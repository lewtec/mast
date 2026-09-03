import Foundation

enum MastConfigurationError: LocalizedError, Equatable {
    case missingConfiguration
    case malformedLine(Int)
    case invalidSection(Int)
    case missingServerValue(String)
    case missingPackageValue(String, String)
    case noContentPackages

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            "Mast could not find mast.toml in this folder."
        case .malformedLine(let line):
            "mast.toml has an invalid setting on line \(line)."
        case .invalidSection(let line):
            "mast.toml has an invalid section on line \(line)."
        case .missingServerValue(let value):
            "mast.toml needs server.\(value)."
        case .missingPackageValue(let package, let value):
            "mast.toml needs content.packages.\(package).\(value)."
        case .noContentPackages:
            "mast.toml needs at least one content package."
        }
    }
}
