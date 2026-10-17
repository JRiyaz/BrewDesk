import SwiftUI

struct SettingsPage: View {
    @ObservedObject var homebrew: HomebrewStore
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue
    @AppStorage("customHomebrewPath") private var customHomebrewPath = ""
    @AppStorage("confirmMutatingActions") private var confirmMutatingActions = true
    @State private var validationGeneration = 0

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
                    Text("Leave blank to check standard locations and the app’s PATH. Use the full executable path if Homebrew is installed elsewhere.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        Button {
                            validationGeneration += 1
                        } label: {
                            Label(homebrew.isCheckingInstallation ? "Checking…" : "Validate Path", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(.bordered)
                        .disabled(homebrew.isCheckingInstallation)

                        if let installation = homebrew.installation {
                            Text("Found · \(installation.version) · \(installation.prefix)")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.success)
                                .lineLimit(1)
                                .textSelection(.enabled)
                        } else if let error = homebrew.installationError {
                            Text(error)
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.warning)
                                .lineLimit(8)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                    }
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
                        Text("BrewDesk will show the command and ask for confirmation before a system-changing operation.")
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
                title: "Foreground utility",
                message: "Closing the last window quits BrewDesk. System checks run only when you open a feature or request a refresh; no resident agent or polling loop is used.",
                tint: AppTheme.success
            )

            HStack {
                Text("BrewDesk")
                    .font(.system(size: 10, weight: .semibold))
                Text("•")
                Text("Early access · Version 1.0")
                Spacer()
                Text("Preferences stored on this Mac")
            }
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 2)
        }
        .task(id: validationGeneration) {
            guard validationGeneration > 0 else { return }
            await homebrew.checkInstallation(customPath: customHomebrewPath)
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
