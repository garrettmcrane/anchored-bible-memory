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
                VStack(alignment: .leading, spacing: 12) {
                    header

                    VStack(spacing: 10) {
                        NavigationLink {
                            AddVerseView(
                                focusTrigger: focusTrigger,
                                onSave: onSaveVerse,
                                onComplete: onComplete
                            )
                        } label: {
                            AddHubOptionCard(
                                title: "Type Verses",
                                subtitle: "Paste references or messy notes, resolve them against the offline KJV, and save what you want.",
                                systemImage: "doc.text",
                                tint: AppColors.structuralAccent
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
                                tint: AppColors.scriptureAccent
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ImportReferencesView(
                                onSaveVerse: onSaveVerse,
                                onComplete: onComplete
                            )
                        } label: {
                            AddHubOptionCard(
                                title: "Import",
                                subtitle: "Bring in a CSV from Files, review what will be saved, and import many verses at once.",
                                systemImage: "square.and.arrow.down",
                                tint: AppColors.structuralAccent
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AnchoredSpacing.screenHorizontal)
                .padding(.bottom, 24)
            }
            .background(AppColors.background)
            .navigationTitle("Add")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppColors.structuralAccent)
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Build your Scripture library")
                .font(AnchoredFont.editorial(32))
                .foregroundStyle(AppColors.textPrimary)

            Text("Choose how you want to add verses. Paste references, search the bundled Bible, or import a CSV from Files.")
                .font(AnchoredFont.uiSubheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AnchoredCardBackground(elevated: true))
    }
}

private struct AddHubOptionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    var isPlaceholder = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 50, height: 50)

                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(AnchoredFont.ui(17, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)

                    if isPlaceholder {
                        Text("Soon")
                            .font(AnchoredFont.uiCaption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppColors.secondarySurface))
                            .foregroundStyle(tint)
                    }
                }

                Text(subtitle)
                    .font(AnchoredFont.uiSubheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            if !isPlaceholder {
                Image(systemName: "chevron.right")
                    .font(AnchoredFont.uiLabel)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(AppColors.surface))
        .opacity(isPlaceholder ? 0.84 : 1)
    }
}
