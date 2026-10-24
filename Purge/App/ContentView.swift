import SwiftUI

struct ContentView: View {
    @State private var selection: AppSection = .overview
    @State private var searchText = ""
    @State private var installedFilter: InstalledFilter = .all
    @StateObject private var homebrew = HomebrewStore()
    @StateObject private var moleStore = MoleStore()
    
    var body: some View {
        NavigationSplitView {
            AppSidebar(selection: $selection)
        } detail: {
            VStack(spacing: 0) {
                AppHeader(
                    section: selection,
                    searchText: $searchText,
                    onOpenSettings: { selection = .settings }
                )
                
                Divider()
                    .overlay(AppTheme.separator)
                
                ScrollView {
                    pageContent
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 28)
                }
                .scrollIndicators(.visible)
                .background(AppTheme.canvas)
            }
            .background(AppTheme.canvas)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 980, minHeight: 680)
        .background(AppTheme.canvas)
        .onChange(of: selection) { _, newSelection in
            if newSelection == .services {
                installedFilter = .services
            } else if newSelection == .installed && installedFilter == .services {
                installedFilter = .all
            }
        }
        .onChange(of: installedFilter) { _, newFilter in
            if newFilter == .services && selection == .installed {
                selection = .services
            } else if newFilter != .services && selection == .services {
                selection = .installed
            }
        }
    }
    
    @ViewBuilder
    private var pageContent: some View {
        switch selection {
        case .overview:
            OverviewView(onNavigate: navigate, homebrew: homebrew, moleStore: moleStore)
        case .installed, .services:
            InstalledView(searchText: searchText, homebrew: homebrew, selectedFilter: $installedFilter)
        case .discover:
            DiscoverView(searchText: searchText, homebrew: homebrew)
        case .updates:
            UpdatesView(homebrew: homebrew)
        case .cleaner:
            CleanerView(homebrew: homebrew)
        case .ports:
            PortsView(searchText: searchText)
        case .systemCleaner:
            SystemCleanerView(searchText: searchText)
        case .uninstallGuide:
            AppUninstallGuideView(searchText: searchText)
        case .mole:
            MoleView(searchText: searchText, moleStore: moleStore)
        case .commands:
            CommandsView(searchText: searchText)
        case .settings:
            SettingsView(homebrew: homebrew)
        }
    }
    
    private func navigate(to section: AppSection) {
        searchText = ""
        selection = section
        if section == .services {
            installedFilter = .services
        } else if section == .installed && installedFilter == .services {
            installedFilter = .all
        }
    }
}
