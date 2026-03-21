import SwiftUI

struct AddHubView: View {
    @Environment(\.dismiss) private var dismiss

    let showsCancelButton: Bool
    let focusTrigger: Int
    let onSaveVerse: (Verse) -> Void
    let onComplete: (() -> Void)?

    init(
        showsCancelButton: Bool = false,
        focusTrigger: Int = 0,
        onSaveVerse: @escaping (Verse) -> Void,
        onComplete: (() -> Void)? = nil
    ) {
        self.showsCancelButton = showsCancelButton
        self.focusTrigger = focusTrigger
        self.onSaveVerse = onSaveVerse
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    VStack(spacing: 14) {
                        NavigationLink {
                            AddVerseView(
                                focusTrigger: focusTrigger,
                                onSave: onSaveVerse,
                                onComplete: onComplete
                            )
                        } label: {
                            AddHubOptionCard(
                                title: "Paste / Type",
                                subtitle: "Paste references or messy notes, resolve them against the offline KJV, and save what you want.",
                                systemImage: "doc.text",
                                tint: Color(red: 0.16, green: 0.41, blue: 0.78)
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            BrowseBibleAddView(
                                onSaveVerse: onSaveVerse,
                                onComplete: onComplete
                            )
                        } label: {
                            AddHubOptionCard(
                                title: "Search Bible",
                                subtitle: "Move through the bundled KJV by book and chapter, then preview a verse or range.",
                                systemImage: "magnifyingglass",
                                tint: Color(red: 0.11, green: 0.52, blue: 0.45)
                            )
                        }
                        .buttonStyle(.plain)

                        AddHubOptionCard(
                            title: "Import",
                            subtitle: "Bulk import is planned next. For now, use Paste / Type to bring in references from copied notes.",
                            systemImage: "square.and.arrow.down",
                            tint: Color(red: 0.74, green: 0.44, blue: 0.12),
                            isPlaceholder: true
                        )
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if showsCancelButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Build your Scripture library")
                .font(.system(size: 30, weight: .bold))

            Text("Choose how you want to add verses. Paste references, search the bundled Bible, or come back soon for bulk import.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.18, blue: 0.33),
                            Color(red: 0.21, green: 0.38, blue: 0.56)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .foregroundStyle(.white)
    }
}

private struct AddHubOptionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    var isPlaceholder = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 58, height: 58)

                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if isPlaceholder {
                        Text("Coming Later")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(tint.opacity(0.14)))
                            .foregroundStyle(tint)
                    }
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            if !isPlaceholder {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .opacity(isPlaceholder ? 0.72 : 1)
    }
}
