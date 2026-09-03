import Foundation

struct MarkdownDiscoveryResult: Equatable {
    let packages: [SetupPackage]
    let hasRootMarkdown: Bool
}
