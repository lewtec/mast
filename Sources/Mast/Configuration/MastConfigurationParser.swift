import Foundation

enum MastConfigurationParser {
    static func parse(_ source: String) throws -> MastConfiguration {
        var preset: String?
        var command: String?
        var url: String?
        var autosaveDelayMilliseconds = 1_000
        var packageOrder: [String] = []
        var packages: [String: PackageBuilder] = [:]
        var section = Section.none

        for (offset, rawLine) in source.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let lineNumber = offset + 1
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            if line.isEmpty || line.hasPrefix("#") {
                continue
            }

            if line.hasPrefix("[") && line.hasSuffix("]") {
                section = try Section.parse(String(line.dropFirst().dropLast()), lineNumber: lineNumber)

                if case .package(let name) = section, packages[name] == nil {
                    packageOrder.append(name)
                    packages[name] = PackageBuilder()
                }
                continue
            }

            let parts = line.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else {
                throw MastConfigurationError.malformedLine(lineNumber)
            }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)

            switch section {
            case .server:
                try assignServerValue(key: String(key), value: String(value), preset: &preset, command: &command, url: &url, lineNumber: lineNumber)
            case .serverOptions:
                continue
            case .editor:
                autosaveDelayMilliseconds = try assignEditorValue(
                    key: String(key),
                    value: String(value),
                    lineNumber: lineNumber
                )
            case .package(let name):
                try assignPackageValue(key: String(key), value: String(value), package: name, packages: &packages, lineNumber: lineNumber)
            case .none:
                throw MastConfigurationError.malformedLine(lineNumber)
            }
        }

        guard let preset else { throw MastConfigurationError.missingServerValue("preset") }
        guard let command else { throw MastConfigurationError.missingServerValue("command") }
        guard let url else { throw MastConfigurationError.missingServerValue("url") }
        guard !packageOrder.isEmpty else { throw MastConfigurationError.noContentPackages }

        let contentPackages = try packageOrder.map { name in
            guard let package = packages[name], let path = package.path else {
                throw MastConfigurationError.missingPackageValue(name, "path")
            }
            guard let route = package.route else {
                throw MastConfigurationError.missingPackageValue(name, "route")
            }
            return ContentPackage(name: name, path: path, route: route, languages: package.languages)
        }

        return MastConfiguration(
            server: ServerConfiguration(preset: preset, command: command, url: url),
            packages: contentPackages,
            autosaveDelayMilliseconds: autosaveDelayMilliseconds,
            serverOptionsSource: serverOptionsSource(from: source)
        )
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

    private static func assignEditorValue(key: String, value: String, lineNumber: Int) throws -> Int {
        guard key == "autosave_delay_ms", let milliseconds = Int(value), milliseconds >= 0 else {
            throw MastConfigurationError.malformedLine(lineNumber)
        }
        return milliseconds
    }

    private static func assignServerValue(
        key: String,
        value: String,
        preset: inout String?,
        command: inout String?,
        url: inout String?,
        lineNumber: Int
    ) throws {
        switch key {
        case "preset": preset = try stringValue(value, lineNumber: lineNumber)
        case "command": command = try stringValue(value, lineNumber: lineNumber)
        case "url": url = try stringValue(value, lineNumber: lineNumber)
        default: throw MastConfigurationError.malformedLine(lineNumber)
        }
    }

    private static func assignPackageValue(
        key: String,
        value: String,
        package name: String,
        packages: inout [String: PackageBuilder],
        lineNumber: Int
    ) throws {
        guard var package = packages[name] else {
            throw MastConfigurationError.invalidSection(lineNumber)
        }

        switch key {
        case "path": package.path = try stringValue(value, lineNumber: lineNumber)
        case "route": package.route = try stringValue(value, lineNumber: lineNumber)
        case "languages": package.languages = try stringArrayValue(value, lineNumber: lineNumber)
        default: throw MastConfigurationError.malformedLine(lineNumber)
        }

        packages[name] = package
    }

    private static func stringValue(_ value: String, lineNumber: Int) throws -> String {
        guard value.count >= 2, value.first == "\"", value.last == "\"" else {
            throw MastConfigurationError.malformedLine(lineNumber)
        }
        return String(value.dropFirst().dropLast())
    }

    private static func stringArrayValue(_ value: String, lineNumber: Int) throws -> [String] {
        guard value.first == "[", value.last == "]" else {
            throw MastConfigurationError.malformedLine(lineNumber)
        }

        let values = value.dropFirst().dropLast().split(separator: ",")
        return try values.map { try stringValue($0.trimmingCharacters(in: .whitespaces), lineNumber: lineNumber) }
    }
}

private enum Section {
    case none
    case server
    case serverOptions
    case editor
    case package(String)

    static func parse(_ name: String, lineNumber: Int) throws -> Section {
        if name == "server" {
            return .server
        }

        if name.hasPrefix("server.options.") {
            return .serverOptions
        }

        if name == "editor" {
            return .editor
        }

        let prefix = "content.packages."
        if name.hasPrefix(prefix) {
            let packageName = String(name.dropFirst(prefix.count))
            guard !packageName.isEmpty else {
                throw MastConfigurationError.invalidSection(lineNumber)
            }
            return .package(packageName)
        }

        throw MastConfigurationError.invalidSection(lineNumber)
    }
}

private struct PackageBuilder {
    var path: String?
    var route: String?
    var languages: [String] = []
}
