import AVFoundation
import Combine
import Speech
import SwiftUI
import UIKit

struct VoiceRecitationReviewSessionView: View {
    @StateObject private var transcriber = VoiceRecitationTranscriber()

    let descriptor: ReviewSessionDescriptor
    let verses: [Verse]
    let onUpdate: (Verse) -> Void
    let groupID: String?

    @State private var currentIndex = 0
    @State private var summary = ReviewSessionSummary()
    @State private var isSessionComplete = false
    @State private var endedEarly = false
    @State private var showingEndEarlyConfirmation = false
    @State private var sessionStartDate = Date()

    init(
        descriptor: ReviewSessionDescriptor,
        verses: [Verse],
        onUpdate: @escaping (Verse) -> Void,
        groupID: String? = nil
    ) {
        self.descriptor = descriptor
        self.verses = verses
        self.onUpdate = onUpdate
        self.groupID = groupID
    }

    private var currentVerse: Verse {
        verses[currentIndex]
    }

    private var comparison: VoiceRecitationComparison {
        VoiceRecitationComparison(spokenText: transcriber.transcript, actualText: currentVerse.text)
    }

    var body: some View {
        NavigationStack {
            sessionContent
                .navigationTitle(descriptor.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: toolbarContent)
                .confirmationDialog("End session early?", isPresented: $showingEndEarlyConfirmation, titleVisibility: .visible) {
                    Button("End Review") {
                        transcriber.stopImmediately()
                        endedEarly = true
                        isSessionComplete = true
                    }

                    Button("Keep Reviewing", role: .cancel) {}
                } message: {
                    Text("You’ll still see results for the verses you’ve already reviewed.")
                }
                .task {
                    await transcriber.preparePermissionsIfNeeded()
                }
                .task(id: currentVerse.id) {
                    transcriber.prepareForVerse(reference: currentVerse.reference)
                }
                .onDisappear {
                    transcriber.stopImmediately()
                }
                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                .animation(.easeInOut(duration: 0.2), value: isSessionComplete)
        }
    }

    @ViewBuilder
    private var sessionContent: some View {
        if verses.isEmpty {
            emptyState
        } else if isSessionComplete {
            completionContent
        } else {
            reviewContent
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()

            Text("No verses to review.")
                .font(.headline)
                .foregroundStyle(AppColors.lightTextSecondary)

            Spacer()
        }
        .padding(.vertical, 32)
    }

    private var completionContent: some View {
        let reviewAgainAction: (() -> Void)? = verses.isEmpty ? nil : { resetSession() }

        return ReviewSessionCompletionView(
            descriptor: descriptor,
            summary: summary,
            totalVerseCount: verses.count,
            endedEarly: endedEarly,
            duration: sessionDuration,
            onReviewAgain: reviewAgainAction
        )
    }

    private var reviewContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                ReviewSessionProgressHeader(
                    descriptor: descriptor,
                    currentIndex: currentIndex,
                    totalCount: verses.count,
                    reference: currentVerse.reference
                )

                VStack(spacing: 18) {
                    referenceHeader

                    if transcriber.showsTranscriptCard {
                        transcriptCard
                    }

                    if transcriber.hasComparisonReady {
                        comparisonCard
                        resultButtons
                    } else if case .denied = transcriber.permissionState {
                        permissionCard
                    } else {
                        recordControls
                    }
                }
                .id(currentVerse.id)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    private var referenceHeader: some View {
        VStack(spacing: 14) {
            Text(currentVerse.reference)
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .multilineTextAlignment(.center)

            Button {
                transcriber.speakReference(currentVerse.reference)
            } label: {
                Label("Hear Reference", systemImage: "speaker.wave.2.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(height: 44)
                    .padding(.horizontal, 16)
            }
            .buttonStyle(.bordered)
            .disabled(transcriber.isRecording || transcriber.isProcessing)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(transcriber.stateTitle)
                    .font(.headline)

                Spacer()

                if transcriber.isRecording {
                    Text("Live")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.gold)
                }
            }

            if let message = transcriber.stateMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.lightTextSecondary)
            }

            transcriptText
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(cardBackground)
    }

    @ViewBuilder
    private var transcriptText: some View {
        if transcriber.transcript.isEmpty {
            Text(transcriber.transcriptPlaceholder)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 92, alignment: .topLeading)
        } else {
            Text(transcriber.transcriptPlaceholder)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 92, alignment: .topLeading)
                .textSelection(.enabled)
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Permissions Required")
                .font(.headline)

            Text("Microphone and speech recognition access are both required.")
                .font(.subheadline)
                .foregroundStyle(AppColors.lightTextSecondary)

            HStack(spacing: 12) {
                Button("Try Again") {
                    Task {
                        await transcriber.preparePermissions(forceRefresh: true)
                    }
                }
                .buttonStyle(.bordered)

                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }

                    UIApplication.shared.open(url)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(cardBackground)
    }

    private var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            comparisonSection(title: "Transcript", content: comparison.spokenAttributedText)
            comparisonSection(title: "Verse", content: comparison.actualAttributedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(cardBackground)
    }

    private func comparisonSection(title: String, content: AttributedString) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.lightTextSecondary)
                .textCase(.uppercase)

            Text(content.characters.isEmpty ? AttributedString(" ") : content)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }

    private var recordControls: some View {
        VStack(spacing: 12) {
            Button {
                switch transcriber.captureState {
                case .ready, .failed, .noSpeechDetected, .completed:
                    Task {
                        await transcriber.startTranscribing()
                    }
                case .recording:
                    transcriber.finishCurrentCapture()
                case .requestingPermissions, .processing:
                    break
                }
            } label: {
                Label(primaryButtonTitle, systemImage: primaryButtonSystemImage)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(.borderedProminent)
            .tint(primaryButtonTint)
            .disabled(transcriber.isPrimaryButtonDisabled)

            if transcriber.canRetryCurrentVerse {
                Button("Retry Verse") {
                    transcriber.retryCurrentVerse(reference: currentVerse.reference)
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .buttonStyle(.bordered)
            }
        }
    }

    private var resultButtons: some View {
        VStack(spacing: 12) {
            Button("Correct") {
                recordReview(result: .correct)
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.gold)
            .foregroundStyle(AppColors.darkTextPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button("Incorrect") {
                recordReview(result: .missed)
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.gold)
            .foregroundStyle(AppColors.darkTextPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button("Retry Verse") {
                transcriber.retryCurrentVerse(reference: currentVerse.reference)
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .buttonStyle(.bordered)
        }
    }

    private var primaryButtonTitle: String {
        switch transcriber.captureState {
        case .ready, .failed, .noSpeechDetected, .completed:
            return "Start Recording"
        case .recording:
            return "Stop Recording"
        case .requestingPermissions:
            return "Requesting Access"
        case .processing:
            return "Processing"
        }
    }

    private var primaryButtonSystemImage: String {
        switch transcriber.captureState {
        case .ready, .failed, .noSpeechDetected, .completed:
            return "mic.fill"
        case .recording:
            return "stop.circle.fill"
        case .requestingPermissions, .processing:
            return "ellipsis.circle"
        }
    }

    private var primaryButtonTint: Color {
        switch transcriber.captureState {
        case .recording:
            return AppColors.gold
        default:
            return AppColors.brandBlue
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(AppColors.lightSurface)
    }

    private func recordReview(result: ReviewResult) {
        let updatedVerse: Verse

        if let groupID {
            ReviewRepository.shared.recordGroupReview(
                for: currentVerse,
                groupID: groupID,
                method: .voiceRecitation,
                result: result
            )
            updatedVerse = currentVerse
        } else {
            updatedVerse = ReviewRepository.shared.recordReview(
                for: currentVerse,
                method: .voiceRecitation,
                result: result
            )
        }

        onUpdate(updatedVerse)
        summary.record(result, reference: currentVerse.reference)
        moveToNextVerseOrFinish()
    }

    private func moveToNextVerseOrFinish() {
        transcriber.stopImmediately()

        if currentIndex + 1 < verses.count {
            withAnimation(.easeInOut(duration: 0.22)) {
                currentIndex += 1
            }
        } else {
            isSessionComplete = true
        }
    }

    private var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartDate)
    }

    private func resetSession() {
        transcriber.stopImmediately()
        currentIndex = 0
        summary = ReviewSessionSummary()
        isSessionComplete = false
        endedEarly = false
        sessionStartDate = Date()
        transcriber.prepareForVerse(reference: verses.first?.reference ?? "")
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if !isSessionComplete {
            ToolbarItem(placement: .topBarTrailing) {
                Button("End") {
                    showingEndEarlyConfirmation = true
                }
            }
        }
    }
}

@MainActor
final class VoiceRecitationTranscriber: NSObject, ObservableObject {
    enum PermissionState: Equatable {
        case unknown
        case requesting
        case denied
        case ready
    }

    enum CaptureState: Equatable {
        case ready
        case requestingPermissions
        case recording
        case processing
        case completed
        case failed(String)
        case noSpeechDetected
    }

    @Published private(set) var permissionState: PermissionState = .unknown
    @Published private(set) var captureState: CaptureState = .requestingPermissions
    @Published private(set) var transcript = ""

    var isRecording: Bool {
        captureState == .recording
    }

    var isProcessing: Bool {
        captureState == .processing
    }

    var hasComparisonReady: Bool {
        captureState == .completed
    }

    var showsTranscriptCard: Bool {
        switch captureState {
        case .recording, .processing, .completed, .failed, .noSpeechDetected:
            return true
        case .ready, .requestingPermissions:
            return false
        }
    }

    var transcriptPlaceholder: String {
        transcript.isEmpty ? transcriptPlaceholderText : transcript
    }

    var transcriptPlaceholderText: String {
        switch captureState {
        case .recording:
            return "Listening…"
        case .processing:
            return transcript.isEmpty ? "Finishing capture…" : transcript
        case .failed:
            return "No usable transcript."
        case .noSpeechDetected:
            return "No speech detected."
        case .completed:
            return transcript
        case .ready, .requestingPermissions:
            return ""
        }
    }

    var stateTitle: String {
        switch captureState {
        case .ready:
            return "Ready"
        case .requestingPermissions:
            return "Requesting Permissions"
        case .recording:
            return "Recording"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Transcription Failed"
        case .noSpeechDetected:
            return "No Speech Detected"
        }
    }

    var stateMessage: String? {
        switch captureState {
        case .ready:
            return nil
        case .requestingPermissions:
            return "Waiting for microphone and speech access."
        case .recording:
            return nil
        case .processing:
            return "Finalizing your transcript."
        case .completed:
            return nil
        case .failed(let message):
            return message
        case .noSpeechDetected:
            return "Try again and start speaking after recording begins."
        }
    }

    var canRetryCurrentVerse: Bool {
        switch captureState {
        case .completed, .failed, .noSpeechDetected:
            return true
        case .ready, .requestingPermissions, .recording, .processing:
            return false
        }
    }

    var isPrimaryButtonDisabled: Bool {
        switch captureState {
        case .requestingPermissions, .processing:
            return true
        default:
            return false
        }
    }

    private let audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.autoupdatingCurrent)

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTask: Task<Void, Never>?
    private var processingTimeoutTask: Task<Void, Never>?
    private var isFinishingCapture = false
    private var shouldIgnoreRecognizerErrors = false
    private var hasReceivedRecognitionResult = false

    override init() {
        super.init()
        speechSynthesizer.usesApplicationAudioSession = true
    }

    func preparePermissionsIfNeeded() async {
        guard permissionState == .unknown else {
            if permissionState == .ready, captureState == .requestingPermissions {
                captureState = .ready
            }
            return
        }

        await preparePermissions(forceRefresh: false)
    }

    func preparePermissions(forceRefresh: Bool) async {
        guard forceRefresh || permissionState != .ready else {
            captureState = .ready
            return
        }

        permissionState = .requesting
        captureState = .requestingPermissions

        let speechAuthorized = await requestSpeechAuthorization()
        let microphoneAuthorized = await requestMicrophoneAuthorization()

        permissionState = speechAuthorized && microphoneAuthorized ? .ready : .denied
        captureState = permissionState == .ready ? .ready : .failed("Voice Recitation needs microphone and speech recognition access.")
    }

    func prepareForVerse(reference: String) {
        stopImmediately()
        transcript = ""
        hasReceivedRecognitionResult = false

        captureState = permissionState == .ready ? .ready : .requestingPermissions

        guard !reference.isEmpty else {
            return
        }

        speakReference(reference)
    }

    func retryCurrentVerse(reference: String) {
        prepareForVerse(reference: reference)
    }

    func speakReference(_ reference: String) {
        guard !reference.isEmpty else {
            return
        }

        stopSpeaking()
        configureReferencePlayback()

        let utterance = AVSpeechUtterance(string: reference)
        utterance.rate = 0.48
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.autoupdatingCurrent.identifier)
        speechSynthesizer.speak(utterance)
    }

    func startTranscribing() async {
        await preparePermissionsIfNeeded()

        guard permissionState == .ready else {
            return
        }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            captureState = .failed("Speech recognition is not available right now.")
            return
        }

        stopSpeaking()
        stopImmediately()

        transcript = ""
        hasReceivedRecognitionResult = false
        shouldIgnoreRecognizerErrors = false
        isFinishingCapture = false

        do {
            try startAudioSession()
            try startRecognition(with: speechRecognizer)
            captureState = .recording
            scheduleSilenceTimeout(after: 5)
        } catch {
            stopImmediately()
            captureState = .failed("Unable to start recording. Try the verse again.")
        }
    }

    func finishCurrentCapture() {
        guard captureState == .recording else {
            return
        }

        finishCapture(userInitiated: true)
    }

    func stopImmediately() {
        cancelTimers()
        stopAudioEngine()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isFinishingCapture = false
        shouldIgnoreRecognizerErrors = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func configureReferencePlayback() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // If speaker routing fails, fall back to the system-managed route.
        }
    }

    private func startRecognition(with speechRecognizer: SFSpeechRecognizer) throws {
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        self.recognitionRequest = recognitionRequest

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognition(result: result, error: error)
            }
        }
    }

    private func handleRecognition(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            let newTranscript = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
            if !newTranscript.isEmpty {
                transcript = newTranscript
                hasReceivedRecognitionResult = true
            }

            if captureState == .recording {
                scheduleSilenceTimeout(after: transcript.isEmpty ? 5 : 1.6)
            }

            if result.isFinal {
                finalizeCapture(successFromRecognizer: true)
                return
            }
        }

        guard let error else {
            return
        }

        if shouldIgnoreRecognizerErrors, !transcript.isEmpty {
            finalizeCapture(successFromRecognizer: false)
            return
        }

        if isBenignStopError(error), !transcript.isEmpty {
            finalizeCapture(successFromRecognizer: false)
            return
        }

        if isFinishingCapture, !transcript.isEmpty {
            finalizeCapture(successFromRecognizer: false)
            return
        }

        stopImmediately()
        captureState = transcript.isEmpty ? .failed("Transcription failed. Try again.") : .completed
    }

    private func finishCapture(userInitiated: Bool) {
        guard !isFinishingCapture else {
            return
        }

        isFinishingCapture = true
        shouldIgnoreRecognizerErrors = userInitiated
        cancelTimers()
        stopAudioEngine()
        recognitionRequest?.endAudio()

        if !transcript.isEmpty || hasReceivedRecognitionResult {
            captureState = .processing
        } else {
            captureState = .processing
        }

        processingTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else {
                return
            }

            self?.finalizeCapture(successFromRecognizer: false)
        }
    }

    private func finalizeCapture(successFromRecognizer: Bool) {
        processingTimeoutTask?.cancel()
        processingTimeoutTask = nil

        stopAudioEngine()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isFinishingCapture = false
        shouldIgnoreRecognizerErrors = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        if !transcript.isEmpty {
            captureState = .completed
        } else if successFromRecognizer {
            captureState = .noSpeechDetected
        } else if hasReceivedRecognitionResult {
            captureState = .completed
        } else {
            captureState = .noSpeechDetected
        }
    }

    private func stopAudioEngine() {
        silenceTask?.cancel()
        silenceTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
    }

    private func cancelTimers() {
        silenceTask?.cancel()
        silenceTask = nil
        processingTimeoutTask?.cancel()
        processingTimeoutTask = nil
    }

    private func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func scheduleSilenceTimeout(after seconds: Double) {
        silenceTask?.cancel()
        silenceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else {
                return
            }

            self?.finishCapture(userInitiated: false)
        }
    }

    private func isBenignStopError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == "kAFAssistantErrorDomain" || nsError.code == 301
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }
}

private struct VoiceRecitationComparison {
    let spokenAttributedText: AttributedString
    let actualAttributedText: AttributedString

    init(spokenText: String, actualText: String) {
        let spokenTokens = Self.tokens(from: spokenText)
        let actualTokens = Self.tokens(from: actualText)
        let matchedPairs = Self.longestCommonSubsequence(spokenTokens: spokenTokens, actualTokens: actualTokens)
        let spokenMatches = Set(matchedPairs.map(\.spokenIndex))
        let actualMatches = Set(matchedPairs.map(\.actualIndex))

        spokenAttributedText = Self.attributedText(for: spokenTokens, matchedIndexes: spokenMatches, mismatchColor: AppColors.gold)
        actualAttributedText = Self.attributedText(for: actualTokens, matchedIndexes: actualMatches, mismatchColor: AppColors.gold)
    }

    private struct Token {
        let raw: String
        let normalized: String
    }

    private struct MatchPair {
        let spokenIndex: Int
        let actualIndex: Int
    }

    private static func tokens(from text: String) -> [Token] {
        text
            .split(whereSeparator: \.isWhitespace)
            .map { rawToken in
                let raw = String(rawToken)
                let normalized = raw
                    .lowercased()
                    .filter { $0.isLetter || $0.isNumber }

                return Token(raw: raw, normalized: normalized)
            }
    }

    private static func longestCommonSubsequence(spokenTokens: [Token], actualTokens: [Token]) -> [MatchPair] {
        guard !spokenTokens.isEmpty, !actualTokens.isEmpty else {
            return []
        }

        var table = Array(
            repeating: Array(repeating: 0, count: actualTokens.count + 1),
            count: spokenTokens.count + 1
        )

        for spokenIndex in 0..<spokenTokens.count {
            for actualIndex in 0..<actualTokens.count {
                if spokenTokens[spokenIndex].normalized == actualTokens[actualIndex].normalized,
                   !spokenTokens[spokenIndex].normalized.isEmpty {
                    table[spokenIndex + 1][actualIndex + 1] = table[spokenIndex][actualIndex] + 1
                } else {
                    table[spokenIndex + 1][actualIndex + 1] = max(
                        table[spokenIndex][actualIndex + 1],
                        table[spokenIndex + 1][actualIndex]
                    )
                }
            }
        }

        var matches: [MatchPair] = []
        var spokenIndex = spokenTokens.count
        var actualIndex = actualTokens.count

        while spokenIndex > 0, actualIndex > 0 {
            if spokenTokens[spokenIndex - 1].normalized == actualTokens[actualIndex - 1].normalized,
               !spokenTokens[spokenIndex - 1].normalized.isEmpty {
                matches.append(MatchPair(spokenIndex: spokenIndex - 1, actualIndex: actualIndex - 1))
                spokenIndex -= 1
                actualIndex -= 1
            } else if table[spokenIndex - 1][actualIndex] >= table[spokenIndex][actualIndex - 1] {
                spokenIndex -= 1
            } else {
                actualIndex -= 1
            }
        }

        return matches.reversed()
    }

    private static func attributedText(for tokens: [Token], matchedIndexes: Set<Int>, mismatchColor: Color) -> AttributedString {
        var attributedText = AttributedString()

        for (index, token) in tokens.enumerated() {
            var tokenText = AttributedString(token.raw)

            if !matchedIndexes.contains(index) {
                tokenText.foregroundColor = mismatchColor
                tokenText.backgroundColor = mismatchColor.opacity(0.12)
            }

            attributedText.append(tokenText)

            if index < tokens.count - 1 {
                attributedText.append(AttributedString(" "))
            }
        }

        return attributedText
    }
}

#Preview {
    VoiceRecitationReviewSessionView(
        descriptor: ReviewSessionDescriptor(title: "Voice Recitation", method: .voiceRecitation),
        verses: [
            Verse(
                reference: "John 3:16",
                text: "For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life."
            )
        ],
        onUpdate: { _ in }
    )
}
