import Foundation

struct PostDocument: Equatable, Hashable, Identifiable, Sendable {
    let fileURL: URL
    let language: String?

    var id: URL { fileURL }
}
