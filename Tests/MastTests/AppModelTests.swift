import Foundation
import Testing
@testable import Mast

@MainActor
struct AppModelTests {
    @Test
    func openingAMissingRecentRemovesIt() {
        let suite = "mast.tests.appmodel.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let missing = URL(filePath: "/opt/sites/missing-\(UUID().uuidString)")
        let store = RecentProjectsStore(defaults: defaults)
        store.record(missing)

        let model = AppModel(recents: store)
        model.openProject(at: missing)

        #expect(model.project == nil)
        #expect(model.recentProjects.isEmpty)
        #expect(model.isShowingError)
        #expect(model.errorMessage == "Mast could not find \(missing.lastPathComponent).")
    }

    @Test
    func removingRecentsUpdatesThePublishedList() {
        let suite = "mast.tests.appmodel.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let blog = URL(filePath: "/opt/sites/blog")
        let docs = URL(filePath: "/opt/sites/docs")
        let store = RecentProjectsStore(defaults: defaults)
        store.record(blog)
        store.record(docs)

        let model = AppModel(recents: store)
        #expect(model.recentProjects.map(\.name) == ["docs", "blog"])

        model.removeRecent(blog)
        #expect(model.recentProjects.map(\.name) == ["docs"])

        model.removeRecent(docs)
        #expect(model.recentProjects.isEmpty)
    }
}
