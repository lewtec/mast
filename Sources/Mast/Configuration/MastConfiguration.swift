import Foundation

struct MastConfiguration: Equatable, Sendable {
    let server: ServerConfiguration
    let packages: [ContentPackage]
    let autosaveDelayMilliseconds: Int

    init(
        server: ServerConfiguration,
        packages: [ContentPackage],
        autosaveDelayMilliseconds: Int = 1_000
    ) {
        self.server = server
        self.packages = packages
        self.autosaveDelayMilliseconds = autosaveDelayMilliseconds
    }
}
