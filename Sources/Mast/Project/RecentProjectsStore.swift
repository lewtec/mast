import Foundation
import Observation

@MainActor
@Observable
final class RecentProjectsStore {
    static let limit = 20

    private let defaults: UserDefaults
    private let key: String
    private(set) var projects: [RecentProject]

    init(defaults: UserDefaults = .standard, key: String = "recentProjects") {
        self.defaults = defaults
        self.key = key
        self.projects = Self.load(from: defaults, key: key)
    }

    func record(_ url: URL, at date: Date = .now) {
        let path = RecentProject.normalizedPath(for: url)
        var next = projects.filter { $0.path != path }
        next.insert(RecentProject(path: path, openedAt: date), at: 0)
        if next.count > Self.limit {
            next = Array(next.prefix(Self.limit))
        }
        projects = next
        save()
    }

    func remove(_ url: URL) {
        let path = RecentProject.normalizedPath(for: url)
        projects = projects.filter { $0.path != path }
        save()
    }

    func removeAll() {
        projects = []
        save()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        defaults.set(try? encoder.encode(projects), forKey: key)
    }

    private static func load(from defaults: UserDefaults, key: String) -> [RecentProject] {
        guard let data = defaults.data(forKey: key) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([RecentProject].self, from: data)) ?? []
    }
}
