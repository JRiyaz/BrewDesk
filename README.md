# BrewDesk

BrewDesk is a modern, native macOS utility for managing Homebrew packages, background services, listening network ports, and system storage hygiene. Built with Swift and SwiftUI, it delivers a fast, transparent, and local-first Mac developer experience with native glass styling.

---

## Features

### 🍺 Homebrew Workspace
- **Overview:** System status snapshot, installed packages, available updates, and fast navigation across your developer toolkit.
- **Installed Packages:**
  - Fast search and inspection of installed formulae and casks.
  - Toggle between **Direct only** (top-level leaf packages) and all packages (including transitive dependencies).
  - Copy individual install/list commands directly to the clipboard.
- **Background Services:**
  - List and inspect background services configured via Homebrew (e.g. Redis, PostgreSQL, MySQL, Nginx).
  - 1-click **Start** and **Stop** buttons with live status tracking.
  - Copy dynamic service commands (`brew services start <name>`, `brew services stop <name>`).
- **Discover (Catalogue Search):**
  - Live catalogue search across Homebrew **Formulae** and **Casks**.
  - Install status indicators (**Installed**, **Available**, **Disabled**).
  - 1-click package installation with progress indicator and terminal copy command.
- **Updates:**
  - Real-time check for outdated formulae and casks via Homebrew API.
  - Per-package version comparison (Installed vs. Latest).
  - Upgrade individual packages or **Upgrade all** at once.
  - Copy upgrade commands to clipboard.
- **Homebrew Cleaner:**
  - **Autoremove:** Dry-run and uninstall orphaned dependencies (`brew autoremove`).
  - **Clean:** Preview and delete outdated package versions and stale lockfiles (`brew cleanup`).
  - **Purge Cache:** Inspect the full bottle archive cache in `~/Library/Caches/Homebrew` and purge all archives (`brew cleanup --prune=all`) to reclaim disk space.
- **Command Reference:**
  - Curated catalogue of essential Homebrew commands with instant search and 1-click clipboard copying.

### 🛠️ Utilities
- **Listening Ports:**
  - Real-time inspection of active TCP listening ports on your Mac using `lsof`.
  - Filter by **All**, **User / Apps** (e.g. Angular, Vite, Node, Flask), or **System daemons**.
  - Shows process name, PID, user, protocol, and bound address.
  - Safe process termination with confirmation modal and copy kill commands.
- **System Cleaner:**
  - Reclaim gigabytes of disk space across macOS user caches, application logs, and developer stores.
  - Targets **Xcode DerivedData**, **macOS Trash**, **User App Caches**, **Application Logs**, **NPM Cache**, **SwiftPM Cache**, and **Pip Cache**.
  - Filter by Developer vs. System caches, with safe clean actions and copyable `rm -rf` terminal commands.

### ⚙️ Settings
- Automatic detection of Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) Homebrew installations.
- Custom Homebrew executable path configuration with instant validation.
- Appearance preferences: System, Light, and Dark modes.

---

## Design & Architecture

- **Local-first & Idle When Closed:** No login items, background launch daemons, telemetry, or analytics.
- **Process Safety:** Process runner uses explicit executable paths, argument arrays, timeouts, and process tree termination on task cancellation.
- **Copy-First Workflow:** Every action includes a 1-click clipboard copy icon for CLI transparency.
- **Aesthetic Excellence:** Curated macOS dark/light mode palette, SF Symbols, and continuous rounded surfaces.

---

## Project Structure

```text
BrewDesk/
├── MyApp.swift                      # Main application entry point & lifecycle
├── App/
│   ├── AppSection.swift             # Sidebar navigation definitions & groups
│   └── ContentView.swift            # Root layout & page routing
├── Components/
│   ├── AppHeader.swift              # Unified search header & settings button
│   ├── AppSidebar.swift             # Glassmorphic sidebar navigation
│   └── CommonUI.swift               # Reusable UI tokens, cards, and buttons
├── Services/
│   ├── HomebrewClient.swift         # Process execution & Homebrew CLI wrapper
│   ├── HomebrewStore.swift          # Reactive state store for packages & services
│   ├── HomebrewModels.swift         # Data models for formulae, casks, and services
│   ├── PortScannerService.swift     # Port scanning & process termination service
│   ├── CleanerService.swift         # Homebrew cleanup dry-run & cache manager
│   ├── SystemCleanerService.swift   # macOS storage & developer cache scanner
│   ├── ProcessRunner.swift          # Non-blocking async process execution
│   └── ClipboardService.swift       # Pasteboard copy utilities
├── Theme/
│   └── AppTheme.swift               # Design tokens, materials, and colors
└── Views/
    ├── OverviewView.swift           # Dashboard view
    ├── InstalledView.swift          # Formulae, casks, and background services
    ├── DiscoverView.swift           # Online catalogue search
    ├── UpdatesView.swift            # Package update manager
    ├── CleanerView.swift            # 3-section Homebrew cleaner
    ├── PortsView.swift              # Listening ports inspector
    ├── SystemCleanerView.swift      # Mac system & developer storage cleaner
    ├── CommandsView.swift           # CLI commands reference
    └── SettingsView.swift           # Configuration & path validation
```

---

## Requirements & Building

- **macOS:** 14.0 or later (Apple Silicon or Intel).
- **Xcode:** 16.0 or later.
- **Homebrew:** Installed locally at standard paths (`/opt/homebrew` or `/usr/local`) or configured via Settings.

### Building in Xcode
1. Open `BrewDesk.xcodeproj` in Xcode.
2. Select the `BrewDesk` scheme and target `My Mac`.
3. Press `Cmd + R` to build and run.

---

## License

MIT License. See `LICENSE` for details.
