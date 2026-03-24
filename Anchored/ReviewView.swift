import SwiftUI

struct ReviewView: View {
    @Environment(\.dismiss) private var dismiss

    let verse: Verse
    let onUpdate: (Verse) -> Void

    @State private var showingAnswer = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Text(verse.reference)
                        .font(AnchoredFont.editorial(30))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColors.brandBlue)

                    if showingAnswer {
                        Text(verse.text)
                            .font(AnchoredFont.scripture(26))
                            .lineSpacing(8)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppColors.textPrimary)
                            .padding(.horizontal)
                    } else {
                        Text("Try to recite this verse before revealing it.")
                            .font(.headline)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer()

                    if showingAnswer {
                        HStack(spacing: 16) {
                            Button {
                                recordReview(result: .missed)
                            } label: {
                                Text("Missed")
                            }
                            .buttonStyle(AnchoredMissedButtonStyle())

                            Button {
                                recordReview(result: .correct)
                            } label: {
                                Text("Got It")
                            }
                            .buttonStyle(AnchoredSuccessButtonStyle())
                        }
                        .padding(.horizontal)
                    } else {
                        Button {
                            showingAnswer = true
                        } label: {
                            Text("Reveal Verse")
                        }
                        .buttonStyle(AnchoredPrimaryButtonStyle())
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 32)
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppColors.structuralAccent)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func recordReview(result: ReviewResult) {
        let updatedVerse = ReviewRepository.shared.recordReview(
            for: verse,
            method: .flashcard,
            result: result
        )

        onUpdate(updatedVerse)
        dismiss()
    }
}

#Preview {
    let previewVerse = Verse(
        reference: "John 3:16",
        text: "For God so loved the world, that he gave his only Son..."
    )

    return ReviewView(verse: previewVerse, onUpdate: { _ in })
}
