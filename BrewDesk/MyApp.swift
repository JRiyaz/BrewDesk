import AppKit
import SwiftUI

@main
struct MyApp: App {
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
            CommandGroup(replacing: .newItem) { }
        }
    }
}

/// Closes the app when the last window is closed.
final class AppLifecycle: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

typealias BrewDeskApp = MyApp
