import SwiftUI

struct SettingsPage: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue
    @AppStorage("customHomebrewPath") private var customHomebrewPath = ""
    @AppStorage("confirmMutatingActions") private var confirmMutatingActions = true

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "PREFERENCES",
                title: "Make BrewDesk yours",
                description: "A few thoughtful preferences. No account, analytics, or always-on helper."
            )

            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionHeading(symbol: "circle.lefthalf.filled", title: "Appearance", detail: "Choose how the interface follows your Mac.")

                HStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Theme")
                            .font(.system(size: 12, weight: .semibold))
                        Text("System follows macOS appearance.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Appearance", selection: $appearanceMode) {
                        ForEach(AppAppearance.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.symbolName)
                                .tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 290)
                }
            }
            .padding(19)
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))

            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionHeading(symbol: "shippingbox", title: "Homebrew", detail: "Choose a custom executable path if auto-detection needs an override.")

                VStack(alignment: .leading, spacing: 7) {
                    Text("Custom brew path")
                        .font(.system(size: 11, weight: .semibold))
                    TextField("/opt/homebrew/bin/brew", text: $customHomebrewPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                    Text("Saved locally. Path detection and validation will be connected in a later implementation phase.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(19)
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))

            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionHeading(symbol: "checkmark.shield", title: "Safety", detail: "Keep system-changing workflows explicit.")

                Toggle(isOn: $confirmMutatingActions) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirm system-changing actions")
                            .font(.system(size: 12, weight: .medium))
                        Text("Preference is saved for the planned Homebrew workflows; this preview performs no system changes.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
            .padding(19)
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))

            NotePanel(
                symbol: "moon.zzz",
                title: "Quiet by default",
                message: "Closing the last window quits BrewDesk. This app shell registers no login item, launch agent, daemon, timer, or recurring refresh loop.",
                tint: AppTheme.success
            )

            HStack {
                Text("BrewDesk")
                    .font(.system(size: 10, weight: .semibold))
                Text("•")
                Text("Design preview · Version 1.0")
                Spacer()
                Text("Preferences stored on this Mac")
            }
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 2)
        }
    }
}

private struct SettingsSectionHeading: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 35, height: 35)
                .background(AppTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
