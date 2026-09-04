import Foundation

enum MarkdownDestination {
    struct Session: Equatable {
        enum Kind: Equatable {
            case image
            case post
        }

        let kind: Kind
        let queryRange: NSRange
        let items: [Item]
    }

    struct Item: Equatable, Identifiable {
        let id: String
        let title: String
        let subtitle: String?
        let insertion: String
        let fileURL: URL?
    }

    static func session(
        in text: String,
        cursor: Int,
        document: PostDocument,
        project: Project
    ) -> Session? {
        guard let query = destinationQuery(in: text, cursor: cursor) else { return nil }

        let items: [Item]
        switch query.kind {
        case .image:
            items = imageItems(beside: document.fileURL, query: query.filter)
        case .post:
            items = postItems(in: project, current: document, query: query.filter)
        }
        guard !items.isEmpty else { return nil }
        if items.contains(where: { $0.insertion == query.raw }) {
            return nil
        }
        return Session(kind: query.kind, queryRange: query.range, items: items)
    }

    static func replacing(_ range: NSRange, in text: String, with insertion: String) -> String {
        guard let swiftRange = Range(range, in: text) else { return text }
        return text.replacingCharacters(in: swiftRange, with: insertion)
    }
}

private extension MarkdownDestination {
    struct Query {
        let kind: Session.Kind
        let range: NSRange
        let filter: String
        let raw: String
    }

    static func destinationQuery(in text: String, cursor: Int) -> Query? {
        guard cursor >= 0, cursor <= text.utf16.count else { return nil }
        let cursorIndex = String.Index(utf16Offset: cursor, in: text)
        let prefix = text[..<cursorIndex]
        guard let openParen = prefix.lastIndex(of: "(") else { return nil }

        let destination = prefix[prefix.index(after: openParen)..<cursorIndex]
        guard !destination.contains(where: { $0 == ")" || $0 == "\n" }) else { return nil }
        guard openParen > prefix.startIndex else { return nil }

        let beforeParen = prefix.index(before: openParen)
        guard prefix[beforeParen] == "]" else { return nil }
        guard let openBracket = prefix[..<beforeParen].lastIndex(of: "[") else { return nil }

        let isImage = openBracket > prefix.startIndex && prefix[prefix.index(before: openBracket)] == "!"
        let raw = String(destination)
        let filter = isImage && raw.hasPrefix("./") ? String(raw.dropFirst(2)) : raw
        let range = NSRange(prefix.index(after: openParen)..<cursorIndex, in: text)
        return Query(kind: isImage ? .image : .post, range: range, filter: filter, raw: raw)
    }

    static func imageItems(beside fileURL: URL, query: String) -> [Item] {
        let images = PostFile.images(beside: fileURL)
        return FuzzySearch.ranked(images, query: query, against: { [$0.lastPathComponent] }).map { imageURL in
            Item(
                id: imageURL.path(),
                title: imageURL.lastPathComponent,
                subtitle: nil,
                insertion: "./\(imageURL.lastPathComponent)",
                fileURL: imageURL
            )
        }
    }

    static func postItems(in project: Project, current: PostDocument, query: String) -> [Item] {
        let currentPost = project.post(containing: current.fileURL)?.post
        let posts = project.posts.filter { $0.id != currentPost?.id }
        return FuzzySearch.ranked(posts, query: query, against: { [$0.title, $0.relativePath, $0.packageName] }).map { post in
            let document = post.documents.first { $0.language == current.language } ?? post.defaultDocument
            let path = project.markdownRoute(for: post, document: document)
            return Item(
                id: post.id,
                title: post.title,
                subtitle: post.packageName,
                insertion: path,
                fileURL: nil
            )
        }
    }
}
