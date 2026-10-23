import Foundation

struct ProcessResult: Sendable {
    let standardOutput: String
    let standardError: String
    let exitCode: Int32
}

enum ProcessRunnerError: LocalizedError {
    case launchFailed(String)
    case timedOut(TimeInterval)
    
    var errorDescription: String? {
        switch self {
        case .launchFailed(let reason):
            return "The command could not be started. \(reason)"
        case .timedOut(let seconds):
            return "The command did not finish within \(Int(seconds.rounded(.up))) seconds. Try again or verify Homebrew is working."
        }
    }
}

/// Runs one explicitly selected executable with an argument array. No shell is involved.
/// Output streams are drained concurrently to avoid pipe-buffer deadlocks. Cancellation and
/// timeout only affect this individual, user-initiated process; nothing stays resident.
enum ProcessRunner {
    static func run(
        executableURL: URL,
        arguments: [String],
        timeout: TimeInterval = 20
    ) async throws -> ProcessResult {
        try Task.checkCancellation()
        
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.environment = commandEnvironment()
        
        let timeoutMarker = TimeoutMarker()
        let timeoutWorkItem = DispatchWorkItem {
            guard process.isRunning else { return }
            timeoutMarker.markTimedOut()
            process.terminate()
        }
        
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            do {
                try process.run()
            } catch {
                throw ProcessRunnerError.launchFailed(error.localizedDescription)
            }
            
            DispatchQueue.global(qos: .utility).asyncAfter(
                deadline: .now() + timeout,
                execute: timeoutWorkItem
            )
            
            let stdoutHandle = stdoutPipe.fileHandleForReading
            let stderrHandle = stderrPipe.fileHandleForReading
            let stdoutTask = Task.detached(priority: .utility) {
                stdoutHandle.readDataToEndOfFile()
            }
            let stderrTask = Task.detached(priority: .utility) {
                stderrHandle.readDataToEndOfFile()
            }
            let exitCode = await Task.detached(priority: .utility) {
                process.waitUntilExit()
                return process.terminationStatus
            }.value
            
            timeoutWorkItem.cancel()
            let stdoutData = await stdoutTask.value
            let stderrData = await stderrTask.value
            
            try Task.checkCancellation()
            if timeoutMarker.didTimeOut {
                throw ProcessRunnerError.timedOut(timeout)
            }
            
            return ProcessResult(
                standardOutput: String(decoding: stdoutData, as: UTF8.self),
                standardError: String(decoding: stderrData, as: UTF8.self),
                exitCode: exitCode
            )
        } onCancel: {
            if process.isRunning {
                process.terminate()
            }
        }
    }
    
    private static func commandEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["HOMEBREW_NO_ANALYTICS"] = "1"
        let inheritedPath = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        environment["PATH"] = [
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/usr/local/bin",
            "/usr/local/sbin",
            inheritedPath
        ].joined(separator: ":")
        return environment
    }
}

private final class TimeoutMarker: @unchecked Sendable {
    private let lock = NSLock()
    private var timedOut = false
    
    func markTimedOut() {
        lock.lock()
        timedOut = true
        lock.unlock()
    }
    
    var didTimeOut: Bool {
        lock.lock()
        defer { lock.unlock() }
        return timedOut
    }
}
