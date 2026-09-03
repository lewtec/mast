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
    var setupRootURL: URL?
    var isShowingSetup = false

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
            selectPost(loadedProject.posts.first)
        } catch {
            project = nil
            selectedPost = nil
            editorText = ""
            errorMessage = error.localizedDescription
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
