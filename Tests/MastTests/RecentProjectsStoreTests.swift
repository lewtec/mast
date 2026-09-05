import Foundation
import Testing
@testable import Mast

@MainActor
struct RecentProjectsStoreTests {
    @Test
    func recordsMostRecentFirstAndMovesDuplicates() {
        let (store, cleanup) = makeStore()
        defer { cleanup() }

        let blog = URL(filePath: "/Users/test/blog")
        let docs = URL(filePath: "/Users/test/docs")
        let older = Date(timeIntervalSince1970: 1_000)
        let newer = Date(timeIntervalSince1970: 2_000)

        store.record(blog, at: older)
        store.record(docs, at: older)
        store.record(blog, at: newer)

        #expect(store.projects.map(\.path) == [
            RecentProject.normalizedPath(for: blog),
            RecentProject.normalizedPath(for: docs),
        ])
        #expect(store.projects.first?.openedAt == newer)
    }

    @Test
    func dropsOldestProjectsPastTheLimit() {
        let (store, cleanup) = makeStore()
        defer { cleanup() }

        for index in 0...RecentProjectsStore.limit {
            store.record(
                URL(filePath: "/Users/test/project-\(index)"),
                at: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }

        #expect(store.projects.count == RecentProjectsStore.limit)
        #expect(store.projects.first?.name == "project-\(RecentProjectsStore.limit)")
        #expect(store.projects.contains(where: { $0.name == "project-0" }) == false)
    }

    @Test
    func removesAProjectAndClearsTheList() throws {
        let (store, cleanup) = makeStore()
        defer { cleanup() }

        let blog = URL(filePath: "/Users/test/blog")
        let docs = URL(filePath: "/Users/test/docs")
        store.record(blog)
        store.record(docs)

        store.remove(try #require(store.projects.first { $0.name == "blog" }))
        #expect(store.projects.map(\.name) == ["docs"])

        store.remove(docs)
        #expect(store.projects.isEmpty)

        store.record(blog)
        store.record(docs)
        store.removeAll()
        #expect(store.projects.isEmpty)
    }

    @Test
    func reloadsPersistedProjects() throws {
        let suite = "mast.tests.recents.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let blog = URL(filePath: "/Users/test/blog")
        let openedAt = Date(timeIntervalSince1970: 1_700_000_000)
        RecentProjectsStore(defaults: defaults).record(blog, at: openedAt)

        let reloaded = RecentProjectsStore(defaults: defaults)
        #expect(reloaded.projects == [
            RecentProject(path: RecentProject.normalizedPath(for: blog), openedAt: openedAt)
        ])
    }

    @Test
    func treatsEquivalentFileURLsAsTheSameProject() {
        let (store, cleanup) = makeStore()
        defer { cleanup() }

        store.record(URL(filePath: "/Users/test/blog/"))
        store.record(URL(filePath: "/Users/test/blog/."))

        #expect(store.projects.count == 1)
        #expect(store.projects.first?.name == "blog")
    }

    @Test
    func abbreviatesTheHomeDirectoryInDisplayPaths() {
        let home = RecentProject.normalizedPath(for: .homeDirectory)

        #expect(RecentProject(path: home, openedAt: .now).displayPath == "~")
        #expect(RecentProject(path: home + "/src/blog", openedAt: .now).displayPath == "~/src/blog")
        #expect(RecentProject(path: "/opt/sites/blog", openedAt: .now).displayPath == "/opt/sites/blog")
    }

    @Test
    func removesAStoredPathEvenWhenAURLWouldRenormalizeIt() throws {
        let suite = "mast.tests.recents.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let openedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let stored = RecentProject(path: "/private/tmp/old-blog", openedAt: openedAt)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        defaults.set(try encoder.encode([stored]), forKey: "recentProjects")

        let store = RecentProjectsStore(defaults: defaults)
        try #require(store.projects == [stored])

        store.remove(store.projects[0])
        #expect(store.projects.isEmpty)
    }
}

@MainActor
private func makeStore() -> (RecentProjectsStore, () -> Void) {
    let suite = "mast.tests.recents.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return (RecentProjectsStore(defaults: defaults), {
        defaults.removePersistentDomain(forName: suite)
    })
}
