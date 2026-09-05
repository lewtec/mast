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
        stripped(url.standardizedFileURL.path())
    }

    static func refersToSameLocation(_ lhs: String, _ rhs: String) -> Bool {
        if lhs == rhs {
            return true
        }
        let left = normalizedPath(for: URL(filePath: lhs))
        let right = normalizedPath(for: URL(filePath: rhs))
        if left == right {
            return true
        }
        return URL(filePath: lhs).resolvingSymlinksInPath().path()
            == URL(filePath: rhs).resolvingSymlinksInPath().path()
    }

    private static func stripped(_ path: String) -> String {
        var path = path
        if path.count > 1, path.hasSuffix("/") {
            path.removeLast()
        }
        return path
    }
}
