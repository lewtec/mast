import Foundation

enum MastConfigurationWriter {
    static func write(
        to rootURL: URL,
        preset: String,
        command: String,
        url: String,
        packageName: String,
        contentPath: String,
        route: String
    ) throws {
        let source = """
        [server]
        preset = "\(preset)"
        command = "\(command)"
        url = "\(url)"

        [content.packages.\(packageName)]
        path = "\(contentPath)"
        route = "\(route)"
        """

        try source.write(to: rootURL.appending(path: "mast.toml"), atomically: true, encoding: .utf8)
    }
}
