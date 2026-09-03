import Testing
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
}
