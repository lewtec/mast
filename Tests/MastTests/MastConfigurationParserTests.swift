import Testing
import Foundation
@testable import Mast

struct MastConfigurationParserTests {
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
            packageName: "blog",
            contentPath: "content",
            route: "/{path}"
        )

        let source = try String(contentsOf: rootURL.appending(path: "mast.toml"), encoding: .utf8)
        let configuration = try MastConfigurationParser.parse(source)

        #expect(configuration.packages.first?.path == "content")
    }
}
