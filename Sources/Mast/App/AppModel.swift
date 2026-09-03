import Foundation
import Observation

enum ServerStatus: Equatable {
    case stopped
    case starting
    case running
    case failed

    var label: String {
        switch self {
        case .stopped: "Server stopped"
        case .starting: "Starting server"
        case .running: "Server running"
        case .failed: "Server failed"
        }
    }
}

@MainActor
@Observable
final class AppModel {
    private(set) var project: Project?
    var selectedPost: Post?
    var editorText = ""
    var errorMessage: String?
    var isShowingError = false
    var previewURL: URL?
    var previewAddress: String?
    var serverStatus: ServerStatus = .stopped
    var serverMessage = "Server has not started."
    var serverCommand: String?
    var serverOutput = ""
    var configurationSource = ""
    var setupRootURL: URL?
    var isShowingSetup = false
    private var serverProcess: Process?
    private var saveTask: Task<Void, Never>?
    private var previewTask: Task<Void, Never>?

    func openProject(at rootURL: URL) {
        let configurationURL = rootURL.appending(path: "mast.toml")
        guard FileManager.default.fileExists(atPath: configurationURL.path()) else {
            setupRootURL = rootURL
            isShowingSetup = true
            return
        }

        do {
            let loadedProject = try ProjectLoader.load(at: rootURL)
            project = loadedProject
            configurationSource = try String(contentsOf: configurationURL, encoding: .utf8)
            selectPost(loadedProject.posts.first)
            startServer(for: loadedProject)
        } catch {
            project = nil
            selectedPost = nil
            editorText = ""
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }

    func scheduleSave() {
        guard let post = selectedPost else { return }
        let text = editorText
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            self?.save(text, to: post)
        }
    }

    func save() {
        guard let post = selectedPost else { return }
        save(editorText, to: post)
    }

    func saveConfiguration() -> Bool {
        guard let project else { return false }

        do {
            _ = try MastConfigurationParser.parse(configurationSource)
            try configurationSource.write(
                to: project.rootURL.appending(path: "mast.toml"),
                atomically: true,
                encoding: .utf8
            )
            openProject(at: project.rootURL)
            return true
        } catch {
            errorMessage = "Mast could not save mast.toml: \(error.localizedDescription)"
            isShowingError = true
            return false
        }
    }

    func createPost(in package: ContentPackage, slug: String, language: String?) -> Bool {
        guard let project else { return false }
        guard !slug.isEmpty, !slug.contains("/") else {
            errorMessage = "A post folder name cannot be empty or contain a slash."
            isShowingError = true
            return false
        }

        let postURL = project.rootURL.appending(path: package.path).appending(path: slug)
        let filename = language.map { "index.\($0).md" } ?? "index.md"
        let fileURL = postURL.appending(path: filename)

        guard !FileManager.default.fileExists(atPath: postURL.path()) else {
            errorMessage = "A post named \(slug) already exists in \(package.name)."
            isShowingError = true
            return false
        }

        do {
            try FileManager.default.createDirectory(at: postURL, withIntermediateDirectories: true)
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            let reloadedProject = try ProjectLoader.load(at: project.rootURL)
            self.project = reloadedProject
            let createdPostPath = fileURL.resolvingSymlinksInPath().path()
            selectPost(reloadedProject.posts.first { $0.fileURL.resolvingSymlinksInPath().path() == createdPostPath })
            return true
        } catch {
            errorMessage = "Mast could not create the post: \(error.localizedDescription)"
            isShowingError = true
            return false
        }
    }

    private func save(_ text: String, to post: Post) {
        do {
            try text.write(to: post.fileURL, atomically: true, encoding: .utf8)
        } catch {
            errorMessage = "Mast could not save \(post.fileURL.lastPathComponent): \(error.localizedDescription)"
            isShowingError = true
        }
    }

    private func startServer(for project: Project) {
        let previousProcess = serverProcess
        serverProcess = nil
        previousProcess?.terminate()
        previewTask?.cancel()
        previewURL = nil
        previewAddress = nil
        serverCommand = nil
        serverOutput = ""
        serverStatus = .starting
        serverMessage = "Starting development server…"
        guard let port = PortAllocator.availablePort() else {
            serverStatus = .failed
            serverMessage = "Mast could not reserve a port for the development server."
            return
        }
        let command = project.configuration.server.command.replacing("{port}", with: String(port))
        let address = project.configuration.server.url.replacing("{port}", with: String(port))
        previewAddress = address
        serverCommand = command
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(filePath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.currentDirectoryURL = project.rootURL
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self, weak process] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            guard let output = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self, weak process] in
                guard let self, let process, self.serverProcess === process else { return }
                self.appendServerOutput(output)
            }
        }
        process.terminationHandler = { [weak self] endedProcess in
            Task { @MainActor [weak self] in
                guard let self, self.serverProcess === endedProcess else { return }
                self.serverProcess = nil
                self.previewURL = nil
                self.serverStatus = .failed
                self.serverMessage = "Development server exited with status \(endedProcess.terminationStatus)."
            }
        }
        do {
            try process.run()
            serverProcess = process
            let url = URL(string: address)
            previewTask = Task { [weak self, weak process] in
                guard let url else {
                    guard let self else { return }
                    self.serverStatus = .failed
                    self.serverMessage = "Preview URL is not valid: \(address)"
                    return
                }
                guard let self else { return }
                for _ in 0..<20 {
                    guard let process, !Task.isCancelled, self.serverProcess === process else { return }
                    guard process.isRunning else {
                        self.serverStatus = .failed
                        self.serverMessage = "Development server exited before it became ready."
                        return
                    }
                    if await Self.connectionFailure(for: url) == nil {
                        guard !Task.isCancelled, self.serverProcess === process else { return }
                        self.serverStatus = .running
                        self.serverMessage = "Development server is running on port \(port)."
                        self.previewURL = url
                        return
                    }
                    try? await Task.sleep(for: .milliseconds(500))
                }
                guard let process, !Task.isCancelled, self.serverProcess === process else { return }
                self.serverStatus = .failed
                self.serverMessage = "Mast could not reach \(url.absoluteString) after 10 seconds."
            }
        } catch {
            serverStatus = .failed
            serverMessage = "Mast could not start the development server: \(error.localizedDescription)"
            errorMessage = "Mast could not start the development server: \(error.localizedDescription)"
            isShowingError = true
        }
    }

    private func appendServerOutput(_ output: String) {
        serverOutput = String((serverOutput + output).suffix(6_000))
    }

    func finishSetup(at rootURL: URL) {
        isShowingSetup = false
        setupRootURL = nil
        openProject(at: rootURL)
    }

    func selectPost(_ post: Post?) {
        selectedPost = post

        guard let post else {
            editorText = ""
            return
        }

        do {
            editorText = try String(contentsOf: post.fileURL, encoding: .utf8)
        } catch {
            editorText = ""
            errorMessage = "Mast could not read \(post.fileURL.lastPathComponent): \(error.localizedDescription)"
            isShowingError = true
        }
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
