import SwiftUI

struct VerseDetailView: View {
    let verse: Verse
    let onStartReview: (ReviewMethod) -> Void

    @State private var isVerseRevealed = false
    @State private var showingReviewMethodPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verse.reference)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    HStack(spacing: 10) {
                        if verse.isMastered {
                            Label("Mastered", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Learning", systemImage: "book.closed")
                                .foregroundStyle(.orange)
                        }

                        Text(verse.progressText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Verse Text")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 16) {
                        if isVerseRevealed {
                            Text(verse.text)
                                .font(.body)
                                .lineSpacing(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Try to recall the verse before revealing it.")
                                    .font(.body)
                                    .foregroundStyle(.secondary)

                                Text("Use “Start Review” to test yourself, or reveal the verse only if you need to study it.")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isVerseRevealed.toggle()
                            }
                        } label: {
                            Text(isVerseRevealed ? "Hide Verse" : "Reveal Verse")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.secondarySystemBackground))
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Progress")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Correct recalls")
                            Spacer()
                            Text("\(verse.correctCount) / \(Verse.masteryGoal)")
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: verse.progress)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.secondarySystemBackground))
                    )
                }

                Button {
                    showingReviewMethodPicker = true
                } label: {
                    Text("Start Review")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Verse")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .confirmationDialog("Choose Review Method", isPresented: $showingReviewMethodPicker, titleVisibility: .visible) {
            ForEach(ReviewMethod.allCases) { method in
                Button(method.title) {
                    onStartReview(method)
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select how you want to review \(verse.reference).")
        }
    }
}

#Preview {
    NavigationStack {
        VerseDetailView(
            verse: Verse(
                reference: "Romans 8:28",
                text: "And we know that for those who love God all things work together for good, for those who are called according to his purpose."
            ),
            onStartReview: { _ in }
        )
    }
}
