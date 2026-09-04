import Foundation

struct Project: Equatable, Sendable {
    let rootURL: URL
    let configuration: MastConfiguration
    let posts: [Post]

    func previewURL(for post: Post?, document: PostDocument? = nil, from serverURL: URL) -> URL {
        guard let post,
              configuration.packages.contains(where: { $0.name == post.packageName })
        else {
            return serverURL
        }
        var components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false)
        components?.path = routePath(for: post, document: document)
        return components?.url ?? serverURL
    }

    func routePath(for post: Post, document: PostDocument? = nil) -> String {
        guard let package = configuration.packages.first(where: { $0.name == post.packageName }) else {
            return "/"
        }

        let document = document ?? post.defaultDocument
        let language = document?.language ?? package.languages.first ?? ""
        return package.route
            .replacing("{lang}", with: language)
            .replacing("{path}", with: post.relativePath)
    }

    func markdownRoute(for post: Post, document: PostDocument? = nil) -> String {
        var components = URLComponents()
        components.path = routePath(for: post, document: document)
        return components.string ?? routePath(for: post, document: document)
    }

    func post(matchingPreviewURL url: URL, from serverURL: URL) -> (post: Post, document: PostDocument)? {
        let target = normalizedLocation(url)
        for post in posts {
            for document in post.documents {
                let candidate = previewURL(for: post, document: document, from: serverURL)
                if normalizedLocation(candidate) == target {
                    return (post, document)
                }
            }
        }
        return nil
    }

    func post(containing fileURL: URL) -> (post: Post, document: PostDocument)? {
        let path = fileURL.resolvingSymlinksInPath().path()
        for post in posts {
            if let document = post.documents.first(where: { $0.fileURL.resolvingSymlinksInPath().path() == path }) {
                return (post, document)
            }
        }
        return nil
    }

    private func normalizedLocation(_ url: URL) -> String {
        let host = url.host() ?? ""
        let port = url.port.map(String.init) ?? ""
        var path = url.path(percentEncoded: false)
        if path.count > 1 && path.hasSuffix("/") {
            path.removeLast()
        }
        return "\(host):\(port)\(path)"
    }
}
