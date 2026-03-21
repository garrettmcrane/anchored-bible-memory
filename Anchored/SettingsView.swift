import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsController: UserSettingsController

    private var appearanceSelection: Binding<AppAppearancePreference> {
        Binding(
            get: { settingsController.settings.preferredAppearance },
            set: { settingsController.updateAppearance($0) }
        )
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Local profile")
                            .font(.headline)
                        Text("Account features coming later")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Profile")
            }

            Section {
                LabeledContent("Translation") {
                    Text(settingsController.settings.selectedTranslation.title)
                        .foregroundStyle(.primary)
                }

                if !BibleTranslation.esv.isAvailable {
                    LabeledContent("ESV") {
                        Text("Coming later")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Scripture & Reading")
            } footer: {
                Text("KJV is the only translation currently available in Anchored.")
            }

            Section {
                Picker("Appearance", selection: appearanceSelection) {
                    ForEach(AppAppearancePreference.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
            } header: {
                Text("Appearance")
            } footer: {
                Text("Applied across the app and saved on this device.")
            }

            Section {
                LabeledContent("Reminders") {
                    Text("Coming later")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Reminders")
            }

            Section {
                LabeledContent("App") {
                    Text("Anchored")
                }

                LabeledContent("Version") {
                    Text(appVersionText)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (version, build) {
        case let (version?, build?) where version != build:
            return "\(version) (\(build))"
        case let (version?, _):
            return version
        case let (_, build?):
            return build
        default:
            return "Unavailable"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(UserSettingsController())
    }
}
