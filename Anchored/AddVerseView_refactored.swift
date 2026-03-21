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
                TranslationPickerSection(selection: $translation)

                VStack(alignment: .leading, spacing: 12) {
                    Text("References")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                            .overlay {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(
                                        isReferenceEditorFocused ? Color.blue.opacity(0.28) : Color.black.opacity(0.05),
                                        lineWidth: 1
                                    )
                            }

                        TextEditor(text: $rawInput)
                            .focused($isReferenceEditorFocused)
                            .scrollContentBackground(.hidden)
                            .font(.body)
                            .frame(minHeight: 180)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)

                        if rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Enter one or more references")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }

                    HStack {
                        Text("Examples: John 3:16, Genesis 1:3-5, Romans 8")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Paste") {
                            rawInput = UIPasteboard.general.string ?? rawInput
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }

                if let message {
                    AddFlowMessageCard(message: message, tint: message.contains("ready") ? .green : .orange)
                }

                Button("Preview Verse(s)") {
                    buildPreview()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
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
            // The hub stays stable; focus refresh will matter once this flow is reopened.
        }
    }

    private func buildPreview() {
        guard translation.isAvailable else {
            message = "ESV is shown here for what’s next, but it isn’t available yet."
            return
        }

        do {
            let references = try ReferenceParser.parse(rawInput)
            let provider = try ScriptureProviderFactory.makeProvider(for: translation)
            let passages = try provider.fetchPassages(for: references)
            previewContext = ScriptureAddPreviewContext(passages: passages)
            message = passages.count == 1 ? "1 verse ready to review." : "\(passages.count) passages ready to review."
        } catch {
            message = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        AddVerseView(onSave: { _ in })
    }
}
