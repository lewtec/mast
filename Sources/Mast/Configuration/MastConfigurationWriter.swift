import Foundation

enum MastConfigurationWriter {
    static func write(_ configuration: MastConfiguration, to rootURL: URL) throws {
        var sections = ["""
        [server]
        preset = "\(configuration.server.preset)"
        command = "\(configuration.server.command)"
        url = "\(configuration.server.url)"

        [editor]
        autosave_delay_ms = \(configuration.autosaveDelayMilliseconds)
        """]
        if !configuration.serverOptionsSource.isEmpty {
            sections.append(configuration.serverOptionsSource)
        }
        sections.append(contentsOf: configuration.packages.map(packageSource))
        let source = sections.joined(separator: "\n\n")

        try source.write(to: rootURL.appending(path: "mast.toml"), atomically: true, encoding: .utf8)
    }

    private static func packageSource(_ package: ContentPackage) -> String {
        let languages = package.languages.isEmpty ? "" : "\nlanguages = [\(package.languages.map { "\"\($0)\"" }.joined(separator: ", "))]"
        return """
        [content.packages.\(package.name)]
        path = "\(package.path)"
        \(languages)
        route = "\(package.route)"
        """
    }
}
