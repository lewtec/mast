import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private(set) var project: Project?
    var selectedPost: Post?
    var editorText = ""
    var errorMessage: String?
    var isShowingError = false
    var previewURL: URL?
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
        serverProcess?.terminate()
        previewTask?.cancel()
        previewURL = nil
        guard let port = PortAllocator.availablePort() else { return }
        let command = project.configuration.server.command.replacing("{port}", with: String(port))
        let process = Process()
        process.executableURL = URL(filePath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.currentDirectoryURL = project.rootURL
        do {
            try process.run()
            serverProcess = process
            let url = URL(string: project.configuration.server.url.replacing("{port}", with: String(port)))
            previewTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self?.previewURL = url
            }
        } catch {
            errorMessage = "Mast could not start the development server: \(error.localizedDescription)"
            isShowingError = true
        }
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
}
