import AppKit
import SwiftUI

@MainActor
struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    let document: PostDocument
    let project: Project
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
        textView.keyDownHandler = { [weak coordinator = context.coordinator] event, textView in
            coordinator?.completion.handleKey(event, in: textView) ?? false
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
        context.coordinator.completion.update(for: textView, document: document, project: project)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            context.coordinator.isApplyingHighlight = true
            textView.string = text
            context.coordinator.highlight(textView)
            context.coordinator.isApplyingHighlight = false
        }
        context.coordinator.completion.update(for: textView, document: document, project: project)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor
        var isApplyingHighlight = false
        let completion = DestinationCompletionController()

        init(parent: MarkdownTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isApplyingHighlight, let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            highlight(textView)
            parent.onTextChange()
            completion.update(for: textView, document: parent.document, project: parent.project)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isApplyingHighlight, let textView = notification.object as? NSTextView else { return }
            completion.update(for: textView, document: parent.document, project: parent.project)
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
                guard let markdown = try ImageAssetImporter.importImage(from: pasteboard, beside: parent.document.fileURL) else {
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
    var keyDownHandler: ((NSEvent, NSTextView) -> Bool)?

    override func keyDown(with event: NSEvent) {
        if keyDownHandler?(event, self) == true { return }
        super.keyDown(with: event)
    }

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
