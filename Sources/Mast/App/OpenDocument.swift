import Foundation
import Observation

@MainActor
@Observable
final class OpenDocument {
    private(set) var post: Post?
    private(set) var document: PostDocument?
    var text = ""

    private var saveTask: Task<Void, Never>?

    func open(document: PostDocument?, in post: Post?) throws {
        if self.document == document && self.post == post {
            return
        }

        saveTask?.cancel()
        self.post = post
        self.document = document

        guard let document else {
            text = ""
            return
        }

        text = try String(contentsOf: document.fileURL, encoding: .utf8)
    }

    func close() {
        saveTask?.cancel()
        post = nil
        document = nil
        text = ""
    }

    func scheduleSave(delayMilliseconds: Int, onError: @escaping (String) -> Void) {
        guard let document else { return }
        let text = text
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(delayMilliseconds))
            guard !Task.isCancelled else { return }
            do {
                try self?.write(text, to: document)
            } catch {
                onError("Mast could not save \(document.fileURL.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }

    func save() throws {
        guard let document else { return }
        try write(text, to: document)
    }

    private func write(_ text: String, to document: PostDocument) throws {
        try text.write(to: document.fileURL, atomically: true, encoding: .utf8)
    }
}
