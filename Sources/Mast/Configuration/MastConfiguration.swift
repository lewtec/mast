import Foundation

struct MastConfiguration: Equatable, Sendable {
    let server: ServerConfiguration
    let packages: [ContentPackage]
    let autosaveDelayMilliseconds: Int
    let serverOptionsSource: String

    init(
        server: ServerConfiguration,
        packages: [ContentPackage],
        autosaveDelayMilliseconds: Int = 1_000,
        serverOptionsSource: String = ""
    ) {
        self.server = server
        self.packages = packages
        self.autosaveDelayMilliseconds = autosaveDelayMilliseconds
        self.serverOptionsSource = serverOptionsSource
    }
}
