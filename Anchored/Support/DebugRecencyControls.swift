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
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.warning)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel("Debug recency simulator")
    }
}
#endif
