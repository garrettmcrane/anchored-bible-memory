import SwiftUI
import UIKit

struct VoiceRecitationReviewSessionView: View {
    @StateObject private var speechService = VoiceRecitationSpeechService()

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
    @State private var selectedMode: VoiceRecitationMode?
    @State private var isModeConfirmed = false
    @State private var verseGrade: VoiceRecitationGrade?
    @State private var currentResultRecorded = false
    @State private var statusText = "Preparing voice review"
    @State private var supportingText = "Anchored will listen, transcribe, and grade automatically."
    @State private var handsFreeRetryCount = 0
    @State private var flowTask: Task<Void, Never>?

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

    private var currentMode: VoiceRecitationMode? {
        isModeConfirmed ? selectedMode : nil
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(descriptor.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: toolbarContent)
                .confirmationDialog("End session early?", isPresented: $showingEndEarlyConfirmation, titleVisibility: .visible) {
                    Button("End Review") {
                        flowTask?.cancel()
                        speechService.cancelAll()
                        endedEarly = true
                        isSessionComplete = true
                    }

                    Button("Keep Reviewing", role: .cancel) {}
                } message: {
                    Text("You’ll still see results for the verses you’ve already reviewed.")
                }
                .task {
                    await speechService.preparePermissionsIfNeeded()
                }
                .onDisappear {
                    flowTask?.cancel()
                    speechService.cancelAll()
                }
                .animation(.easeInOut(duration: 0.22), value: currentIndex)
                .animation(.easeInOut(duration: 0.22), value: isSessionComplete)
        }
    }

    @ViewBuilder
    private var content: some View {
        if verses.isEmpty {
            emptyState
        } else if !isModeConfirmed {
            modeSelectionContent
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
                .foregroundStyle(AppColors.textSecondary)

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

    private var modeSelectionContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                modeSelectionHeader

                VStack(spacing: 14) {
                    ForEach(VoiceRecitationMode.allCases) { mode in
                        modeCard(for: mode)
                    }
                }

                Button("Continue") {
                    guard selectedMode != nil else {
                        return
                    }

                    isModeConfirmed = true
                    startCurrentVerseFlow()
                }
                .buttonStyle(AnchoredPrimaryButtonStyle())
                .disabled(selectedMode == nil)
                .opacity(selectedMode == nil ? 0.45 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    private var modeSelectionHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose Voice Recitation")
                .font(AnchoredFont.editorial(34))
                .foregroundStyle(AppColors.textPrimary)

            Text("Pick the listening style that fits where you are right now. Both modes grade automatically and feed the same review system.")
                .font(AnchoredFont.uiBody)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func modeCard(for mode: VoiceRecitationMode) -> some View {
        let isSelected = selectedMode == mode

        return Button {
            selectedMode = mode
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? AppColors.structuralAccent : AppColors.selectionFill)
                            .frame(width: 46, height: 46)

                        Image(systemName: mode.systemImage)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.white : AppColors.structuralAccent)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(mode.accentTitle)
                            .font(AnchoredFont.uiCaption)
                            .foregroundStyle(AppColors.textSecondary)
                            .textCase(.uppercase)

                        Text(mode.title)
                            .font(AnchoredFont.ui(20, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)

                        Text(mode.subtitle)
                            .font(AnchoredFont.uiSubheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isSelected ? AppColors.structuralAccent : AppColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(mode.detailPoints, id: \.self) { point in
                        HStack(spacing: 10) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.scriptureAccent)

                            Text(point)
                                .font(AnchoredFont.uiSubheadline)
                                .foregroundStyle(AppColors.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(isSelected ? AppColors.elevatedSurface : AppColors.surface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(isSelected ? AppColors.structuralAccent.opacity(0.34) : AppColors.textPrimary.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
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

                currentModeHero
                transcriptCard

                if let grade = verseGrade {
                    gradingCard(for: grade)
                    comparisonCard(for: grade)
                } else {
                    listeningGuidanceCard
                }

                if case .failed(let failure) = speechService.phase {
                    errorCard(for: failure)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom) {
            if let grade = verseGrade {
                bottomActionBar(for: grade)
            } else if speechService.isListening {
                listeningFallbackBar
            }
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    private var currentModeHero: some View {
        AnchoredCard(elevated: true, cornerRadius: 28, padding: 24) {
            VStack(alignment: .center, spacing: 18) {
                Text(currentVerse.reference)
                    .font(AnchoredFont.editorial(36))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.scriptureAccent)

                statusBadge

                VStack(spacing: 6) {
                    Text(statusText)
                        .font(AnchoredFont.ui(20, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(supportingText)
                        .font(AnchoredFont.uiSubheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if currentMode == .standard, verseGrade == nil {
                    Button {
                        flowTask?.cancel()
                        flowTask = Task {
                            await speechService.speakReference(currentVerse.reference)
                            updateStatusForCurrentState()
                        }
                    } label: {
                        Label("Hear Reference", systemImage: "speaker.wave.2.fill")
                            .frame(height: 44)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.glass)
                    .disabled(speechService.isProcessing || speechService.isListening)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: stateIconName)
                .font(.system(size: 13, weight: .semibold))

            Text(stateBadgeText)
                .font(AnchoredFont.uiCaption)
                .textCase(.uppercase)

            if speechService.isListening {
                Capsule(style: .continuous)
                    .fill(AppColors.scriptureAccent)
                    .frame(width: max(18, CGFloat(18 + speechService.liveLevel * 34)), height: 8)
                    .animation(.easeInOut(duration: 0.16), value: speechService.liveLevel)
            }
        }
        .foregroundStyle(stateTintColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(stateTintColor.opacity(0.12))
        )
    }

    private var transcriptCard: some View {
        AnchoredCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Transcript")
                        .font(.headline)

                    Spacer()

                    if speechService.isListening {
                        Text("Live")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.scriptureAccent)
                    }
                }

                if verseGrade != nil {
                    Text(transcriptContent)
                        .font(AnchoredFont.uiBody)
                        .foregroundStyle(speechService.transcript.isEmpty ? AppColors.textSecondary : AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 96, alignment: .topLeading)
                        .textSelection(.enabled)
                } else {
                    Text(transcriptContent)
                        .font(AnchoredFont.uiBody)
                        .foregroundStyle(speechService.transcript.isEmpty ? AppColors.textSecondary : AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 96, alignment: .topLeading)
                }
            }
        }
    }

    private var listeningGuidanceCard: some View {
        AnchoredCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("How It Works")
                    .font(.headline)

                Text(currentMode == .handsFree
                     ? "Anchored speaks the reference, listens for your recitation, detects the stop automatically, then grades and stores the result before moving on."
                     : "Anchored begins listening automatically, stops when your speech trails off, then shows a graded comparison before you move to the next verse.")
                    .font(AnchoredFont.uiBody)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private func gradingCard(for grade: VoiceRecitationGrade) -> some View {
        AnchoredCard(elevated: true) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(grade.summaryTitle)
                            .font(AnchoredFont.ui(22, weight: .semibold))
                            .foregroundStyle(grade.tintColor)

                        Text(grade.summaryDetail)
                            .font(AnchoredFont.uiSubheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer()

                    Text("\(grade.accuracyPercent)%")
                        .font(AnchoredFont.ui(28, weight: .bold))
                        .foregroundStyle(grade.tintColor)
                }

                HStack(spacing: 12) {
                    metricPill(title: "Matched", value: "\(grade.matchedWordCount)")
                    metricPill(title: "Mismatches", value: "\(grade.mismatchCount)")
                    metricPill(title: "Result", value: grade.isPassing ? "Correct" : "Miss")
                }
            }
        }
    }

    private func metricPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AnchoredFont.ui(17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text(title)
                .font(AnchoredFont.uiCaption)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func comparisonCard(for grade: VoiceRecitationGrade) -> some View {
        AnchoredCard {
            VStack(alignment: .leading, spacing: 18) {
                comparisonSection(title: "Verse", content: grade.targetAttributedText)
                comparisonSection(title: "Your Recitation", content: grade.transcriptAttributedText)
            }
        }
    }

    private func comparisonSection(title: String, content: AttributedString) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text(content)
                .font(AnchoredFont.scripture(24))
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }

    private func errorCard(for failure: VoiceRecitationSpeechService.VoiceRecitationSpeechFailure) -> some View {
        AnchoredCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Recovery")
                    .font(.headline)

                Text(failure.errorDescription ?? "Voice Recitation needs attention before continuing.")
                    .font(AnchoredFont.uiBody)
                    .foregroundStyle(AppColors.textSecondary)

                if failure == .permissionsDenied {
                    HStack(spacing: 12) {
                        Button("Try Again") {
                            flowTask?.cancel()
                            flowTask = Task {
                                await speechService.preparePermissions(forceRefresh: true)
                                if speechService.permissionState == .ready {
                                    startCurrentVerseFlow()
                                } else {
                                    updateStatusForCurrentState()
                                }
                            }
                        }
                        .buttonStyle(.glass)

                        Button("Open Settings") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }

                            UIApplication.shared.open(url)
                        }
                        .buttonStyle(.glass)
                    }
                } else {
                    HStack(spacing: 12) {
                        Button("Retry Verse") {
                            startCurrentVerseFlow()
                        }
                        .buttonStyle(.glass)

                        if currentMode == .handsFree {
                            Button("Skip Verse") {
                                moveToNextVerseOrFinish()
                            }
                            .buttonStyle(.glass)
                        }
                    }
                }
            }
        }
    }

    private func bottomActionBar(for grade: VoiceRecitationGrade) -> some View {
        AnchoredBottomActionDock {
            VStack(spacing: 10) {
                if currentMode == .standard {
                    Button("Next Verse") {
                        moveToNextVerseOrFinish()
                    }
                    .modifier(VoiceRecitationNextButtonStyleModifier(isPassing: grade.isPassing))
                } else {
                    Text("Saved automatically. Moving to the next verse…")
                        .font(AnchoredFont.uiSubheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .background(.ultraThinMaterial)
    }

    private var listeningFallbackBar: some View {
        AnchoredBottomActionDock {
            Button("Finish Listening") {
                speechService.stopListeningEarly()
            }
            .buttonStyle(AnchoredSecondaryButtonStyle())
        }
        .background(.ultraThinMaterial)
    }

    private var transcriptContent: String {
        if speechService.transcript.isEmpty {
            switch speechService.phase {
            case .speakingReference:
                return "Speaking the reference aloud…"
            case .listening:
                return "Listening for your recitation…"
            case .processing:
                return "Finishing the transcript and grading…"
            case .failed(let failure):
                return failure.errorDescription ?? "Unable to capture a usable transcript."
            case .idle:
                return verseGrade == nil ? "Your words will appear here automatically." : "No transcript captured."
            }
        }

        return speechService.transcript
    }

    private var stateBadgeText: String {
        if let currentMode, currentMode == .handsFree, verseGrade != nil {
            return "Auto-Advancing"
        }

        switch speechService.phase {
        case .speakingReference:
            return "Speaking"
        case .listening:
            return "Listening"
        case .processing:
            return "Grading"
        case .failed:
            return "Attention Needed"
        case .idle:
            return verseGrade == nil ? "Ready" : "Graded"
        }
    }

    private var stateIconName: String {
        switch speechService.phase {
        case .speakingReference:
            return "speaker.wave.2.fill"
        case .listening:
            return "waveform"
        case .processing:
            return "ellipsis.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        case .idle:
            return verseGrade == nil ? "circle.badge.checkmark" : "checkmark.circle.fill"
        }
    }

    private var stateTintColor: Color {
        if let grade = verseGrade {
            return grade.tintColor
        }

        switch speechService.phase {
        case .failed:
            return AppColors.weakness
        case .speakingReference:
            return AppColors.warning
        case .processing:
            return AppColors.structuralAccent
        case .listening:
            return AppColors.scriptureAccent
        case .idle:
            return AppColors.structuralAccent
        }
    }

    private func startCurrentVerseFlow() {
        guard isModeConfirmed, !isSessionComplete else {
            return
        }

        flowTask?.cancel()
        speechService.cancelAll()
        verseGrade = nil
        currentResultRecorded = false
        statusText = currentMode == .handsFree ? "Preparing the next prompt" : "Get ready to recite"
        supportingText = currentMode == .handsFree
            ? "Anchored will announce the reference, listen, and move on automatically."
            : "Anchored will begin listening automatically in a moment."

        flowTask = Task {
            guard let currentMode else {
                return
            }

            if currentMode == .handsFree {
                await MainActor.run {
                    statusText = "Speaking the reference"
                    supportingText = "Listen for the prompt, then begin reciting."
                }
                await speechService.speakReference(currentVerse.reference)
            }

            await MainActor.run {
                statusText = "Listening"
                supportingText = currentMode == .handsFree
                    ? "Recite the verse. Anchored will stop automatically when you finish."
                    : "Begin speaking whenever you’re ready. Anchored will detect the stop automatically."
            }

            let captureResult = await speechService.captureVerse()
            guard !Task.isCancelled else {
                return
            }

            await handleCaptureResult(captureResult, mode: currentMode)
        }
    }

    private func handleCaptureResult(
        _ captureResult: Result<VoiceRecitationSpeechService.CaptureResult, VoiceRecitationSpeechService.VoiceRecitationSpeechFailure>,
        mode: VoiceRecitationMode
    ) async {
        switch captureResult {
        case .success(let result):
            let grade = VoiceRecitationGrader.grade(transcript: result.transcript, targetText: currentVerse.text)
            verseGrade = grade
            recordReviewIfNeeded(result: grade.reviewResult)
            statusText = grade.summaryTitle
            supportingText = mode == .handsFree
                ? "Result stored. Anchored will continue automatically."
                : "Review the highlighted differences, then continue when you’re ready."
            handsFreeRetryCount = 0

            if mode == .handsFree {
                try? await Task.sleep(for: .seconds(1.35))
                guard !Task.isCancelled else {
                    return
                }
                moveToNextVerseOrFinish()
            }
        case .failure(let failure):
            if mode == .handsFree, handsFreeRetryCount == 0, failure != .permissionsDenied {
                handsFreeRetryCount = 1
                statusText = "Let’s try that again"
                supportingText = "Anchored did not get a usable take, so it is restarting this verse once."
                try? await Task.sleep(for: .seconds(1.1))
                guard !Task.isCancelled else {
                    return
                }
                startCurrentVerseFlow()
                return
            }

            statusText = failure == .permissionsDenied ? "Permissions needed" : "Voice capture needs attention"
            supportingText = failure.errorDescription ?? "Try the verse again."
        }
    }

    private func recordReviewIfNeeded(result: ReviewResult) {
        guard !currentResultRecorded else {
            return
        }

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
        currentResultRecorded = true
    }

    private func moveToNextVerseOrFinish() {
        flowTask?.cancel()
        speechService.cancelAll()
        verseGrade = nil
        currentResultRecorded = false
        handsFreeRetryCount = 0

        if currentIndex + 1 < verses.count {
            withAnimation(.easeInOut(duration: 0.22)) {
                currentIndex += 1
            }
            startCurrentVerseFlow()
        } else {
            isSessionComplete = true
        }
    }

    private func updateStatusForCurrentState() {
        if let grade = verseGrade {
            statusText = grade.summaryTitle
            supportingText = grade.summaryDetail
            return
        }

        switch speechService.phase {
        case .idle:
            statusText = currentMode == .handsFree ? "Preparing the next prompt" : "Get ready to recite"
            supportingText = "Anchored will begin listening automatically."
        case .speakingReference:
            statusText = "Speaking the reference"
            supportingText = "Listen for the prompt, then begin reciting."
        case .listening:
            statusText = "Listening"
            supportingText = "Speak naturally. Anchored will stop automatically when you finish."
        case .processing:
            statusText = "Grading your recitation"
            supportingText = "Comparing your words against the verse."
        case .failed(let failure):
            statusText = failure == .permissionsDenied ? "Permissions needed" : "Voice capture needs attention"
            supportingText = failure.errorDescription ?? "Try the verse again."
        }
    }

    private var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartDate)
    }

    private func resetSession() {
        flowTask?.cancel()
        speechService.cancelAll()
        currentIndex = 0
        summary = ReviewSessionSummary()
        isSessionComplete = false
        endedEarly = false
        sessionStartDate = Date()
        verseGrade = nil
        currentResultRecorded = false
        handsFreeRetryCount = 0
        if isModeConfirmed {
            startCurrentVerseFlow()
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if isModeConfirmed, !isSessionComplete {
            ToolbarItem(placement: .topBarTrailing) {
                Button("End") {
                    showingEndEarlyConfirmation = true
                }
            }
        }
    }
}

private struct VoiceRecitationNextButtonStyleModifier: ViewModifier {
    let isPassing: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isPassing {
            content.buttonStyle(AnchoredSuccessButtonStyle())
        } else {
            content.buttonStyle(AnchoredMissedButtonStyle())
        }
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
