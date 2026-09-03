import Foundation

struct ServerConfiguration: Equatable, Sendable {
    let preset: String
    let command: String
    let url: String
}
