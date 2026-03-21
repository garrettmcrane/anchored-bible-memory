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
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColors.scriptureAccent)

                    if showingAnswer {
                        Text(verse.text)
                            .font(.title3)
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
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(AppColors.secondaryButton)
                                    .foregroundStyle(AppColors.secondaryButtonText)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }

                            Button {
                                recordReview(result: .correct)
                            } label: {
                                Text("Got It")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(AppColors.primaryButton)
                                    .foregroundStyle(AppColors.primaryButtonText)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        Button {
                            showingAnswer = true
                        } label: {
                            Text("Reveal Verse")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppColors.primaryButton)
                                .foregroundStyle(AppColors.primaryButtonText)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
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
