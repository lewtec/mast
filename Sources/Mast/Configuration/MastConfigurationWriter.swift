import Foundation

enum MastConfigurationWriter {
    static func write(
        to rootURL: URL,
        preset: String,
        command: String,
        url: String,
        autosaveDelayMilliseconds: Int,
        packages: [SetupPackage],
        serverOptionsSource: String = ""
    ) throws {
        var sections = ["""
        [server]
        preset = "\(preset)"
        command = "\(command)"
        url = "\(url)"

        [editor]
        autosave_delay_ms = \(autosaveDelayMilliseconds)
        """]
        if !serverOptionsSource.isEmpty {
            sections.append(serverOptionsSource)
        }
        sections.append(contentsOf: packages.map(packageSource))
        let source = sections.joined(separator: "\n\n")

        try source.write(to: rootURL.appending(path: "mast.toml"), atomically: true, encoding: .utf8)
    }

    static func serverOptionsSource(from source: String) -> String {
        var sections: [[String]] = []
        var currentSection: [String]?

        for line in source.components(separatedBy: .newlines) {
            if line.hasPrefix("[") && line.hasSuffix("]") {
                if let currentSection {
                    sections.append(currentSection)
                }
                currentSection = line.hasPrefix("[server.options.") ? [line] : nil
            } else if currentSection != nil {
                currentSection?.append(line)
            }
        }

        if let currentSection {
            sections.append(currentSection)
        }

        return sections.map { $0.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: "\n\n")
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
