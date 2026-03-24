import SwiftUI
import UIKit

struct AddVerseView: View {
    let focusTrigger: Int
    let onSave: (Verse) -> Void
    let onComplete: (() -> Void)?

    @State private var translation: BibleTranslation = .kjv
    @State private var rawInput = ""
    @State private var previewContext: ScriptureAddPreviewContext?
    @State private var message: String?
    @FocusState private var isReferenceEditorFocused: Bool

    init(
        showsCancelButton: Bool = true,
        focusTrigger: Int = 0,
        onSave: @escaping (Verse) -> Void,
        onComplete: (() -> Void)? = nil
    ) {
        self.focusTrigger = focusTrigger
        self.onSave = onSave
        self.onComplete = onComplete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                introCard
                translationCard
                inputCard

                if let message {
                    AddFlowMessageCard(
                        message: message,
                        tint: message.contains("ready") ? AppColors.success : AppColors.warning
                    )
                }

                continueButton
            }
            .padding(AnchoredSpacing.screenHorizontal)
        }
        .background(AppColors.background)
        .navigationTitle("Type Verses")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $previewContext) { context in
            ScriptureAddPreviewView(
                passages: context.passages,
                onSaveVerse: onSave,
                onComplete: onComplete
            )
        }
        .onChange(of: focusTrigger) { _, _ in
            isReferenceEditorFocused = true
        }
        .onAppear {
            if focusTrigger > 0 {
                isReferenceEditorFocused = true
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    isReferenceEditorFocused = false
                }
                .font(.subheadline.weight(.semibold))
            }
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter one or more verses")
                .font(AnchoredFont.editorial(28))
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Anchored will identify what you type or paste into verses you can add to your library.")
                .font(AnchoredFont.uiSubheadline)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Paste references, rough notes, or mixed lists, then review before saving.")
                .font(AnchoredFont.uiCaption)
                .foregroundStyle(AppColors.structuralAccent)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(cornerRadius: 26, fill: AppColors.elevatedSurface))
    }

    private var translationCard: some View {
        TranslationPickerSection(selection: $translation)
            .padding(.leading, 18)
            .padding(.trailing, 6)
            .padding(.top, 4)
            .padding(.bottom, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground(cornerRadius: 24))
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Input")
                    .font(AnchoredFont.uiLabel)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer(minLength: 12)

                Button("Paste") {
                    rawInput = UIPasteboard.general.string ?? rawInput
                }
                .font(AnchoredFont.uiLabel)
                .foregroundStyle(AppColors.structuralAccent)
            }

            Text("Enter references one per line, comma-separated lists, or rough notes that include references.")
                .font(AnchoredFont.uiSubheadline)
                .foregroundStyle(AppColors.textSecondary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppColors.addComposerBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                isReferenceEditorFocused ? AppColors.structuralAccent.opacity(0.3) : AppColors.addComposerBorder,
                                lineWidth: 1
                            )
                    }

                TextEditor(text: $rawInput)
                    .focused($isReferenceEditorFocused)
                    .scrollContentBackground(.hidden)
                    .font(AnchoredFont.scripture(20))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(minHeight: 240)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                if rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        John 3:16
                        Genesis 1:3-5, Romans 8:28
                        Memory list: John 3:16, Romans 12:2, Jude 24-25
                        """)
                        .font(AnchoredFont.scripture(20))
                        .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
                }
            }
        }
        .padding(18)
        .background(cardBackground(cornerRadius: 28))
    }

    private var continueButton: some View {
        Button("Continue") {
            continueToReview()
        }
        .buttonStyle(AnchoredPrimaryButtonStyle())
        .opacity(rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        .disabled(rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func cardBackground(cornerRadius: CGFloat, fill: Color = AppColors.surface) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fill)
    }

    private func continueToReview() {
        guard translation.isAvailable else {
            message = "\(translation.title) is not available yet."
            return
        }

        do {
            let parseResult = try ReferenceParser.parseAddIntake(rawInput)
            guard !parseResult.references.isEmpty else {
                previewContext = nil
                message = parseResult.unresolvedEntries.isEmpty
                    ? "No valid references found."
                    : "\(parseResult.unresolvedEntries.count) unresolved. Adjust the input and try again."
                return
            }

            let provider = try ScriptureProviderFactory.makeProvider(for: translation)
            var passages: [ScripturePassage] = []
            var unresolvedEntries = parseResult.unresolvedEntries

            for reference in parseResult.references {
                do {
                    passages.append(try provider.fetchPassage(for: reference))
                } catch {
                    unresolvedEntries.append(reference.normalizedReference)
                }
            }

            guard !passages.isEmpty else {
                previewContext = nil
                message = "We couldn't resolve any passages from that input."
                return
            }

            let deduplicatedUnresolvedEntries = deduplicatedEntries(unresolvedEntries)
            previewContext = ScriptureAddPreviewContext(passages: passages)

            var parts: [String] = ["\(passages.count) resolved"]
            let duplicateCount = duplicateCount(for: passages)
            if duplicateCount > 0 {
                parts.append("\(duplicateCount) already saved")
            }
            if !deduplicatedUnresolvedEntries.isEmpty {
                parts.append("\(deduplicatedUnresolvedEntries.count) unresolved")
            }
            message = parts.joined(separator: " • ")
        } catch {
            previewContext = nil
            message = error.localizedDescription
        }
    }

    private func duplicateCount(for passages: [ScripturePassage]) -> Int {
        let existingKeys = ScriptureAddPipeline.existingReferenceKeys()
        return passages.reduce(into: 0) { total, passage in
            if existingKeys.contains(ScriptureAddPipeline.normalizedReferenceKey(passage.normalizedReference)) {
                total += 1
            }
        }
    }

    private func deduplicatedEntries(_ entries: [String]) -> [String] {
        var seen: Set<String> = []
        var deduplicated: [String] = []

        for entry in entries {
            let normalizedEntry = ScriptureAddPipeline.normalizedReferenceKey(entry)
            if seen.insert(normalizedEntry).inserted {
                deduplicated.append(entry)
            }
        }

        return deduplicated
    }
}

#Preview {
    NavigationStack {
        AddVerseView(onSave: { _ in })
    }
}
