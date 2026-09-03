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
            let postFiles = postFiles(in: files, languages: package.languages)
            let folderPath = folderURL.path().replacing(packageURL.path(), with: "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))

            posts.append(contentsOf: postFiles.map { fileURL in
                Post(
                    fileURL: fileURL,
                    packageName: package.name,
                    language: language(for: fileURL.lastPathComponent, languages: package.languages),
                    relativePath: folderPath
                )
            })
        }

        return posts
    }

    private static func postFiles(in files: [URL], languages: [String]) -> [URL] {
        if languages.isEmpty {
            return files.filter { ["index.md", "index.mdx"].contains($0.lastPathComponent) }
        }

        return files.filter { fileURL in
            languages.contains { language in
                ["index.\(language).md", "index.\(language).mdx"].contains(fileURL.lastPathComponent)
            }
        }
    }

    private static func language(for filename: String, languages: [String]) -> String? {
        languages.first { language in
            ["index.\(language).md", "index.\(language).mdx"].contains(filename)
        }
    }
}
