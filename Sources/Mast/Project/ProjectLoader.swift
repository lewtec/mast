import Foundation

enum ProjectLoader {
    static func load(at rootURL: URL) throws -> Project {
        let configurationURL = rootURL.appending(path: "mast.toml")
        guard FileManager.default.fileExists(atPath: configurationURL.path()) else {
            throw MastConfigurationError.missingConfiguration
        }

        let source = try String(contentsOf: configurationURL, encoding: .utf8)
        let configuration = try MastConfigurationParser.parse(source)
        let posts = try configuration.packages.flatMap { package in
            try loadPosts(in: package, rootURL: rootURL)
        }

        return Project(rootURL: rootURL, configuration: configuration, posts: posts.sorted { $0.relativePath < $1.relativePath })
    }

    private static func loadPosts(in package: ContentPackage, rootURL: URL) throws -> [Post] {
        let packageURL = rootURL.appending(path: package.path)
        guard FileManager.default.fileExists(atPath: packageURL.path()) else {
            return []
        }

        let enumerator = FileManager.default.enumerator(
            at: packageURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var posts: [Post] = []
        while let folderURL = enumerator?.nextObject() as? URL {
            let resourceValues = try folderURL.resourceValues(forKeys: [.isDirectoryKey])
            guard resourceValues.isDirectory == true else { continue }

            let files = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            let documents = documents(in: files, languages: package.languages)
            guard !documents.isEmpty else { continue }

            let folderPath = relativePath(of: folderURL, inside: packageURL)
            posts.append(Post(packageName: package.name, relativePath: folderPath, documents: documents))
        }

        return posts
    }

    private static func documents(in files: [URL], languages: [String]) -> [PostDocument] {
        PostFile.indexFiles(in: files, languages: languages)
            .map { fileURL in
                PostDocument(
                    fileURL: fileURL,
                    language: PostFile.language(from: fileURL.lastPathComponent, languages: languages)
                )
            }
            .sorted { lhs, rhs in
                languageOrder(lhs.language, in: languages) < languageOrder(rhs.language, in: languages)
            }
    }

    private static func languageOrder(_ language: String?, in languages: [String]) -> Int {
        language.flatMap { languages.firstIndex(of: $0) } ?? languages.count
    }

    private static func relativePath(of url: URL, inside rootURL: URL) -> String {
        let rootPath = rootURL.resolvingSymlinksInPath().path()
        let urlPath = url.resolvingSymlinksInPath().path()
        guard urlPath.hasPrefix(rootPath) else { return url.lastPathComponent }
        return String(urlPath.dropFirst(rootPath.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}
