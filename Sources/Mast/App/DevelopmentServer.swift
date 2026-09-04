import Foundation
import Observation

@MainActor
@Observable
final class DevelopmentServer {
    private(set) var status: ServerStatus = .stopped
    private(set) var message = "Server has not started."
    private(set) var command: String?
    private(set) var output = ""
    private(set) var readyURL: URL?
    private(set) var address: String?

    private var process: ServerProcessGroup?
    private var previewTask: Task<Void, Never>?
    private var project: Project?

    func start(for project: Project) throws {
        stop()
        self.project = project
        command = nil
        output = ""
        status = .starting
        message = "Starting development server…"
        guard let port = PortAllocator.availablePort() else {
            status = .failed
            message = "Mast could not reserve a port for the development server."
            return
        }
        let command = project.configuration.server.command.replacing("{port}", with: String(port))
        let address = project.configuration.server.url.replacing("{port}", with: String(port))
        self.address = address
        self.command = command
        do {
            let process = try ServerProcessGroup(command: command, currentDirectoryURL: project.rootURL)
            process.outputHandle.readabilityHandler = { [weak self, weak process] handle in
                let data = handle.availableData
                guard !data.isEmpty else {
                    handle.readabilityHandler = nil
                    return
                }
                guard let output = String(data: data, encoding: .utf8) else { return }
                Task { @MainActor [weak self, weak process] in
                    guard let self, let process, self.process === process else { return }
                    self.appendOutput(output)
                }
            }
            Task { @MainActor [weak self, weak process] in
                guard let process else { return }
                let terminationStatus = await process.waitForTermination()
                guard let self, self.process === process else { return }
                self.process = nil
                self.readyURL = nil
                self.status = .failed
                self.message = "Development server exited with status \(terminationStatus)."
            }
            self.process = process
            let url = URL(string: address)
            previewTask = Task { [weak self, weak process] in
                guard let url else {
                    guard let self else { return }
                    self.status = .failed
                    self.message = "Preview URL is not valid: \(address)"
                    return
                }
                guard let self else { return }
                for _ in 0..<20 {
                    guard let process, !Task.isCancelled, self.process === process else { return }
                    guard process.isRunning else {
                        self.status = .failed
                        self.message = "Development server exited before it became ready."
                        return
                    }
                    if await Self.connectionFailure(for: url) == nil {
                        guard !Task.isCancelled, self.process === process else { return }
                        self.status = .running
                        self.message = "Development server is running on port \(port)."
                        self.readyURL = url
                        return
                    }
                    try? await Task.sleep(for: .milliseconds(500))
                }
                guard let process, !Task.isCancelled, self.process === process else { return }
                self.status = .failed
                self.message = "Mast could not reach \(url.absoluteString) after 10 seconds."
            }
        } catch {
            status = .failed
            message = "Mast could not start the development server: \(error.localizedDescription)"
            throw error
        }
    }

    func restart() throws {
        guard let project else { return }
        try start(for: project)
    }

    func stop() {
        let process = process
        self.process = nil
        process?.stop()
        previewTask?.cancel()
        previewTask = nil
        readyURL = nil
        address = nil
        status = .stopped
        message = "Development server stopped."
    }

    private func appendOutput(_ output: String) {
        self.output = String((self.output + output).suffix(6_000))
    }

    private nonisolated static func connectionFailure(for url: URL) async -> String? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 2

        do {
            _ = try await URLSession.shared.data(for: request)
            return nil
        } catch {
            return "Mast could not reach \(url.absoluteString): \(error.localizedDescription)"
        }
    }
}
