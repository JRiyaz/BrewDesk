import AppKit
import SwiftUI

struct AppSidebar: View {
    @Binding var selection: AppSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("BrewDesk")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Mac utilities")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 6) {
                SidebarGroupLabel(title: "HOMEBREW")
                ForEach(AppSection.homebrew) { section in
                    SidebarItem(section: section, isSelected: selection == section) {
                        selection = section
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                SidebarGroupLabel(title: "UTILITIES")
                ForEach(AppSection.utilities) { section in
                    SidebarItem(section: section, isSelected: selection == section) {
                        selection = section
                    }
                }
            }
            
            Spacer(minLength: 8)
            
            VStack(alignment: .leading, spacing: 12) {
                Divider().overlay(AppTheme.separator)
                SidebarItem(section: .settings, isSelected: selection == .settings) {
                    selection = .settings
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .frame(minWidth: 205, idealWidth: 228, maxWidth: 255, maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial)
        .navigationSplitViewColumnWidth(min: 205, ideal: 228, max: 255)
    }
}

private struct SidebarGroupLabel: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .tracking(1.2)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 11)
            .padding(.top, 4)
            .padding(.bottom, 3)
    }
}

private struct SidebarItem: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: section.symbol)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 19)
                    .foregroundStyle(isSelected ? AppTheme.accent : Color.secondary)
                
                Text(section.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .frame(height: 38)
            .contentShape(AppTheme.compactShape)
            .background {
                if isSelected {
                    AppTheme.compactShape.fill(AppTheme.accent.opacity(0.07))
                }
            }
            .overlay {
                if isSelected {
                    AppTheme.compactShape.strokeBorder(AppTheme.accent.opacity(0.10), lineWidth: 0.7)
                }
            }
            .modifier(SelectedSidebarGlass(isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct SelectedSidebarGlass: ViewModifier {
    let isSelected: Bool
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if isSelected {
            content.glassEffect(
                .regular.tint(AppTheme.accent.opacity(0.07)),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        } else {
            content
        }
    }
}
