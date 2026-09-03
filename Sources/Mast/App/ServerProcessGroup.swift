import Darwin
import Foundation

final class ServerProcessGroup: @unchecked Sendable {
    let processIdentifier: pid_t
    let outputHandle: FileHandle

    private let stateLock = NSLock()
    private var running = true
    private var status: Int32?

    var isRunning: Bool {
        stateLock.withLock { running }
    }

    var terminationStatus: Int32 {
        stateLock.withLock { status ?? 0 }
    }

    init(command: String, currentDirectoryURL: URL) throws {
        var descriptors: [Int32] = [0, 0]
        guard pipe(&descriptors) == 0 else {
            throw POSIXError(.init(rawValue: errno) ?? .EIO)
        }

        var fileActions: posix_spawn_file_actions_t?
        var attributes: posix_spawnattr_t?
        guard posix_spawn_file_actions_init(&fileActions) == 0,
              posix_spawnattr_init(&attributes) == 0
        else {
            close(descriptors[0])
            close(descriptors[1])
            throw POSIXError(.EIO)
        }
        defer {
            posix_spawn_file_actions_destroy(&fileActions)
            posix_spawnattr_destroy(&attributes)
        }

        guard posix_spawn_file_actions_adddup2(&fileActions, descriptors[1], STDOUT_FILENO) == 0,
              posix_spawn_file_actions_adddup2(&fileActions, descriptors[1], STDERR_FILENO) == 0,
              posix_spawn_file_actions_addclose(&fileActions, descriptors[0]) == 0,
              posix_spawn_file_actions_addclose(&fileActions, descriptors[1]) == 0
        else {
            close(descriptors[0])
            close(descriptors[1])
            throw POSIXError(.EIO)
        }

        let flags = Int16(POSIX_SPAWN_SETPGROUP)
        guard posix_spawnattr_setflags(&attributes, flags) == 0,
              posix_spawnattr_setpgroup(&attributes, 0) == 0
        else {
            close(descriptors[0])
            close(descriptors[1])
            throw POSIXError(.EIO)
        }

        let launchCommand = "cd -- \(Self.shellQuoted(currentDirectoryURL.path)) && \(command)"
        var arguments: [UnsafeMutablePointer<CChar>?] = ["/bin/zsh", "-lc", launchCommand].map { $0.withCString(strdup) }
        arguments.append(nil)
        defer { arguments.forEach { if let pointer = $0 { free(pointer) } } }
        var environment: [UnsafeMutablePointer<CChar>?] = ProcessInfo.processInfo.environment.map {
            "\($0.key)=\($0.value)".withCString(strdup)
        }
        environment.append(nil)
        defer { environment.forEach { if let pointer = $0 { free(pointer) } } }

        var identifier: pid_t = 0
        let spawnResult = posix_spawn(
            &identifier,
            "/bin/zsh",
            &fileActions,
            &attributes,
            &arguments,
            &environment
        )
        close(descriptors[1])
        guard spawnResult == 0 else {
            close(descriptors[0])
            throw POSIXError(.init(rawValue: spawnResult) ?? .EIO)
        }

        processIdentifier = identifier
        outputHandle = FileHandle(fileDescriptor: descriptors[0], closeOnDealloc: true)
        ServerProcessGroup.register(identifier)
    }

    func stop() {
        _ = kill(-processIdentifier, SIGTERM)
        _ = kill(processIdentifier, SIGTERM)
    }

    func waitForTermination() async -> Int32 {
        let identifier = processIdentifier
        return await Task.detached { [weak self] in
            var waitStatus: Int32 = 0
            guard waitpid(identifier, &waitStatus, 0) == identifier else { return -1 }
            let terminationStatus = waitStatus == 0 ? (waitStatus >> 8) & 0xff : 128 + (waitStatus & 0x7f)
            self?.finish(with: terminationStatus)
            return terminationStatus
        }.value
    }

    private func finish(with terminationStatus: Int32) {
        stateLock.withLock {
            running = false
            status = terminationStatus
        }
        outputHandle.readabilityHandler = nil
        ServerProcessGroup.unregister(processIdentifier)
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacing("'", with: "'\\\"'\\\"'"))'"
    }

    private static let groupsLock = NSLock()
    private nonisolated(unsafe) static var groups = Set<pid_t>()

    static func stopAll() {
        let identifiers = groupsLock.withLock { Array(groups) }
        identifiers.forEach {
            _ = kill(-$0, SIGTERM)
            _ = kill($0, SIGTERM)
        }
    }

    private static func register(_ identifier: pid_t) {
        _ = groupsLock.withLock { groups.insert(identifier) }
    }

    private static func unregister(_ identifier: pid_t) {
        _ = groupsLock.withLock { groups.remove(identifier) }
    }
}
