import Foundation

enum MarkdownContentDiscovery {
    static func discover(at rootURL: URL) -> MarkdownDiscoveryResult {
        let excludedFolders: Set<String> = [".git", ".build", "build", "node_modules"]
        let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        let rootPath = rootURL.resolvingSymlinksInPath().path()

        var folders: Set<String> = []
        var hasRootMarkdown = false
        while let fileURL = enumerator?.nextObject() as? URL {
            guard isPostIndex(fileURL) else { continue }
            let filePath = fileURL.resolvingSymlinksInPath().path()
            let relativePath = filePath.replacing(rootPath, with: "")
            let components = relativePath.split(separator: "/").map(String.init)
            let folderComponents = components.dropLast()
            guard let firstFolder = folderComponents.first, !excludedFolders.contains(firstFolder) else {
                hasRootMarkdown = true
                continue
            }

            guard folderComponents.count > 1 else { continue }
            folders.insert(folderComponents.dropLast().joined(separator: "/"))
        }

        return MarkdownDiscoveryResult(
            packages: folders.sorted().map { folder in
                SetupPackage(name: folder.split(separator: "/").last.map(String.init) ?? folder, path: folder, route: "/{path}")
            },
            hasRootMarkdown: hasRootMarkdown
        )
    }

    private static func isPostIndex(_ fileURL: URL) -> Bool {
        guard ["md", "mdx"].contains(fileURL.pathExtension) else { return false }
        let stem = fileURL.deletingPathExtension().lastPathComponent
        return stem == "index" || stem.hasPrefix("index.")
    }
}
