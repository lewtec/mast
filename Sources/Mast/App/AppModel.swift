import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private(set) var project: Project?
    var selectedPost: Post?
    var errorMessage: String?
    var isShowingError = false
    var setupRootURL: URL?
    var isShowingSetup = false
    var isShowingProjectSetup = false
    var isShowingNewPost = false
    var isPreviewVisible = true
    let server = DevelopmentServer()
    let openDocument = OpenDocument()

    var previewURL: URL? {
        guard let serverURL = server.readyURL else { return nil }
        guard let project else { return serverURL }
        return project.previewURL(for: selectedPost, document: openDocument.document, from: serverURL)
    }

    var selectedDocument: PostDocument? {
        get { openDocument.document }
        set {
            guard let newValue else { return }
            selectPost(selectedPost, document: newValue)
        }
    }

    func openProject(at rootURL: URL) {
        let configurationURL = rootURL.appending(path: "mast.toml")
        guard FileManager.default.fileExists(atPath: configurationURL.path()) else {
            setupRootURL = rootURL
            isShowingSetup = true
            return
        }

        let loadedProject: Project
        do {
            loadedProject = try ProjectLoader.load(at: rootURL)
        } catch {
            project = nil
            selectedPost = nil
            openDocument.close()
            server.stop()
            presentError(error.localizedDescription)
            return
        }

        project = loadedProject
        selectPost(loadedProject.posts.first)
        do {
            try server.start(for: loadedProject)
        } catch {
            presentError(server.message)
        }
    }

    func startServer() {
        guard let project else { return }
        do {
            try server.start(for: project)
        } catch {
            presentError(server.message)
        }
    }

    func restartServer() {
        do {
            try server.restart()
        } catch {
            presentError(server.message)
        }
    }

    func stopServer() {
        server.stop()
    }

    func scheduleSave() {
        let delay = project?.configuration.autosaveDelayMilliseconds ?? 1_000
        openDocument.scheduleSave(delayMilliseconds: delay, onError: presentError)
    }

    func save() {
        do {
            try openDocument.save()
        } catch {
            let name = openDocument.document?.fileURL.lastPathComponent ?? "the post"
            presentError("Mast could not save \(name): \(error.localizedDescription)")
        }
    }

    func createPost(in package: ContentPackage, slug: String, language: String?) -> Bool {
        guard let project else { return false }
        do {
            let fileURL = try PostCatalog.create(in: package, slug: slug, language: language, project: project)
            try reloadProject(selecting: fileURL)
            return true
        } catch {
            presentError(error.localizedDescription)
            return false
        }
    }

    func addLanguage(_ language: String, to post: Post) -> Bool {
        guard let project else { return false }
        do {
            let fileURL = try PostCatalog.addLanguage(language, to: post, in: project)
            try reloadProject(selecting: fileURL)
            return true
        } catch PostCatalogError.languageUnavailable, PostCatalogError.languageExists {
            return false
        } catch {
            presentError("Mast could not add \(language): \(error.localizedDescription)")
            return false
        }
    }

    func finishSetup(at rootURL: URL) {
        isShowingSetup = false
        setupRootURL = nil
        openProject(at: rootURL)
    }

    func selectPost(_ post: Post?, document: PostDocument? = nil) {
        selectedPost = post
        do {
            try openDocument.open(document: document ?? post?.defaultDocument, in: post)
        } catch {
            presentError("Mast could not read \(document?.fileURL.lastPathComponent ?? post?.title ?? "the post"): \(error.localizedDescription)")
        }
    }

    func selectedPostChanged(to post: Post?) {
        if openDocument.post?.id == post?.id {
            return
        }
        selectPost(post)
    }

    func previewNavigated(to url: URL) {
        guard let project, let serverURL = server.readyURL else { return }
        guard let match = project.post(matchingPreviewURL: url, from: serverURL) else { return }
        if selectedPost?.id == match.post.id, openDocument.document?.id == match.document.id {
            return
        }
        selectPost(match.post, document: match.document)
    }

    private func reloadProject(selecting fileURL: URL) throws {
        guard let project else { return }
        let reloadedProject = try ProjectLoader.load(at: project.rootURL)
        self.project = reloadedProject
        if let match = reloadedProject.post(containing: fileURL) {
            selectPost(match.post, document: match.document)
        }
    }

    private func presentError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
}
