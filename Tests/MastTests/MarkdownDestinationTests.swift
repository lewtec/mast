import Foundation
import Testing
@testable import Mast

struct MarkdownDestinationTests {
    @Test
    func completesImagesBesideThePost() throws {
        let (project, document, rootURL) = try makeProject(
            files: [
                "content/hello/index.md": "# Hello",
                "content/hello/photo.png": "",
                "content/hello/diagram.webp": "",
            ]
        )
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let text = "See ![alt](ph"
        let cursor = text.utf16.count

        let session = try #require(MarkdownDestination.session(
            in: text,
            cursor: cursor,
            document: document,
            project: project
        ))

        #expect(session.kind == .image)
        #expect(session.items.map(\.title) == ["photo.png"])
        #expect(session.items.first?.insertion == "./photo.png")
    }

    @Test
    func stripsDotSlashFromImageQuery() throws {
        let (project, document, rootURL) = try makeProject(
            files: [
                "content/hello/index.md": "# Hello",
                "content/hello/photo.png": "",
            ]
        )
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let text = "See ![alt](./ph"
        let session = try #require(MarkdownDestination.session(
            in: text,
            cursor: text.utf16.count,
            document: document,
            project: project
        ))

        #expect(session.items.map(\.insertion) == ["./photo.png"])
    }

    @Test
    func completesOtherPostsAndSkipsTheOpenOne() throws {
        let (project, document, rootURL) = try makeProject(
            files: [
                "content/hello/index.en.md": "# Hello",
                "content/world/index.en.md": "# World",
            ],
            languages: ["en"],
            route: "/{lang}/{path}"
        )
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let text = "See [world](wo"
        let session = try #require(MarkdownDestination.session(
            in: text,
            cursor: text.utf16.count,
            document: document,
            project: project
        ))

        #expect(session.kind == .post)
        #expect(session.items.map(\.title) == ["world"])
        #expect(session.items.first?.insertion == "/en/world")
        #expect(!session.items.contains(where: { $0.title == "hello" }))
    }

    @Test
    func ignoresTextThatIsNotAMarkdownDestination() throws {
        let (project, document, rootURL) = try makeProject(files: ["content/hello/index.md": "# Hello"])
        defer { try? FileManager.default.removeItem(at: rootURL) }

        #expect(MarkdownDestination.session(
            in: "plain (wo",
            cursor: 9,
            document: document,
            project: project
        ) == nil)
    }

    @Test
    func hidesWhenDestinationAlreadyMatchesAnItem() throws {
        let (project, document, rootURL) = try makeProject(
            files: [
                "content/hello/index.md": "# Hello",
                "content/hello/photo.png": "",
            ]
        )
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let text = "See ![alt](./photo.png"
        #expect(MarkdownDestination.session(
            in: text,
            cursor: text.utf16.count,
            document: document,
            project: project
        ) == nil)
    }

    @Test
    func replacesOnlyTheDestinationQuery() {
        let text = "See ![alt](ph more"
        let range = NSRange(location: 11, length: 2)

        #expect(MarkdownDestination.replacing(range, in: text, with: "./photo.png") == "See ![alt](./photo.png more")
    }

    private func makeProject(
        files: [String: String],
        languages: [String] = [],
        route: String = "/{path}"
    ) throws -> (Project, PostDocument, URL) {
        let rootURL = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        for (path, contents) in files {
            let fileURL = rootURL.appending(path: path)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try contents.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        let languageLine = languages.isEmpty ? "" : "languages = [\(languages.map { "\"\($0)\"" }.joined(separator: ", "))]\n"
        try """
        [server]
        preset = "custom"
        command = "true"
        url = "http://127.0.0.1:{port}"

        [content.packages.posts]
        path = "content"
        \(languageLine)route = "\(route)"
        """.write(to: rootURL.appending(path: "mast.toml"), atomically: true, encoding: .utf8)

        let project = try ProjectLoader.load(at: rootURL)
        let document = try #require(project.posts.first?.defaultDocument)
        return (project, document, rootURL)
    }
}
