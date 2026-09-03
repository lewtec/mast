import Foundation

struct Post: Equatable, Hashable, Identifiable, Sendable {
    let fileURL: URL
    let packageName: String
    let language: String?
    let relativePath: String

    var id: URL { fileURL }

    var title: String {
        relativePath.split(separator: "/").last.map(String.init) ?? fileURL.deletingLastPathComponent().lastPathComponent
    }
}
