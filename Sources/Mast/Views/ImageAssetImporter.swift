import AppKit
import Foundation

@MainActor
enum ImageAssetImporter {
    private struct ImageAsset {
        let data: Data
        let filename: String
    }

    enum ImportError: LocalizedError {
        case couldNotReadImage
        case couldNotWriteImage

        var errorDescription: String? {
            switch self {
            case .couldNotReadImage: "Mast could not read that image."
            case .couldNotWriteImage: "Mast could not save that image beside the post."
            }
        }
    }

    static func canImport(from pasteboard: NSPasteboard) -> Bool {
        imageAsset(from: pasteboard) != nil
    }

    enum ExistingFilePolicy {
        case replace
        case keepBoth
        case cancel
    }

    static func importImage(
        from pasteboard: NSPasteboard,
        beside fileURL: URL,
        existingFile: ((String) -> ExistingFilePolicy)? = nil
    ) throws -> String? {
        guard let asset = imageAsset(from: pasteboard) else {
            throw ImportError.couldNotReadImage
        }

        guard let destination = destination(
            for: asset.filename,
            beside: fileURL,
            existingFile: existingFile ?? { filename in promptForExistingFile(named: filename) }
        ) else {
            return nil
        }

        do {
            try asset.data.write(to: destination, options: .atomic)
            return "![](./\(destination.lastPathComponent))"
        } catch {
            throw ImportError.couldNotWriteImage
        }
    }

    private static func imageAsset(from pasteboard: NSPasteboard) -> ImageAsset? {
        if let url = fileURL(from: pasteboard),
           let image = NSImage(contentsOf: url),
           let data = try? Data(contentsOf: url)
        {
            _ = image
            return ImageAsset(data: data, filename: imageFilename(from: url.lastPathComponent))
        }

        if let pngData = pasteboard.data(forType: .png) {
            return ImageAsset(data: pngData, filename: generatedFilename())
        }

        if let tiffData = pasteboard.data(forType: .tiff),
           let representation = NSBitmapImageRep(data: tiffData),
           let pngData = representation.representation(using: .png, properties: [:])
        {
            return ImageAsset(data: pngData, filename: generatedFilename())
        }

        guard let image = NSImage(pasteboard: pasteboard),
              let tiffData = image.tiffRepresentation,
              let representation = NSBitmapImageRep(data: tiffData),
              let pngData = representation.representation(using: .png, properties: [:])
        else {
            return nil
        }

        return ImageAsset(data: pngData, filename: generatedFilename())
    }

    private static func fileURL(from pasteboard: NSPasteboard) -> URL? {
        if let url = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )?.first as? URL {
            return url
        }

        guard let value = pasteboard.string(forType: .fileURL) else { return nil }
        return URL(string: value)
    }

    private static func destination(
        for filename: String,
        beside postURL: URL,
        existingFile: (String) -> ExistingFilePolicy
    ) -> URL? {
        let folder = postURL.deletingLastPathComponent()
        let initialDestination = folder.appending(path: filename)
        guard FileManager.default.fileExists(atPath: initialDestination.path()) else {
            return initialDestination
        }

        switch existingFile(filename) {
        case .replace:
            return initialDestination
        case .keepBoth:
            return nextAvailableDestination(for: initialDestination)
        case .cancel:
            return nil
        }
    }

    private static func promptForExistingFile(named filename: String) -> ExistingFilePolicy {
        let alert = NSAlert()
        alert.messageText = "An image named \(filename) already exists"
        alert.informativeText = "Choose whether to replace it or save this image with another name."
        alert.addButton(withTitle: "Replace")
        alert.addButton(withTitle: "Keep both")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return .replace
        case .alertSecondButtonReturn:
            return .keepBoth
        default:
            return .cancel
        }
    }

    private static func imageFilename(from sourceFilename: String) -> String {
        let filename = URL(fileURLWithPath: sourceFilename).lastPathComponent
        guard !filename.isEmpty else { return generatedFilename() }
        guard !URL(fileURLWithPath: filename).pathExtension.isEmpty else {
            return "\(filename).png"
        }
        return filename
    }

    private static func generatedFilename() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return "image-\(formatter.string(from: Date())).png"
    }

    private static func nextAvailableDestination(for destination: URL) -> URL {
        let folder = destination.deletingLastPathComponent()
        let extensionName = destination.pathExtension
        let basename = destination.deletingPathExtension().lastPathComponent
        var suffix = 2

        while true {
            let filename = extensionName.isEmpty
                ? "\(basename)-\(suffix)"
                : "\(basename)-\(suffix).\(extensionName)"
            let candidate = folder.appending(path: filename)
            guard !FileManager.default.fileExists(atPath: candidate.path()) else {
                suffix += 1
                continue
            }
            return candidate
        }
    }
}
