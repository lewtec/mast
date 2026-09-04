import Foundation
import Testing
@testable import Mast

struct CommandPaletteTests {
    @Test
    func welcomeScreenOnlyOffersOpenProject() {
        let items = CommandPalette.items(
            project: nil,
            serverStatus: .stopped,
            isPreviewVisible: true,
            query: ""
        )

        #expect(items.map(\.title) == ["Open project"])
    }

    @Test
    func projectCatalogIncludesActionsAndPosts() {
        let post = Post(
            packageName: "posts",
            relativePath: "hello",
            documents: [PostDocument(fileURL: URL(filePath: "/tmp/hello/index.md"), language: nil)]
        )
        let project = Project(
            rootURL: URL(filePath: "/tmp"),
            configuration: MastConfiguration(
                server: ServerConfiguration(preset: "custom", command: "true", url: "http://127.0.0.1:{port}"),
                packages: [ContentPackage(name: "posts", path: "content", route: "/{path}", languages: [])]
            ),
            posts: [post]
        )

        let items = CommandPalette.items(
            project: project,
            serverStatus: .running,
            isPreviewVisible: true,
            query: ""
        )

        #expect(items.contains(where: { $0.title == "Open project" }))
        #expect(items.contains(where: { $0.title == "Restart server" }))
        #expect(items.contains(where: { $0.title == "Hide preview" }))
        #expect(items.contains(where: { $0.title == "hello" }))
    }

    @Test
    func queryRanksMatchingPostsAndCommands() {
        let post = Post(
            packageName: "posts",
            relativePath: "getting-started",
            documents: [PostDocument(fileURL: URL(filePath: "/tmp/getting-started/index.md"), language: nil)]
        )
        let project = Project(
            rootURL: URL(filePath: "/tmp"),
            configuration: MastConfiguration(
                server: ServerConfiguration(preset: "custom", command: "true", url: "http://127.0.0.1:{port}"),
                packages: [ContentPackage(name: "posts", path: "content", route: "/{path}", languages: [])]
            ),
            posts: [post]
        )

        let restart = CommandPalette.items(
            project: project,
            serverStatus: .running,
            isPreviewVisible: true,
            query: "restart"
        )
        #expect(restart.first?.title == "Restart server")

        let posts = CommandPalette.items(
            project: project,
            serverStatus: .running,
            isPreviewVisible: true,
            query: "getting"
        )
        #expect(posts.first?.title == "getting-started")
        #expect(posts.contains(where: { $0.title == "Restart server" }) == false)
    }
}
