import AppKit

/// Makes closing the last app window behave like quitting a small utility.
/// No login item, menu-bar agent, timer, or background service is registered here.
final class AppLifecycle: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
