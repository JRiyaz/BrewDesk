import Combine
import Foundation
import SwiftUI

struct SystemCleanCategory: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let subtitle: String
    let path: String
    let symbol: String
    let cleanCommand: String
    let isDeveloperFocused: Bool
    var sizeBytes: Int64 = 0
    var itemCount: Int = 0
    var exists: Bool = false
    
    var sizeFormatted: String {
        guard exists && sizeBytes > 0 else { return "0 B" }
        return ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}

@MainActor
final class SystemCleanerService: ObservableObject {
    @Published private(set) var categories: [SystemCleanCategory] = [
        SystemCleanCategory(
            id: "xcode_derived_data",
            name: "Xcode DerivedData",
            subtitle: "Intermediate build outputs, indexing, and module caches",
            path: ("~/Library/Developer/Xcode/DerivedData" as NSString).expandingTildeInPath,
            symbol: "hammer",
            cleanCommand: "rm -rf ~/Library/Developer/Xcode/DerivedData/*",
            isDeveloperFocused: true
        ),
        SystemCleanCategory(
            id: "mac_trash",
            name: "macOS Trash",
            subtitle: "Deleted files awaiting permanent removal from trash",
            path: ("~/.Trash" as NSString).expandingTildeInPath,
            symbol: "trash",
            cleanCommand: "rm -rf ~/.Trash/*",
            isDeveloperFocused: false
        ),
        SystemCleanCategory(
            id: "app_logs",
            name: "Application Logs",
            subtitle: "Crash reports, diagnostic logs, and application traces",
            path: ("~/Library/Logs" as NSString).expandingTildeInPath,
            symbol: "doc.text.magnifyingglass",
            cleanCommand: "rm -rf ~/Library/Logs/*",
            isDeveloperFocused: false
        ),
        SystemCleanCategory(
            id: "user_caches",
            name: "User App Caches",
            subtitle: "Temporary browser, desktop app, and media caches",
            path: ("~/Library/Caches" as NSString).expandingTildeInPath,
            symbol: "internaldrive",
            cleanCommand: "rm -rf ~/Library/Caches/*",
            isDeveloperFocused: false
        ),
        SystemCleanCategory(
            id: "npm_cache",
            name: "Node / NPM Cache",
            subtitle: "Package manager download archives and metadata",
            path: ("~/.npm" as NSString).expandingTildeInPath,
            symbol: "shippingbox",
            cleanCommand: "npm cache clean --force",
            isDeveloperFocused: true
        ),
        SystemCleanCategory(
            id: "swiftpm_cache",
            name: "Swift Package Manager",
            subtitle: "Cloned Git repositories and compiled binary artifacts",
            path: ("~/Library/Caches/org.swift.swiftpm" as NSString).expandingTildeInPath,
            symbol: "swift",
            cleanCommand: "rm -rf ~/Library/Caches/org.swift.swiftpm/*",
            isDeveloperFocused: true
        ),
        SystemCleanCategory(
            id: "pip_cache",
            name: "Python / Pip Cache",
            subtitle: "Cached Python wheels and tarballs",
            path: ("~/Library/Caches/pip" as NSString).expandingTildeInPath,
            symbol: "curlybraces",
            cleanCommand: "pip cache purge",
            isDeveloperFocused: true
        )
    ]
    
    @Published private(set) var isScanning = false
    @Published private(set) var isCleaning = false
    @Published private(set) var activeCategoryCleaning: String?
    @Published private(set) var lastScannedAt: Date?
    @Published private(set) var message: String?
    
    var totalReclaimableBytes: Int64 {
        categories.reduce(0) { $0 + $1.sizeBytes }
    }
    
    var totalReclaimableFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalReclaimableBytes, countStyle: .file)
    }
    
    func scanAll() async {
        guard !isScanning else { return }
        isScanning = true
        message = nil
        defer { isScanning = false }
        
        let currentCats = self.categories
        
        let updatedCats = await Task.detached(priority: .userInitiated) { () -> [SystemCleanCategory] in
            var updated: [SystemCleanCategory] = []
            let fm = FileManager.default
            
            for var cat in currentCats {
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: cat.path, isDirectory: &isDir) {
                    cat.exists = true
                    var totalSize: Int64 = 0
                    var count = 0
                    
                    if isDir.boolValue {
                        let url = URL(fileURLWithPath: cat.path)
                        if let enumerator = fm.enumerator(
                            at: url,
                            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                            options: [.skipsHiddenFiles]
                        ) {
                            while let fileURL = enumerator.nextObject() as? URL {
                                if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                                   let isSubDir = values.isDirectory, !isSubDir,
                                   let size = values.fileSize {
                                    totalSize += Int64(size)
                                    count += 1
                                }
                            }
                        }
                    } else if let attrs = try? fm.attributesOfItem(atPath: cat.path),
                              let size = attrs[.size] as? Int64 {
                        totalSize = size
                        count = 1
                    }
                    
                    cat.sizeBytes = totalSize
                    cat.itemCount = count
                } else {
                    cat.exists = false
                    cat.sizeBytes = 0
                    cat.itemCount = 0
                }
                updated.append(cat)
            }
            return updated
        }.value
        
        self.categories = updatedCats
        self.lastScannedAt = Date()
    }
    
    @discardableResult
    func cleanCategory(_ category: SystemCleanCategory) async -> Bool {
        guard !isCleaning else { return false }
        isCleaning = true
        activeCategoryCleaning = category.id
        message = nil
        defer {
            isCleaning = false
            activeCategoryCleaning = nil
        }
        
        let fm = FileManager.default
        let path = category.path
        
        let success = await Task.detached(priority: .userInitiated) { () -> Bool in
            guard fm.fileExists(atPath: path) else { return true }
            do {
                let contents = try fm.contentsOfDirectory(atPath: path)
                for item in contents {
                    let fullPath = (path as NSString).appendingPathComponent(item)
                    try? fm.removeItem(atPath: fullPath)
                }
                return true
            } catch {
                return false
            }
        }.value
        
        if success {
            self.message = "Successfully cleared \(category.name)."
            await scanAll()
            return true
        } else {
            self.message = "Permission restricted or unable to remove some files in \(category.name)."
            await scanAll()
            return false
        }
    }
}
