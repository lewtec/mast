import Foundation

enum MastConfigurationParser {
    static func parse(_ source: String) throws -> MastConfiguration {
        var preset: String?
        var command: String?
        var url: String?
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
            packages: contentPackages
        )
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
    case package(String)

    static func parse(_ name: String, lineNumber: Int) throws -> Section {
        if name == "server" {
            return .server
        }

        if name.hasPrefix("server.options.") {
            return .serverOptions
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
