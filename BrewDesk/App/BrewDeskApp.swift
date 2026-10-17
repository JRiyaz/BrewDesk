import AppKit
import SwiftUI

@main
struct BrewDeskApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycle.self) private var appLifecycle
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue

    var body: some Scene {
        WindowGroup("BrewDesk") {
            ContentView()
                .preferredColorScheme(
                    (AppAppearance(rawValue: appearanceMode) ?? .system).colorScheme
                )
        }
        .defaultSize(width: 1220, height: 820)
        .windowResizability(.contentMinSize)
        .commands {
            // BrewDesk is a single-window utility. The red close button exits the app.
            CommandGroup(replacing: .newItem) { }
        }
    }
}
