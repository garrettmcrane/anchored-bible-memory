import SwiftUI

#if DEBUG
struct DebugRecencyControls: View {
    private let debugRecencySimulator = DebugVerseRecencySimulator()
    let onAppliedPreset: () -> Void

    var body: some View {
        Menu {
            ForEach(DebugVerseRecencySimulator.Preset.allCases) { preset in
                Button(preset.title) {
                    debugRecencySimulator.apply(preset)
                    onAppliedPreset()
                }
            }
        } label: {
            Image(systemName: "ladybug")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Debug recency simulator")
    }
}
#endif
