import AppKit
import SwiftUI

struct OverviewView: View {
    let onNavigate: (AppSection) -> Void
    @ObservedObject var homebrew: HomebrewStore
    @State private var checkGeneration = 0
    
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private let featureColumns = [GridItem(.adaptive(minimum: 175), spacing: 12)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 27) {
            welcomeCard
            
            if let error = homebrew.installationError {
                NotePanel(
                    symbol: "exclamationmark.triangle",
                    title: "Homebrew wasn't detected",
                    message: "\(error) Open Settings to verify or configure the Homebrew executable path.",
                    tint: AppTheme.warning
                )
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                MetricCard(
                    title: "Homebrew",
                    value: homebrewStatus,
                    detail: homebrew.installation?.prefix ?? "Checks a local executable only",
                    symbol: "shippingbox",
                    statusSymbol: homebrew.installation != nil ? "checkmark.circle.fill" : (homebrew.isCheckingInstallation ? "hourglass" : "circle.dashed")
                )
                MetricCard(
                    title: "Installed packages",
                    value: homebrew.hasLoadedPackages ? "\(homebrew.packages.count)" : "Not loaded",
                    detail: homebrew.hasLoadedPackages ? "\(homebrew.formulaCount) formulae · \(homebrew.caskCount) casks" : "Open Installed to load local packages",
                    symbol: "square.stack.3d.up",
                    statusSymbol: homebrew.hasLoadedPackages ? "checkmark.circle.fill" : "tray"
                )
                MetricCard(
                    title: "Available updates",
                    value: updatesStatus,
                    detail: updatesDetail,
                    symbol: "arrow.triangle.2.circlepath",
                    statusSymbol: updatesStatusSymbol
                )
            }
            
            VStack(alignment: .leading, spacing: 13) {
                SectionCaption(title: "Your toolkit", trailing: "8 tools")
                LazyVGrid(columns: featureColumns, alignment: .leading, spacing: 12) {
                    FeatureTile(section: .installed, detail: "Browse formulae and casks installed locally") { onNavigate(.installed) }
                    FeatureTile(section: .services, detail: "Manage background services and daemons") { onNavigate(.services) }
                    FeatureTile(section: .discover, detail: "Search the online Homebrew catalogue") { onNavigate(.discover) }
                    FeatureTile(section: .updates, detail: "Review pending package updates") { onNavigate(.updates) }
                    FeatureTile(section: .cleaner, detail: "Review caches and leftovers safely") { onNavigate(.cleaner) }
                    FeatureTile(section: .commands, detail: "Browse and copy common commands") { onNavigate(.commands) }
                    FeatureTile(section: .ports, detail: "Inspect listening ports and owners") { onNavigate(.ports) }
                    FeatureTile(section: .systemCleaner, detail: "Reclaim space from logs, Trash, and Xcode") { onNavigate(.systemCleaner) }
                }
            }
            
            
        }
        .task(id: checkGeneration) {
            if checkGeneration > 0 || (homebrew.installation == nil && homebrew.installationError == nil) {
                await homebrew.checkInstallation()
            }
        }
    }
    
    private var homebrewStatus: String {
        if homebrew.isCheckingInstallation { return "Checking…" }
        if let installation = homebrew.installation { return installation.version }
        if homebrew.installationError != nil { return "Not found" }
        return "Not checked"
    }
    
    private var updatesStatus: String {
        if homebrew.isCheckingUpdates { return "Checking…" }
        if homebrew.hasCheckedUpdates {
            return homebrew.outdatedPackages.isEmpty ? "Up to date" : "\(homebrew.outdatedPackages.count)"
        }
        return "Not checked"
    }
    
    private var updatesDetail: String {
        if homebrew.hasCheckedUpdates {
            if homebrew.outdatedPackages.isEmpty {
                return "All packages are on latest versions"
            }
            let formulaCount = homebrew.outdatedPackages.filter { $0.kind == .formula }.count
            let caskCount = homebrew.outdatedPackages.filter { $0.kind == .cask }.count
            return "\(formulaCount) formulae · \(caskCount) casks"
        }
        return "Open Updates to check for pending updates"
    }
    
    private var updatesStatusSymbol: String {
        if homebrew.isCheckingUpdates { return "hourglass" }
        if homebrew.hasCheckedUpdates {
            return homebrew.outdatedPackages.isEmpty ? "checkmark.circle.fill" : "arrow.up.circle.fill"
        }
        return "clock"
    }
    
    private var appIconView: some View {
        Group {
            if let image = NSImage(named: "AppIconImage") {
                Image(nsImage: image)
                    .resizable()
            } else if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
            } else {
                Image("AppIconImage")
                    .resizable()
            }
        }
        .aspectRatio(contentMode: .fit)
        .frame(width: 130, height: 130)
        .shadow(color: Color.black.opacity(0.28), radius: 14, x: 0, y: 7)
    }
    
    private var welcomeCard: some View {
        HStack(alignment: .center, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                StatusPill(
                    title: homebrew.installation == nil ? "LOCAL SYSTEM STATUS" : "HOMEBREW CONNECTED",
                    symbol: homebrew.installation == nil ? "desktopcomputer" : "checkmark.circle.fill",
                    tint: homebrew.installation == nil ? AppTheme.accent : AppTheme.success
                )
                
                Text("Your Mac,\nneatly managed.")
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineSpacing(2)
                
                Text("A quiet, native companion for Homebrew. Review packages, inspect listening ports, and run maintenance only when you choose.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .frame(maxWidth: 510, alignment: .leading)
            }
            
            Spacer(minLength: 0)
            
            appIconView
        }
        .padding(26)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
}

typealias OverviewPage = OverviewView
