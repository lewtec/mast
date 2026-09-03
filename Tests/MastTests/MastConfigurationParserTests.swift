import Foundation
import Testing
import AppKit
@testable import Mast

struct MastConfigurationParserTests {
    @MainActor
    @Test
    func markdownHighlightingPreservesLiteralDashes() {
        let source = "---\ntitle: Test\n---\n\n# Heading\n\n----"
        let storage = NSTextStorage(string: source)

        MarkdownHighlighter.apply(to: storage)

        #expect(storage.string == source)
    }

    @Test
    func parsesServerAndContentPackages() throws {
        let configuration = try MastConfigurationParser.parse("""
        [server]
        preset = "hugo"
        command = "hugo server --port {port}"
        url = "http://127.0.0.1:{port}"

        [server.options.hugo]
        drafts = true
        future = false

        [content.packages.blog]
        path = "content/blog"
        route = "/{path}"

        [content.packages.docs]
        path = "content/docs"
        languages = ["pt", "en"]
        route = "/{lang}/{path}"
        """)

        #expect(configuration.server.preset == "hugo")
        #expect(configuration.autosaveDelayMilliseconds == 1_000)
        #expect(configuration.packages.map(\.name) == ["blog", "docs"])
        #expect(configuration.packages[1].languages == ["pt", "en"])
    }

    @Test
    func requiresServerURL() {
        #expect(throws: MastConfigurationError.missingServerValue("url")) {
            try MastConfigurationParser.parse("""
            [server]
            preset = "custom"
            command = "serve"

            [content.packages.blog]
            path = "content/blog"
            route = "/{path}"
            """)
        }
    }

    @Test
    func writerCreatesConfigurationThatTheParserCanRead() throws {
        let rootURL = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        try MastConfigurationWriter.write(
            to: rootURL,
            preset: "hugo",
            command: "hugo server --port {port}",
            url: "http://127.0.0.1:{port}",
            autosaveDelayMilliseconds: 1_500,
            packages: [SetupPackage(name: "blog", path: "content", route: "/{path}", languages: ["pt", "en"])]
        )

        let source = try String(contentsOf: rootURL.appending(path: "mast.toml"), encoding: .utf8)
        let configuration = try MastConfigurationParser.parse(source)

        #expect(configuration.packages.first?.path == "content")
        #expect(configuration.packages.first?.languages == ["pt", "en"])
        #expect(configuration.autosaveDelayMilliseconds == 1_500)
    }

    @Test
    func writerPreservesServerOptionsWhenReconfiguring() throws {
        let rootURL = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let existingSource = """
        [server]
        preset = "hugo"

        [server.options.hugo]
        drafts = true
        """

        try MastConfigurationWriter.write(
            to: rootURL,
            preset: "hugo",
            command: "hugo server --port {port}",
            url: "http://127.0.0.1:{port}",
            autosaveDelayMilliseconds: 1_000,
            packages: [SetupPackage(name: "blog", path: "content", route: "/{path}")],
            serverOptionsSource: MastConfigurationWriter.serverOptionsSource(from: existingSource)
        )

        let writtenSource = try String(contentsOf: rootURL.appending(path: "mast.toml"), encoding: .utf8)

        #expect(writtenSource.contains("[server.options.hugo]\ndrafts = true"))
    }

    @Test
    func discoversOnlyFoldersContainingPostIndexFolders() throws {
        let rootURL = URL.temporaryDirectory.appending(path: UUID().uuidString)
        let contentURL = rootURL.appending(path: "content/blog/post")
        let localizedPostURL = rootURL.appending(path: "content/blog/localized-post")
        let notesURL = rootURL.appending(path: "notes")
        try FileManager.default.createDirectory(at: contentURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: localizedPostURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: notesURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        try "# Post".write(to: contentURL.appending(path: "index.md"), atomically: true, encoding: .utf8)
        try "# Post".write(to: localizedPostURL.appending(path: "index.en.mdx"), atomically: true, encoding: .utf8)
        try "# Post".write(to: localizedPostURL.appending(path: "index.pt.md"), atomically: true, encoding: .utf8)
        try "# Note".write(to: notesURL.appending(path: "readme.md"), atomically: true, encoding: .utf8)
        try "# Root".write(to: rootURL.appending(path: "README.md"), atomically: true, encoding: .utf8)

        let discovery = MarkdownContentDiscovery.discover(at: rootURL)

        #expect(discovery.packages.map(\.path) == ["content/blog"])
        #expect(discovery.packages.first?.languages == ["en", "pt"])
        #expect(!discovery.hasRootMarkdown)
    }

    @Test
    func loadsMarkdownAndMDXPosts() throws {
        let rootURL = URL.temporaryDirectory.appending(path: UUID().uuidString)
        let markdownPostURL = rootURL.appending(path: "content/markdown-post")
        let mdxPostURL = rootURL.appending(path: "content/mdx-post")
        try FileManager.default.createDirectory(at: markdownPostURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: mdxPostURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        try "# Markdown".write(to: markdownPostURL.appending(path: "index.md"), atomically: true, encoding: .utf8)
        try "# MDX".write(to: mdxPostURL.appending(path: "index.mdx"), atomically: true, encoding: .utf8)
        try """
        [server]
        preset = "custom"
        command = "echo server"
        url = "http://127.0.0.1:{port}"

        [content.packages.posts]
        path = "content"
        route = "/{path}"
        """.write(to: rootURL.appending(path: "mast.toml"), atomically: true, encoding: .utf8)

        let project = try ProjectLoader.load(at: rootURL)

        #expect(project.posts.map(\.fileURL.lastPathComponent) == ["index.md", "index.mdx"])
    }

    @MainActor
    @Test
    func groupsPostLanguagesInThePostList() {
        let english = Post(
            fileURL: URL(filePath: "/tmp/hello/index.en.md"),
            packageName: "posts",
            language: "en",
            relativePath: "hello"
        )
        let portuguese = Post(
            fileURL: URL(filePath: "/tmp/hello/index.pt.md"),
            packageName: "posts",
            language: "pt",
            relativePath: "hello"
        )

        let view = PostListView(
            posts: [english, portuguese],
            selection: .constant(english),
            configureProject: {}
        )

        #expect(view.displayPosts == [english])
        #expect(view.languages(for: english) == ["en", "pt"])
    }

    @Test
    func resolvesPreviewRouteForSelectedPostLanguage() {
        let package = ContentPackage(
            name: "posts",
            path: "content/posts",
            route: "/{lang}/post/{path}",
            languages: ["en", "pt"]
        )
        let post = Post(
            fileURL: URL(filePath: "/tmp/hello/index.pt.md"),
            packageName: "posts",
            language: "pt",
            relativePath: "2026/hello world"
        )
        let project = Project(
            rootURL: URL(filePath: "/tmp"),
            configuration: MastConfiguration(server: ServerConfiguration(preset: "custom", command: "serve", url: "http://127.0.0.1:{port}"), packages: [package]),
            posts: [post]
        )

        let url = project.previewURL(for: post, from: URL(string: "http://127.0.0.1:4321/")!)

        #expect(url.absoluteString == "http://127.0.0.1:4321/pt/post/2026/hello%20world")
    }

    @MainActor
    @Test
    func createsPostInSelectedPackageUsingDefaultLanguage() throws {
        let rootURL = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        try """
        [server]
        preset = "custom"
        command = "true"
        url = "http://127.0.0.1:{port}"

        [content.packages.posts]
        path = "content/posts"
        languages = ["en", "pt"]
        route = "/{lang}/post/{path}"
        """.write(to: rootURL.appending(path: "mast.toml"), atomically: true, encoding: .utf8)

        let model = AppModel()
        model.openProject(at: rootURL)
        let package = try #require(model.project?.configuration.packages.first)

        #expect(model.createPost(in: package, slug: "hello", language: package.languages.first))
        #expect(FileManager.default.fileExists(atPath: rootURL.appending(path: "content/posts/hello/index.en.md").path()))
        #expect(model.project?.posts.count == 1)
        #expect(model.selectedPost?.fileURL.lastPathComponent == "index.en.md")
        let englishPost = try #require(model.selectedPost)
        #expect(model.addLanguage("pt", to: englishPost))
        #expect(FileManager.default.fileExists(atPath: rootURL.appending(path: "content/posts/hello/index.pt.md").path()))
        #expect(model.selectedPost?.fileURL.lastPathComponent == "index.pt.md")
    }
}
