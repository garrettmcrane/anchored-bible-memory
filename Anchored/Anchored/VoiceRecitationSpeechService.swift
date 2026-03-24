import AVFoundation
import Combine
import Speech
import SwiftUI

@MainActor
final class VoiceRecitationSpeechService: NSObject, ObservableObject {
    enum PermissionState: Equatable {
        case unknown
        case requesting
        case ready
        case denied
    }

    enum Phase: Equatable {
        case idle
        case speakingReference
        case listening
        case processing
        case failed(VoiceRecitationSpeechFailure)
    }

    enum VoiceRecitationSpeechFailure: Equatable, LocalizedError {
        case permissionsDenied
        case speechUnavailable
        case microphoneUnavailable
        case noSpeechDetected
        case unusableTranscript
        case transcriptionFailed

        var errorDescription: String? {
            switch self {
            case .permissionsDenied:
                return "Microphone and speech recognition access are required."
            case .speechUnavailable:
                return "Speech transcription is not available on this device right now."
            case .microphoneUnavailable:
                return "The microphone could not be started."
            case .noSpeechDetected:
                return "No speech was detected for this verse."
            case .unusableTranscript:
                return "The transcript was too limited to grade reliably."
            case .transcriptionFailed:
                return "Transcription failed. Try the verse again."
            }
        }
    }

    struct CaptureResult: Equatable {
        let transcript: String
    }

    @Published private(set) var permissionState: PermissionState = .unknown
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var transcript = ""
    @Published private(set) var liveLevel: Double = 0

    var isListening: Bool {
        phase == .listening
    }

    var isProcessing: Bool {
        phase == .processing
    }

    private let audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer()

    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var analyzerTask: Task<Void, Never>?
    private var resultsTask: Task<Void, Never>?
    private var silenceMonitorTask: Task<Void, Never>?
    private var referenceContinuation: CheckedContinuation<Void, Never>?

    private var selectedVoice: AVSpeechSynthesisVoice?
    private var captureError: VoiceRecitationSpeechFailure?
    private var lastSpeechActivity = Date()
    private var captureStartTime = Date()
    private var heardSpeech = false
    private var isFinishingCapture = false

    override init() {
        super.init()
        speechSynthesizer.delegate = self
        speechSynthesizer.usesApplicationAudioSession = true
    }

    func preparePermissionsIfNeeded() async {
        guard permissionState == .unknown else {
            return
        }

        await preparePermissions(forceRefresh: false)
    }

    func preparePermissions(forceRefresh: Bool) async {
        guard forceRefresh || permissionState != .ready else {
            return
        }

        permissionState = .requesting

        let speechAuthorized = await requestSpeechAuthorization()
        let microphoneAuthorized = await AVAudioApplication.requestRecordPermission()

        permissionState = speechAuthorized && microphoneAuthorized ? .ready : .denied

        if permissionState == .denied {
            phase = .failed(.permissionsDenied)
        } else if phase == .failed(.permissionsDenied) {
            phase = .idle
        }
    }

    func speakReference(_ reference: String) async {
        guard !reference.isEmpty else {
            return
        }

        cancelReferencePlayback()
        do {
            try configurePlaybackSession()
        } catch {
            // Keep going with system defaults if the route cannot be configured.
        }

        phase = .speakingReference
        let utterance = AVSpeechUtterance(string: reference)
        utterance.voice = selectedVoice ?? bestVoice(for: Locale.autoupdatingCurrent)
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0
        utterance.prefersAssistiveTechnologySettings = false

        await withCheckedContinuation { continuation in
            referenceContinuation = continuation
            speechSynthesizer.speak(utterance)
        }
    }

    func captureVerse() async -> Result<CaptureResult, VoiceRecitationSpeechFailure> {
        await preparePermissionsIfNeeded()

        guard permissionState == .ready else {
            return .failure(.permissionsDenied)
        }

        guard SpeechTranscriber.isAvailable else {
            phase = .failed(.speechUnavailable)
            return .failure(.speechUnavailable)
        }

        resetCaptureState()
        phase = .listening

        do {
            let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale.autoupdatingCurrent) ?? Locale(identifier: "en-US")
            let transcriber = SpeechTranscriber(locale: locale, preset: .progressiveTranscription)
            let detector = SpeechDetector(detectionOptions: .init(sensitivityLevel: .medium), reportResults: false)
            let modules: [any SpeechModule] = [transcriber, detector]

            if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: modules) {
                try await installationRequest.downloadAndInstall()
            }

            let analyzer = SpeechAnalyzer(modules: modules)
            let preferredFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: modules)

            let (inputStream, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)
            inputContinuation = continuation

            try startRecording(preferredFormat: preferredFormat)
            observeSilenceWindow()

            resultsTask = Task { [weak self] in
                guard let self else {
                    return
                }

                do {
                    for try await result in transcriber.results {
                        self.consume(result)
                    }
                } catch is CancellationError {
                    return
                } catch {
                    self.captureError = .transcriptionFailed
                    self.finishCaptureInput()
                }
            }

            analyzerTask = Task { [weak self] in
                guard let self else {
                    return
                }

                do {
                    let lastSampleTime = try await analyzer.analyzeSequence(inputStream)
                    if let lastSampleTime {
                        try await analyzer.finalizeAndFinish(through: lastSampleTime)
                    } else {
                        await analyzer.cancelAndFinishNow()
                    }
                } catch is CancellationError {
                    return
                } catch {
                    self.captureError = self.captureError ?? .transcriptionFailed
                }
            }

            await analyzerTask?.value
            await resultsTask?.value

            stopRecording()

            if let captureError {
                phase = .failed(captureError)
                return .failure(captureError)
            }

            let finalTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

            guard heardSpeech else {
                phase = .failed(.noSpeechDetected)
                return .failure(.noSpeechDetected)
            }

            guard !finalTranscript.isEmpty else {
                phase = .failed(.transcriptionFailed)
                return .failure(.transcriptionFailed)
            }

            guard finalTranscript.split(whereSeparator: \.isWhitespace).count >= 2 else {
                phase = .failed(.unusableTranscript)
                return .failure(.unusableTranscript)
            }

            phase = .idle
            return .success(CaptureResult(transcript: finalTranscript))
        } catch {
            stopRecording()
            phase = .failed(.microphoneUnavailable)
            return .failure(.microphoneUnavailable)
        }
    }

    func stopListeningEarly() {
        captureError = heardSpeech ? nil : .noSpeechDetected
        finishCaptureInput()
    }

    func cancelAll() {
        captureError = nil
        cancelReferencePlayback()
        stopRecording()
        phase = .idle
    }

    private func consume(_ result: SpeechTranscriber.Result) {
        let updatedTranscript = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)

        if !updatedTranscript.isEmpty {
            transcript = updatedTranscript
            heardSpeech = true
            lastSpeechActivity = Date()
        }
    }

    private func observeSilenceWindow() {
        silenceMonitorTask?.cancel()
        silenceMonitorTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled, self.phase == .listening {
                try? await Task.sleep(for: .milliseconds(180))

                if self.heardSpeech,
                   Date().timeIntervalSince(self.lastSpeechActivity) > 1.15 {
                    self.finishCaptureInput()
                    break
                }

                if !self.heardSpeech,
                   Date().timeIntervalSince(self.captureStartTime) > 4.0 {
                    self.captureError = .noSpeechDetected
                    self.finishCaptureInput()
                    break
                }
            }
        }
    }

    private func startRecording(preferredFormat: AVAudioFormat?) throws {
        captureStartTime = Date()
        lastSpeechActivity = Date()
        heardSpeech = false
        isFinishingCapture = false
        captureError = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .allowBluetoothHFP, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let fallbackFormat = inputNode.outputFormat(forBus: 0)
        let tapFormat = preferredFormat ?? fallbackFormat

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: tapFormat) { [weak self] buffer, _ in
            guard let self else {
                return
            }

            self.updateLevel(using: buffer)
            self.inputContinuation?.yield(AnalyzerInput(buffer: buffer))
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func finishCaptureInput() {
        guard !isFinishingCapture else {
            return
        }

        isFinishingCapture = true
        phase = .processing
        inputContinuation?.finish()
        inputContinuation = nil
    }

    private func stopRecording() {
        silenceMonitorTask?.cancel()
        silenceMonitorTask = nil

        analyzerTask?.cancel()
        analyzerTask = nil

        resultsTask?.cancel()
        resultsTask = nil

        inputContinuation?.finish()
        inputContinuation = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        liveLevel = 0
        isFinishingCapture = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func updateLevel(using buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else {
            return
        }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else {
            return
        }

        let channel = channelData[0]
        var sum: Float = 0

        for frame in 0..<frameLength {
            let sample = channel[frame]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))
        let normalizedLevel = min(max(Double(rms) * 9.0, 0), 1)

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            self.liveLevel = normalizedLevel

            if normalizedLevel > 0.08 {
                self.heardSpeech = true
                self.lastSpeechActivity = Date()
            }
        }
    }

    private func resetCaptureState() {
        stopRecording()
        transcript = ""
        liveLevel = 0
        captureError = nil
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func configurePlaybackSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func cancelReferencePlayback() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        referenceContinuation?.resume()
        referenceContinuation = nil
    }

    private func bestVoice(for locale: Locale) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.hasPrefix(locale.language.languageCode?.identifier ?? "en")
                && !voice.voiceTraits.contains(.isNoveltyVoice)
        }

        let preferredIdentifier = locale.identifier
        let rankedVoice = voices.max { lhs, rhs in
            voiceScore(for: lhs, preferredIdentifier: preferredIdentifier) < voiceScore(for: rhs, preferredIdentifier: preferredIdentifier)
        }

        selectedVoice = rankedVoice ?? AVSpeechSynthesisVoice(language: preferredIdentifier)
        return selectedVoice
    }

    private func voiceScore(for voice: AVSpeechSynthesisVoice, preferredIdentifier: String) -> Int {
        var score = 0

        if voice.language == preferredIdentifier {
            score += 300
        } else if voice.language.hasPrefix("en") {
            score += 180
        }

        switch voice.quality {
        case .premium:
            score += 120
        case .enhanced:
            score += 80
        default:
            score += 20
        }

        if voice.voiceTraits.contains(.isPersonalVoice) {
            score -= 40
        }

        return score
    }
}

extension VoiceRecitationSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.referenceContinuation?.resume()
            self?.referenceContinuation = nil
            self?.phase = .idle
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.referenceContinuation?.resume()
            self?.referenceContinuation = nil
            self?.phase = .idle
        }
    }
}
