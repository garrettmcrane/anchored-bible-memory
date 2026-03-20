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
                        .textCase(.uppercase)

                    TextEditor(text: $rawInput)
                        .font(.body)
                        .frame(minHeight: 180)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )

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

                Button("Fetch Preview") {
                    buildPreview()
                }
                .buttonStyle(.borderedProminent)
                .disabled(rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Paste / Type")
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
            message = "ESV is visible for the future, but it is not available until API approval is in place."
            return
        }

        do {
            let references = try ReferenceParser.parse(rawInput)
            let provider = try ScriptureProviderFactory.makeProvider(for: translation)
            let passages = try provider.fetchPassages(for: references)
            previewContext = ScriptureAddPreviewContext(passages: passages)
            message = passages.count == 1 ? "1 passage ready for preview." : "\(passages.count) passages ready for preview."
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
