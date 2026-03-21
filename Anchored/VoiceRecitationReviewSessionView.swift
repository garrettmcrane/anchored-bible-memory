import AVFoundation
import Combine
import Speech
import SwiftUI
import UIKit

struct VoiceRecitationReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss
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
                        transcriber.stopTranscribing()
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
                    transcriber.stopTranscribing()
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
                .foregroundStyle(.secondary)

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
                    referenceCard
                    statusCard

                    if transcriber.hasComparisonReady {
                        comparisonCard
                        resultButtons
                    } else {
                        controlButtons
                    }
                }
                .id(currentVerse.id)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recite From Memory")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(currentVerse.reference)
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundStyle(.primary)

            Text("The app reads the reference aloud. Recite the verse, then compare your transcript with the actual text before scoring yourself.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                transcriber.speakReference(currentVerse.reference)
            } label: {
                Label("Hear Reference Again", systemImage: "speaker.wave.2.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.bordered)
            .disabled(transcriber.isRecording)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(statusTitle, systemImage: statusSystemImage)
                    .font(.headline)

                Spacer()

                if transcriber.isRecording {
                    Text("Listening")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }

            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if transcriber.isRecording || !transcriber.transcript.isEmpty {
                ScrollView {
                    Text(transcriber.transcript.isEmpty ? "Waiting for speech..." : transcriber.transcript)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 96, alignment: .top)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.systemBackground))
                )
            }

            if case .denied = transcriber.permissionState {
                permissionActions
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Compare")
                .font(.headline)

            comparisonSection(
                title: "Your Transcription",
                content: comparison.spokenAttributedText,
                emptyState: "Nothing was transcribed."
            )

            comparisonSection(
                title: "Actual Verse",
                content: comparison.actualAttributedText,
                emptyState: currentVerse.text
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func comparisonSection(title: String, content: AttributedString, emptyState: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if content.characters.isEmpty {
                Text(emptyState)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(content)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
    }

    private var controlButtons: some View {
        VStack(spacing: 12) {
            if transcriber.isRecording {
                Button {
                    transcriber.finishCurrentCapture()
                } label: {
                    Label("Stop Recording", systemImage: "stop.circle.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button {
                    Task {
                        await transcriber.startTranscribing()
                    }
                } label: {
                    Label("Start Recording", systemImage: "mic.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(.borderedProminent)
            }

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
            .background(Color.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button("Incorrect") {
                recordReview(result: .missed)
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.red)
            .foregroundStyle(.white)
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

    private var permissionActions: some View {
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

    private var statusTitle: String {
        switch transcriber.permissionState {
        case .unknown, .requesting:
            return "Preparing Voice Review"
        case .denied:
            return "Permissions Required"
        case .ready:
            switch transcriber.captureState {
            case .idle:
                return "Ready to Listen"
            case .recording:
                return "Recording in Progress"
            case .transcribed:
                return "Transcription Complete"
            case .failed:
                return "Transcription Failed"
            case .noSpeechDetected:
                return "No Speech Detected"
            }
        }
    }

    private var statusSystemImage: String {
        switch transcriber.permissionState {
        case .unknown, .requesting:
            return "ellipsis.circle"
        case .denied:
            return "mic.slash"
        case .ready:
            switch transcriber.captureState {
            case .idle:
                return "mic"
            case .recording:
                return "waveform"
            case .transcribed:
                return "checkmark.bubble"
            case .failed:
                return "exclamationmark.triangle"
            case .noSpeechDetected:
                return "bubble.left.and.exclamationmark.bubble.right"
            }
        }
    }

    private var statusMessage: String {
        switch transcriber.permissionState {
        case .unknown, .requesting:
            return "Requesting microphone and speech recognition access."
        case .denied:
            return "Voice Recitation needs both microphone and speech recognition permission."
        case .ready:
            switch transcriber.captureState {
            case .idle:
                return "Tap Start Recording when you’re ready to recite the verse aloud."
            case .recording:
                return "Speak naturally. Recording will stop when you tap Stop or after a short pause."
            case .transcribed:
                return "Review the transcript against the verse text, then choose Correct or Incorrect."
            case .failed(let message):
                return message
            case .noSpeechDetected:
                return "No speech was captured for this attempt. Try again and speak after recording starts."
            }
        }
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
        transcriber.stopTranscribing()

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
        transcriber.stopTranscribing()
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
        case idle
        case recording
        case transcribed
        case failed(String)
        case noSpeechDetected
    }

    @Published private(set) var permissionState: PermissionState = .unknown
    @Published private(set) var captureState: CaptureState = .idle
    @Published private(set) var transcript = ""

    var isRecording: Bool {
        captureState == .recording
    }

    var hasComparisonReady: Bool {
        captureState == .transcribed
    }

    var canRetryCurrentVerse: Bool {
        switch captureState {
        case .idle, .recording:
            return false
        case .transcribed, .failed, .noSpeechDetected:
            return true
        }
    }

    private let audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.autoupdatingCurrent)

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTask: Task<Void, Never>?

    override init() {
        super.init()
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
        let microphoneAuthorized = await requestMicrophoneAuthorization()

        permissionState = speechAuthorized && microphoneAuthorized ? .ready : .denied
    }

    func prepareForVerse(reference: String) {
        stopTranscribing()
        transcript = ""
        captureState = .idle

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
        stopTranscribing()

        transcript = ""
        captureState = .idle

        do {
            try startAudioSession()
            try startRecognition(with: speechRecognizer)
            captureState = .recording
            scheduleSilenceTimeout(after: 5)
        } catch {
            stopTranscribing()
            captureState = .failed("Unable to start recording. Check permissions and try again.")
        }
    }

    func finishCurrentCapture() {
        finishCapture(markNoSpeechIfNeeded: true)
    }

    func stopTranscribing() {
        silenceTask?.cancel()
        silenceTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func startRecognition(with speechRecognizer: SFSpeechRecognizer) throws {
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
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
            transcript = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
            scheduleSilenceTimeout(after: transcript.isEmpty ? 5 : 1.6)

            if result.isFinal {
                finishCapture(markNoSpeechIfNeeded: true)
                return
            }
        }

        if error != nil {
            let hasTranscript = !transcript.isEmpty
            finishCapture(markNoSpeechIfNeeded: !hasTranscript)

            if !hasTranscript {
                captureState = .failed("Transcription failed. Try the verse again.")
            }
        }
    }

    private func finishCapture(markNoSpeechIfNeeded: Bool) {
        silenceTask?.cancel()
        silenceTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        if markNoSpeechIfNeeded && transcript.isEmpty {
            captureState = .noSpeechDetected
        } else if !transcript.isEmpty {
            captureState = .transcribed
        }
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

            self?.finishCapture(markNoSpeechIfNeeded: true)
        }
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

        spokenAttributedText = Self.attributedText(for: spokenTokens, matchedIndexes: spokenMatches, mismatchColor: .orange)
        actualAttributedText = Self.attributedText(for: actualTokens, matchedIndexes: actualMatches, mismatchColor: .red)
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
