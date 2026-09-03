import Foundation

struct Project: Equatable, Sendable {
    let rootURL: URL
    let configuration: MastConfiguration
    let posts: [Post]
}
