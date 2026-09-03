import Foundation

enum MastConfigurationWriter {
    static func write(
        to rootURL: URL,
        preset: String,
        command: String,
        url: String,
        packages: [SetupPackage]
    ) throws {
        let source = """
        [server]
        preset = "\(preset)"
        command = "\(command)"
        url = "\(url)"

        \(packages.map(packageSource).joined(separator: "\n\n"))
        """

        try source.write(to: rootURL.appending(path: "mast.toml"), atomically: true, encoding: .utf8)
    }

    private static func packageSource(_ package: SetupPackage) -> String {
        let languages = package.languages.isEmpty ? "" : "\nlanguages = [\(package.languages.map { "\"\($0)\"" }.joined(separator: ", "))]"
        return """
        [content.packages.\(package.name)]
        path = "\(package.path)"
        \(languages)
        route = "\(package.route)"
        """
    }
}
