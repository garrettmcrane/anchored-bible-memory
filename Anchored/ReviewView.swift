import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let verse: Verse

    @State private var showingAnswer = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text(verse.reference)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                if showingAnswer {
                    Text(verse.text)
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
                            markMissed()
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
                            markCorrect()
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
            .padding(.vertical, 32)
            .navigationTitle("Review")
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

    private func markCorrect() {
        verse.correctCount += 1
        verse.reviewCount += 1
        verse.lastReviewedAt = Date()

        if verse.correctCount >= Verse.masteryGoal {
            verse.isMastered = true
        }

        try? modelContext.save()
        dismiss()
    }

    private func markMissed() {
        verse.correctCount = 0
        verse.isMastered = false
        verse.reviewCount += 1
        verse.lastReviewedAt = Date()

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let previewVerse = Verse(
        reference: "John 3:16",
        text: "For God so loved the world, that he gave his only Son..."
    )

    return ReviewView(verse: previewVerse)
        .modelContainer(for: Verse.self, inMemory: true)
}
