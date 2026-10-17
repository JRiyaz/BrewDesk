import SwiftUI

struct MyApp: View {
    @State private var selection: AppSection = .overview
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            AppSidebar(selection: $selection)
        } detail: {
            VStack(spacing: 0) {
                AppPageHeader(
                    section: selection,
                    searchText: $searchText,
                    onOpenSettings: { selection = .settings }
                )
                
                Divider()
                    .overlay(AppTheme.separator)
                
                ScrollView {
                    pageContent
                        .frame(maxWidth: 1020, alignment: .leading)
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
    }
    
    @ViewBuilder
    private var pageContent: some View {
        switch selection {
        case .overview:
            OverviewPage(onNavigate: navigate)
        case .installed:
            InstalledPage(searchText: searchText)
        case .discover:
            DiscoverPage(searchText: searchText)
        case .updates:
            UpdatesPage()
        case .cleaner:
            CleanerPage()
        case .ports:
            PortsPage(searchText: searchText)
        case .commands:
            CommandsPage(searchText: searchText)
        case .settings:
            SettingsPage()
        }
    }
    
    private func navigate(to section: AppSection) {
        searchText = ""
        selection = section
    }
}
