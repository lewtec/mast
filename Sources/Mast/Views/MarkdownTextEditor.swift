import AppKit
import SwiftUI

@MainActor
struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    let post: Post
    let onTextChange: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textStorage = NSTextStorage(string: text)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(containerSize: NSSize(width: 860, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let textView = ImageMarkdownTextView(frame: NSRect(x: 0, y: 0, width: 860, height: 1_000), textContainer: textContainer)
        textView.delegate = context.coordinator
        textView.font = MarkdownHighlighter.bodyFont
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = NSView.AutoresizingMask.width
        textView.registerForDraggedTypes([.fileURL, .tiff, .png])
        textView.imageImportHandler = { [weak coordinator = context.coordinator] pasteboard, textView in
            coordinator?.importImage(from: pasteboard, into: textView) ?? false
        }

        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        scrollView.drawsBackground = false
        scrollView.documentView = textView

        context.coordinator.highlight(textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView, textView.string != text else { return }
        context.coordinator.isApplyingHighlight = true
        textView.string = text
        context.coordinator.highlight(textView)
        context.coordinator.isApplyingHighlight = false
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor
        var isApplyingHighlight = false

        init(parent: MarkdownTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isApplyingHighlight, let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            highlight(textView)
            parent.onTextChange()
        }

        func highlight(_ textView: NSTextView) {
            guard let textStorage = textView.textStorage else { return }
            isApplyingHighlight = true
            MarkdownHighlighter.apply(to: textStorage)
            isApplyingHighlight = false
        }

        func importImage(from pasteboard: NSPasteboard, into textView: NSTextView) -> Bool {
            guard ImageAssetImporter.canImport(from: pasteboard) else { return false }

            do {
                guard let markdown = try ImageAssetImporter.importImage(from: pasteboard, beside: parent.post) else {
                    return true
                }
                textView.insertText(markdown, replacementRange: textView.selectedRange())
                return true
            } catch {
                NSAlert(error: error).runModal()
                return true
            }
        }
    }
}

private final class ImageMarkdownTextView: NSTextView {
    var imageImportHandler: ((NSPasteboard, NSTextView) -> Bool)?

    override func paste(_ sender: Any?) {
        guard imageImportHandler?(NSPasteboard.general, self) != true else { return }
        super.paste(sender)
    }

    override func readSelection(from pasteboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        guard imageImportHandler?(pasteboard, self) != true else { return true }
        return super.readSelection(from: pasteboard, type: type)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if ImageAssetImporter.canImport(from: sender.draggingPasteboard) {
            return .copy
        }
        return super.draggingEntered(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard imageImportHandler?(sender.draggingPasteboard, self) != true else { return true }
        return super.performDragOperation(sender)
    }
}

@MainActor
enum MarkdownHighlighter {
    static let bodyFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    private static let headingFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .bold)

    static func apply(to textStorage: NSTextStorage) {
        let text = textStorage.string
        let fullRange = NSRange(text.startIndex..., in: text)
        textStorage.beginEditing()
        textStorage.setAttributes([.font: bodyFont, .foregroundColor: NSColor.labelColor], range: fullRange)
        apply(pattern: "(?m)^#{1,6}\\s.*$", to: text, storage: textStorage, attributes: [
            .font: headingFont,
            .foregroundColor: NSColor.controlAccentColor,
        ])
        apply(pattern: "(?m)^---\\s*$", to: text, storage: textStorage, attributes: [
            .foregroundColor: NSColor.systemPurple,
        ])
        apply(pattern: "(?m)^```.*$", to: text, storage: textStorage, attributes: [
            .foregroundColor: NSColor.systemGreen,
        ])
        apply(pattern: "\\*\\*[^*]+\\*\\*", to: text, storage: textStorage, attributes: [
            .font: headingFont,
        ])
        apply(pattern: "`[^`]+`", to: text, storage: textStorage, attributes: [
            .foregroundColor: NSColor.systemOrange,
        ])
        apply(pattern: "!?\\[[^]]+\\]\\([^)]*\\)", to: text, storage: textStorage, attributes: [
            .foregroundColor: NSColor.systemBlue,
        ])
        textStorage.endEditing()
    }

    private static func apply(
        pattern: String,
        to text: String,
        storage: NSTextStorage,
        attributes: [NSAttributedString.Key: Any]
    ) {
        let expression = try? NSRegularExpression(pattern: pattern)
        expression?.matches(in: text, range: NSRange(text.startIndex..., in: text)).forEach {
            storage.addAttributes(attributes, range: $0.range)
        }
    }
}
