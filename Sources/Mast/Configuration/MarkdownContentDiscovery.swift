import Foundation

enum MarkdownContentDiscovery {
    static func suggestedPackages(at rootURL: URL) -> [SetupPackage] {
        let excludedFolders: Set<String> = [".git", ".build", "build", "node_modules"]
        let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        let rootPath = rootURL.resolvingSymlinksInPath().path()

        var folders: Set<String> = []
        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension == "md" else { continue }
            let filePath = fileURL.resolvingSymlinksInPath().path()
            let relativePath = filePath.replacing(rootPath, with: "")
            let components = relativePath.split(separator: "/").map(String.init)
            guard let firstFolder = components.first, !excludedFolders.contains(firstFolder) else { continue }
            folders.insert(firstFolder)
        }

        return folders.sorted().map { folder in
            SetupPackage(name: folder, path: folder, route: "/{path}")
        }
    }
}
