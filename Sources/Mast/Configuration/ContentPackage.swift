import Foundation

struct ContentPackage: Equatable, Identifiable, Sendable {
    let name: String
    let path: String
    let route: String
    let languages: [String]

    var id: String { name }
}
