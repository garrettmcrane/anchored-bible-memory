import SwiftUI

struct ReviewView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isRevealed = false
    @State private var verse: Verse

    let onUpdate: (Verse) -> Void

    init(verse: Verse, onUpdate: @escaping (Verse) -> Void) {
        _verse = State(initialValue: verse)
        self.onUpdate = onUpdate
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(verse.reference)
                .font(.title)
                .bold()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(verse.progressText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    if verse.isMastered {
                        Label("Complete", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.green)
                    }
                }

                ProgressView(value: verse.progressValue)
                    .tint(verse.isMastered ? .green : .blue)
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            Spacer()

            if isRevealed {
                Text(verse.text)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                Text("Tap to reveal")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !isRevealed {
                Button("Reveal Verse") {
                    isRevealed = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                HStack(spacing: 16) {

                    Button("Missed") {
                        verse.correctCount = 0
                        verse.isMastered = false
                        onUpdate(verse)
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("Got It") {
                        verse.correctCount += 1
                        if verse.correctCount >= Verse.masteryGoal {
                            verse.isMastered = true
                        }
                        onUpdate(verse)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ReviewView(
        verse: Verse(reference: "John 3:16", text: "Sample verse"),
        onUpdate: { _ in }
    )
}
