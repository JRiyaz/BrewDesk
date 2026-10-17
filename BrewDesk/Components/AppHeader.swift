import SwiftUI

struct AppHeader: View {
    let section: AppSection
    @Binding var searchText: String
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(section.title)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(section.subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            if section.supportsSearch {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    TextField("Search \(section.title.lowercased())", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .autocorrectionDisabled()
                        .accessibilityLabel("Search \(section.title)")
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, 11)
                .frame(width: 245, height: 34)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppTheme.separator, lineWidth: 0.8)
                }
            }

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(.regularMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(AppTheme.separator, lineWidth: 0.8))
            }
            .buttonStyle(.plain)
            .help("Settings")
            .accessibilityLabel("Open Settings")
            .disabled(section == .settings)
            .opacity(section == .settings ? 0.45 : 1)
        }
        .padding(.horizontal, 28)
        .frame(height: 76)
        .background(.regularMaterial)
    }
}

typealias AppPageHeader = AppHeader
