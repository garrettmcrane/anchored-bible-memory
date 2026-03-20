import SwiftUI

struct ReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss

    let verses: [Verse]
    let onUpdate: (Verse) -> Void

    @State private var currentIndex = 0
    @State private var showingAnswer = false

    private var currentVerse: Verse {
        verses[currentIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if verses.isEmpty {
                    Spacer()

                    Text("No learning verses to review.")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Spacer()
                } else {
                    Spacer()

                    Text("Verse \(currentIndex + 1) of \(verses.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(currentVerse.reference)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    if showingAnswer {
                        Text(currentVerse.text)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("Try to recite this verse before revealing it.")
                            .font(.headline)
                            .foregroundStyle(.secondary)
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
                                    .background(Color.red.opacity(0.15))
                                    .foregroundStyle(.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }

                            Button {
                                recordReview(result: .correct)
                            } label: {
                                Text("Got It")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundStyle(.green)
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
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 32)
            .navigationTitle("Review Session")
            .navigationBarTitleDisplayMode(.inline)
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
            for: currentVerse,
            method: .flashcard,
            result: result
        )

        onUpdate(updatedVerse)
        moveToNextVerseOrFinish()
    }

    private func moveToNextVerseOrFinish() {
        if currentIndex + 1 < verses.count {
            currentIndex += 1
            showingAnswer = false
        } else {
            dismiss()
        }
    }
}

#Preview {
    let verse1 = Verse(
        reference: "John 3:16",
        text: "For God so loved the world, that he gave his only Son..."
    )

    let verse2 = Verse(
        reference: "Romans 8:28",
        text: "And we know that for those who love God all things work together for good..."
    )

    return ReviewSessionView(verses: [verse1, verse2], onUpdate: { _ in })
}
