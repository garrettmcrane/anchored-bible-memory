import SwiftUI
import SwiftData

struct ReviewSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var sessionVerses: [Verse]
    @State private var currentIndex: Int = 0
    @State private var isRevealed = false
    @State private var correctAnswers = 0
    @State private var sessionComplete = false

    let onComplete: ([Verse]) -> Void

    init(verses: [Verse], onComplete: @escaping ([Verse]) -> Void) {
        _sessionVerses = State(initialValue: verses)
        self.onComplete = onComplete
    }

    private var currentVerse: Verse {
        sessionVerses[currentIndex]
    }

    private var progressLabel: String {
        "\(currentIndex + 1) of \(sessionVerses.count)"
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessionVerses.isEmpty {
                    emptyState
                } else if sessionComplete {
                    completionView
                } else {
                    activeSessionView
                }
            }
            .navigationTitle("Review Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var activeSessionView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(progressLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView(value: Double(currentIndex + 1), total: Double(sessionVerses.count))
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                Text(currentVerse.reference)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(currentVerse.isMastered ? "Memorized" : "Learning")
                    .font(.subheadline)
                    .foregroundStyle(currentVerse.isMastered ? .green : .orange)
            }

            Spacer()

            VStack(spacing: 16) {
                if isRevealed {
                    Text(currentVerse.text)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        Text("Try to recite the verse before revealing it.")
                            .font(.title3)
                            .multilineTextAlignment(.center)

                        Text("Say it out loud first. Then reveal only if needed.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.secondarySystemBackground))
                        )
                    .padding(.horizontal)
                }
            }

            Spacer()

            if !isRevealed {
                Button {
                    isRevealed = true
                } label: {
                    Text("Reveal Verse")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
            } else {
                HStack(spacing: 16) {
                    Button {
                        recordMissed()
                    } label: {
                        Text("Missed")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        recordCorrect()
                    } label: {
                        Text("Got It")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Session Complete")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("You answered \(correctAnswers) of \(sessionVerses.count) verses correctly.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button {
                onComplete(sessionVerses)
                dismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No verses to review")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add a verse or switch back to the main library.")
                .foregroundStyle(.secondary)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    private func recordMissed() {
        sessionVerses[currentIndex].correctCount = 0
        try? modelContext.save()
        moveToNextVerse()
    }

    private func recordCorrect() {
        sessionVerses[currentIndex].correctCount += 1

        if sessionVerses[currentIndex].correctCount >= Verse.masteryGoal {
            sessionVerses[currentIndex].isMastered = true
        }

        try? modelContext.save()
        correctAnswers += 1
        moveToNextVerse()
    }

    private func moveToNextVerse() {
        if currentIndex + 1 < sessionVerses.count {
            currentIndex += 1
            isRevealed = false
        } else {
            sessionComplete = true
        }
    }
}

#Preview {
    ReviewSessionView(
        verses: [
            Verse(reference: "John 3:16", text: "For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life."),
            Verse(reference: "Romans 8:28", text: "And we know that for those who love God all things work together for good, for those who are called according to his purpose.", correctCount: 1)
        ],
        onComplete: { _ in }
    )
}
