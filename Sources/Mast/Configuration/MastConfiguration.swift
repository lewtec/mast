import Foundation

struct MastConfiguration: Equatable, Sendable {
    let server: ServerConfiguration
    let packages: [ContentPackage]
}
