import Foundation

struct Project: Equatable, Sendable {
    let rootURL: URL
    let configuration: MastConfiguration
    let posts: [Post]

    func previewURL(for post: Post?, from serverURL: URL) -> URL {
        guard
            let post,
            let package = configuration.packages.first(where: { $0.name == post.packageName })
        else {
            return serverURL
        }

        let language = post.language ?? package.languages.first ?? ""
        let route = package.route
            .replacing("{lang}", with: language)
            .replacing("{path}", with: post.relativePath)

        var components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false)
        components?.path = route
        return components?.url ?? serverURL
    }
}
