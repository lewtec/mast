import Foundation

struct Post: Equatable, Hashable, Identifiable, Sendable {
    let packageName: String
    let relativePath: String
    let documents: [PostDocument]

    var id: String { "\(packageName)/\(relativePath)" }

    var title: String {
        relativePath.split(separator: "/").last.map(String.init) ?? relativePath
    }

    var defaultDocument: PostDocument? { documents.first }

    var languageLabels: [String] {
        documents.map { $0.language ?? "Default" }
    }

    func missingLanguages(in package: ContentPackage) -> [String] {
        let present = Set(documents.compactMap(\.language))
        return package.languages.filter { !present.contains($0) }
    }
}
