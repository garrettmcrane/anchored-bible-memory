import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentPage = 0

    let onFinish: () -> Void

    private let pageCount = 4

    var body: some View {
        ZStack {
            onboardingBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                pages
                footer
            }
        }
    }

    private var header: some View {
        HStack {
            Spacer()

            if currentPage < pageCount - 1 {
                Button("Skip") {
                    onFinish()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.secondarySurface.opacity(0.9))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private var pages: some View {
        TabView(selection: $currentPage) {
            OnboardingPageContainer(
                title: "Welcome to Anchored",
                message: "Anchored helps you memorize Scripture with a focused, simple system built for steady daily practice."
            ) {
                welcomeVisual
            }
            .tag(0)

            OnboardingPageContainer(
                title: "Add verses your way",
                message: "Build your library by typing passages, searching the Bible, or importing a CSV when you already have a list."
            ) {
                addVersesVisual
            }
            .tag(1)

            OnboardingPageContainer(
                title: "Practice what needs work",
                message: "Use Review Practicing to focus on active verses, or Review All when you want to revisit everything together."
            ) {
                reviewVisual
            }
            .tag(2)

            OnboardingPageContainer(
                title: "Stay organized and keep growing",
                message: "Keep verses in folders, study with groups, and track progress from the Me tab as your library grows."
            ) {
                organizationVisual
            }
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .animation(.easeInOut(duration: 0.2), value: currentPage)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button(actionTitle) {
                if currentPage == pageCount - 1 {
                    onFinish()
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentPage += 1
                    }
                }
            }
            .buttonStyle(OnboardingPrimaryButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 28)
    }

    private var welcomeVisual: some View {
        VStack(spacing: 20) {
            Image(colorScheme == .dark ? "LaunchScreen_Dark" : "LaunchScreen_Light")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 230)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppColors.divider.opacity(0.7), lineWidth: 1)
                }
                .shadow(color: AppColors.shadow, radius: 22, y: 10)

            VStack(spacing: 8) {
                Text("A calm place to learn and return to the verses you want to keep close.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, 12)
            }
        }
    }

    private var addVersesVisual: some View {
        VStack(spacing: 16) {
            OnboardingShowcaseCard(title: "Add to Library", subtitle: "Choose the path that fits the moment") {
                VStack(spacing: 12) {
                    OnboardingFeatureRow(
                        title: "Type Verses",
                        subtitle: "Paste or enter a passage manually",
                        systemImage: "keyboard"
                    )
                    OnboardingFeatureRow(
                        title: "Search Bible",
                        subtitle: "Find verses from the built-in Bible",
                        systemImage: "magnifyingglass"
                    )
                    OnboardingFeatureRow(
                        title: "CSV Import",
                        subtitle: "Bring over an existing verse list",
                        systemImage: "square.and.arrow.down"
                    )
                }
            }
        }
    }

    private var reviewVisual: some View {
        VStack(spacing: 14) {
            OnboardingShowcaseCard(title: "Review Loop", subtitle: "Short sessions with clear intent") {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        reviewModeCard(
                            title: "Review Practicing",
                            subtitle: "Focus on verses that still need repetition",
                            systemImage: "flame.fill",
                            tint: AppColors.statusPracticing
                        )
                        reviewModeCard(
                            title: "Review All",
                            subtitle: "Refresh your full library in one pass",
                            systemImage: "books.vertical.fill",
                            tint: AppColors.scriptureAccent
                        )
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(AppColors.structuralAccent)
                        Text("Review, strengthen weak spots, and keep your memorized verses durable.")
                            .font(.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var organizationVisual: some View {
        VStack(spacing: 16) {
            OnboardingShowcaseCard(title: "Keep Momentum Visible", subtitle: "A simple structure around your memory work") {
                VStack(spacing: 12) {
                    OnboardingFeatureRow(
                        title: "Folders",
                        subtitle: "Group verses by topic, season, or study plan",
                        systemImage: "folder.fill"
                    )
                    OnboardingFeatureRow(
                        title: "Groups",
                        subtitle: "Share progress and verse sets with others",
                        systemImage: "person.3.fill"
                    )
                    OnboardingFeatureRow(
                        title: "Me Tab",
                        subtitle: "Track progress, recent activity, and growth",
                        systemImage: "chart.line.uptrend.xyaxis"
                    )
                }
            }
        }
    }

    private func reviewModeCard(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(title)
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .padding(16)
        .background(AppColors.secondarySurface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var onboardingBackground: some View {
        LinearGradient(
            colors: [
                AppColors.background,
                AppColors.subtleAccent.opacity(colorScheme == .dark ? 0.45 : 0.8),
                AppColors.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(AppColors.scriptureAccent.opacity(colorScheme == .dark ? 0.1 : 0.16))
                .frame(width: 180, height: 180)
                .blur(radius: 24)
                .offset(x: 54, y: -36)
        }
    }

    private var actionTitle: String {
        currentPage == pageCount - 1 ? "Get Started" : "Continue"
    }
}

private struct OnboardingPageContainer<Content: View>: View {
    let title: String
    let message: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)

            content

            VStack(spacing: 14) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.textPrimary)

                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}

private struct OnboardingShowcaseCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }

            content
        }
        .padding(20)
        .background(AppColors.surface.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.divider.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: AppColors.shadow, radius: 18, y: 8)
    }
}

private struct OnboardingFeatureRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(AppColors.structuralAccent)
                .frame(width: 42, height: 42)
                .background(AppColors.subtleAccent)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AppColors.secondarySurface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppColors.primaryButtonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppColors.primaryButton.opacity(configuration.isPressed ? 0.88 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppColors.shadow.opacity(configuration.isPressed ? 0.12 : 0.28), radius: 14, y: 8)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

#Preview("Light") {
    OnboardingView { }
}

#Preview("Dark") {
    OnboardingView { }
        .preferredColorScheme(.dark)
}
