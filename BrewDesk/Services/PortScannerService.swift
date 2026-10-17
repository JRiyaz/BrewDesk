import Combine
import Darwin
import Foundation
import SwiftUI

struct ListeningPort: Identifiable, Hashable, Sendable {
    let id: String
    let port: Int
    let portAddress: String
    let processName: String
    let pid: Int
    let user: String
    let isCustom: Bool
    
    var killCommand: String {
        "kill \(pid)"
    }
    
    var inspectCommand: String {
        "lsof -i :\(port)"
    }
    
    var typeTitle: String {
        isCustom ? "Custom / Dev" : "System"
    }
    
    var friendlyDescription: String {
        let lower = processName.lowercased()
        if lower.contains("node") || lower.contains("ng") || lower.contains("angular") {
            return "Node.js / Angular / Frontend"
        } else if lower.contains("python") || lower.contains("flask") || lower.contains("uvicorn") || lower.contains("gunicorn") {
            return "Python / Flask / Backend"
        } else if lower.contains("vite") {
            return "Vite Dev Server"
        } else if lower.contains("docker") {
            return "Docker Container Port"
        } else if lower.contains("postgres") {
            return "PostgreSQL Database"
        } else if lower.contains("redis") {
            return "Redis In-Memory Store"
        } else if lower.contains("controlcenter") {
            return "AirPlay / Control Center"
        } else if lower.contains("rapportd") {
            return "macOS Companion Device Service"
        } else {
            return isCustom ? "User Application" : "macOS System Daemon"
        }
    }
}

enum PortFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case custom = "Custom (Apps & Dev)"
    case system = "System"
    
    var id: String { rawValue }
}

@MainActor
final class PortScannerService: ObservableObject {
    @Published private(set) var ports: [ListeningPort] = []
    @Published private(set) var isScanning = false
    @Published private(set) var scanError: String?
    @Published private(set) var terminatingPID: Int?
    @Published private(set) var lastScannedAt: Date?
    
    var customCount: Int { ports.filter { $0.isCustom }.count }
    var systemCount: Int { ports.filter { !$0.isCustom }.count }
    
    func scanPorts() async {
        guard !isScanning else { return }
        isScanning = true
        scanError = nil
        defer { isScanning = false }
        
        do {
            let executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
            let result = try await ProcessRunner.run(
                executableURL: executableURL,
                arguments: ["-iTCP", "-sTCP:LISTEN", "-n", "-P", "-F", "pcnu"],
                timeout: 10
            )
            
            let parsed = parseLsofOutput(result.standardOutput)
            try Task.checkCancellation()
            self.ports = parsed
            self.lastScannedAt = Date()
            self.scanError = nil
        } catch is CancellationError {
        } catch {
            self.scanError = error.localizedDescription
        }
    }
    
    @discardableResult
    func terminate(port: ListeningPort) async -> Bool {
        guard terminatingPID == nil else { return false }
        terminatingPID = port.pid
        defer { terminatingPID = nil }
        
        // Attempt graceful SIGTERM
        let res = kill(pid_t(port.pid), SIGTERM)
        if res != 0 {
            // Attempt SIGKILL
            _ = kill(pid_t(port.pid), SIGKILL)
        }
        
        // Wait briefly for process to exit
        try? await Task.sleep(nanoseconds: 300_000_000)
        await scanPorts()
        return true
    }
    
    private func parseLsofOutput(_ output: String) -> [ListeningPort] {
        var currentPID: Int?
        var currentCommand: String = ""
        var currentUser: String = ""
        var results: [ListeningPort] = []
        var seen = Set<String>()
        
        for line in output.split(whereSeparator: \.isNewline) {
            let str = String(line)
            guard !str.isEmpty else { continue }
            let prefix = str.prefix(1)
            let value = String(str.dropFirst())
            
            switch prefix {
            case "p":
                currentPID = Int(value)
            case "c":
                currentCommand = value
            case "u":
                currentUser = value
            case "n":
                guard let pid = currentPID else { continue }
                let address = value
                if let colonIndex = address.lastIndex(of: ":") {
                    let portStr = String(address[address.index(after: colonIndex)...])
                    if let portNum = Int(portStr) {
                        let key = "\(pid):\(portNum)"
                        if !seen.contains(key) {
                            seen.insert(key)
                            let isCustom = classifyIsCustom(command: currentCommand, port: portNum)
                            results.append(ListeningPort(
                                id: key,
                                port: portNum,
                                portAddress: address,
                                processName: currentCommand,
                                pid: pid,
                                user: currentUser,
                                isCustom: isCustom
                            ))
                        }
                    }
                }
            default:
                break
            }
        }
        
        return results.sorted {
            if $0.isCustom != $1.isCustom {
                return $0.isCustom && !$1.isCustom
            }
            return $0.port < $1.port
        }
    }
    
    private func classifyIsCustom(command: String, port: Int) -> Bool {
        let lower = command.lowercased()
        
        let systemKeywords = [
            "controlcenter", "rapportd", "ampdevicesagent", "sharingd",
            "identityservicesd", "launchd", "cupsd", "mdnsresponder",
            "airplayxpchelper", "appleidsettingsagent", "locationd",
            "bluetoothd", "wifiagent", "loginwindow", "windowserver",
            "trustd", "opendirectoryd", "syspolicyd", "systemstats",
            "securityd", "hidd", "distnoted", "powerd", "diskarbitrationd",
            "coreaudiod", "coreauthd", "timed", "usbd", "kdc", "findmy"
        ]
        if systemKeywords.contains(where: { lower.contains($0) }) {
            return false
        }
        
        let devKeywords = [
            "node", "python", "flask", "django", "uvicorn", "gunicorn",
            "vite", "angular", "ng", "next", "nuxt", "webpack", "ruby",
            "rails", "puma", "go", "java", "rust", "cargo", "docker",
            "redis", "postgres", "mysql", "mongod", "caddy", "nginx",
            "httpd", "apache", "deno", "bun", "php", "artisan", "live-server",
            "electron", "code", "cursor", "antigravity", "simulator"
        ]
        if devKeywords.contains(where: { lower.contains($0) }) {
            return true
        }
        
        let commonDevPorts: Set<Int> = [
            3000, 3001, 3002, 4200, 5000, 5001, 5173, 5174, 8000, 8080,
            8081, 8888, 9000, 9090, 5432, 6379, 27017, 3306, 11434
        ]
        if commonDevPorts.contains(port) {
            return true
        }
        
        return port >= 1024
    }
}
