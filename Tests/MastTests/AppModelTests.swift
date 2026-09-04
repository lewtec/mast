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
        #expect(model.recents.projects.isEmpty)
        #expect(model.isShowingError)
        #expect(model.errorMessage == "Mast could not find \(missing.lastPathComponent).")
    }
}
