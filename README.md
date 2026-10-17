# BrewDesk

BrewDesk is a lightweight native macOS utility app for managing Homebrew and a small set of system tools. It is built with Swift and SwiftUI, with AppKit used only where macOS integration requires it.

## Goals

- **Native macOS experience:** a clean, adaptive interface with selective Liquid Glass styling.
- **Light and dark appearance:** supports System, Light, and Dark modes.
- **Lightweight and idle when closed:** no login item, LaunchAgent, LaunchDaemon, menu-bar resident agent, recurring timer, or polling loop.
- **Transparent actions:** show command previews and allow copying commands without executing them.
- **Safe by default:** review and confirm destructive actions, avoid silent privilege escalation, and explain permission limits.
- **Local-first:** no account, telemetry, or analytics by default.

## Current Status

The current project is the initial UI/design shell.

### Available in the design shell

- Sidebar navigation for Overview, Installed, Discover, Updates, Cleaner, Ports, Commands, and Settings.
- System, Light, and Dark appearance preferences.
- Curated Homebrew command reference with search and copy-to-clipboard actions.
- Preview, empty, and informational states for features that are not yet connected to system services.
- Foreground application lifecycle intended to quit when the last window is closed.

### Not implemented yet

These screens are not yet connected to their real system operations:

- Listing installed Homebrew formulae and casks.
- Searching the online Homebrew catalogue.
- Checking or installing updates.
- Managing Homebrew services.
- Scanning or removing cache/log/app-leftover files.
- Discovering listening ports or terminating processes.

Do not treat preview screens as proof that those operations are working. Implement and test each service before exposing real system-changing actions.

## Requirements

- A Mac running a compatible version of macOS.
- Xcode and the macOS SDK compatible with the project's deployment target.
- Homebrew installed for Homebrew-specific features once those integrations are implemented.

The project currently targets macOS 27. Confirm that the installed Xcode version provides a compatible SDK before building.

## Open the Project

1. Extract or clone the repository on your Mac.
2. Open `BrewDesk.xcodeproj` in Xcode.
3. Select the `BrewDesk` scheme.
4. Check the deployment target and signing settings.
5. Replace the placeholder bundle identifier `com.example.brewdesk` with your own reverse-DNS identifier before distribution.
6. Build and run the app.

## Development Principles

- Prefer Swift, SwiftUI, Foundation, and system frameworks over unnecessary third-party dependencies.
- Keep views focused on presentation; isolate process execution and system access in testable services.
- Launch known executables using explicit paths and argument arrays; avoid shell interpolation.
- Do not silently request elevated privileges or broad privacy permissions.
- Do not add persistent background work unless the product requirements explicitly change.
- Cancel app-owned work and clean up child processes when the app quits.
- Use conservative allowlists, path validation, review screens, and confirmation for cleanup operations.
- Start process termination with graceful termination and clearly separate any force-termination option.
- Support accessibility settings, keyboard navigation, and semantic system colors.

## Suggested Source Organization

```text
BrewDesk/
├── App/
├── Components/
├── DesignSystem/
├── Features/
│   ├── Overview/
│   ├── Installed/
│   ├── Discover/
│   ├── Updates/
│   ├── Services/
│   ├── Cleaner/
│   ├── Ports/
│   ├── Commands/
│   └── Settings/
├── Domain/
├── Services/
├── Resources/
├── Tests/
└── Docs/
```

This is a suggested organization. Add directories and abstractions when they provide a useful boundary; do not create empty modules just to match the tree.

## Build and Test

Open the project in Xcode and build the `BrewDesk` scheme.

Before considering a feature complete, verify:

- System, Light, and Dark appearances.
- Window close and `⌘Q` quit behavior.
- Loading, empty, success, and error states.
- Cancellation and cleanup of app-owned tasks/processes.
- Permission-denied behavior.
- Unit and UI tests for critical flows.

## Privacy

BrewDesk is intended to be local-first. It should not collect telemetry or analytics by default. Network access should occur only for explicit online catalogue searches or user-requested Homebrew operations that need it.

## License

Add or update the repository's `LICENSE` file before publishing or distributing BrewDesk.
