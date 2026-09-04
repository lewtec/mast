import Foundation

enum PostCatalogError: LocalizedError, Equatable {
    case invalidSlug
    case postExists(String, String)
    case languageUnavailable
    case languageExists

    var errorDescription: String? {
        switch self {
        case .invalidSlug:
            "A post folder name cannot be empty or contain a slash."
        case .postExists(let slug, let package):
            "A post named \(slug) already exists in \(package)."
        case .languageUnavailable, .languageExists:
            nil
        }
    }
}

enum PostCatalog {
    static func create(
        in package: ContentPackage,
        slug: String,
        language: String?,
        project: Project
    ) throws -> URL {
        guard !slug.isEmpty, !slug.contains("/") else {
            throw PostCatalogError.invalidSlug
        }

        let postURL = project.rootURL.appending(path: package.path).appending(path: slug)
        let fileURL = postURL.appending(path: PostFile.filename(language: language))
        guard !FileManager.default.fileExists(atPath: postURL.path()) else {
            throw PostCatalogError.postExists(slug, package.name)
        }

        try FileManager.default.createDirectory(at: postURL, withIntermediateDirectories: true)
        try "".write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    static func addLanguage(_ language: String, to post: Post, in project: Project) throws -> URL {
        guard let package = project.configuration.packages.first(where: { $0.name == post.packageName }),
              package.languages.contains(language)
        else {
            throw PostCatalogError.languageUnavailable
        }
        guard let template = post.defaultDocument else {
            throw PostCatalogError.languageUnavailable
        }

        let fileURL = template.fileURL.deletingLastPathComponent().appending(
            path: PostFile.filename(language: language, pathExtension: template.fileURL.pathExtension)
        )
        guard !FileManager.default.fileExists(atPath: fileURL.path()) else {
            throw PostCatalogError.languageExists
        }

        try "".write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
