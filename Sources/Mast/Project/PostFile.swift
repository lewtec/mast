import Foundation

enum PostFile {
    static let markdownExtensions: Set<String> = ["md", "mdx"]

    static func isIndex(_ url: URL) -> Bool {
        guard markdownExtensions.contains(url.pathExtension) else { return false }
        let stem = url.deletingPathExtension().lastPathComponent
        return stem == "index" || stem.hasPrefix("index.")
    }

    static func language(from url: URL) -> String? {
        let stem = url.deletingPathExtension().lastPathComponent
        guard stem.hasPrefix("index.") else { return nil }
        return String(stem.dropFirst("index.".count))
    }

    static func language(from filename: String, languages: [String]) -> String? {
        languages.first { language in
            ["index.\(language).md", "index.\(language).mdx"].contains(filename)
        }
    }

    static func filename(language: String?, pathExtension: String = "md") -> String {
        if let language {
            return "index.\(language).\(pathExtension)"
        }
        return "index.\(pathExtension)"
    }

    static func indexFiles(in files: [URL], languages: [String]) -> [URL] {
        if languages.isEmpty {
            return files.filter { ["index.md", "index.mdx"].contains($0.lastPathComponent) }
        }

        return files.filter { fileURL in
            languages.contains { language in
                ["index.\(language).md", "index.\(language).mdx"].contains(fileURL.lastPathComponent)
            }
        }
    }
}
