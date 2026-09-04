import Foundation

struct RecentProject: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: String { path }
    let path: String
    let openedAt: Date

    var url: URL { URL(filePath: path) }
    var name: String { url.lastPathComponent }

    var displayPath: String {
        let home = Self.normalizedPath(for: .homeDirectory)
        if path == home {
            return "~"
        }
        if path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    static func normalizedPath(for url: URL) -> String {
        var path = url.standardizedFileURL.path()
        if path.count > 1, path.hasSuffix("/") {
            path.removeLast()
        }
        return path
    }
}
