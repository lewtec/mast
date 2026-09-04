import AppKit
import SwiftUI

@MainActor
final class DestinationCompletionController {
    private let popover = NSPopover()
    private weak var textView: NSTextView?
    private var session: MarkdownDestination.Session?
    private var selectedIndex = 0

    init() {
        popover.behavior = .applicationDefined
        popover.animates = false
    }

    func update(for textView: NSTextView, document: PostDocument, project: Project) {
        guard textView.selectedRange().length == 0 else {
            dismiss()
            return
        }

        let next = MarkdownDestination.session(
            in: textView.string,
            cursor: textView.selectedRange().location,
            document: document,
            project: project
        )
        guard let next else {
            dismiss()
            return
        }

        if session?.queryRange != next.queryRange || session?.items != next.items {
            selectedIndex = 0
        }
        session = next
        selectedIndex = min(selectedIndex, next.items.count - 1)
        self.textView = textView
        show(next, from: textView)
    }

    func handleKey(_ event: NSEvent, in textView: NSTextView) -> Bool {
        guard session != nil else { return false }

        switch event.keyCode {
        case 125:
            moveSelection(1)
            return true
        case 126:
            moveSelection(-1)
            return true
        case 36, 76, 48:
            applySelection(in: textView)
            return true
        case 53:
            dismiss()
            return true
        default:
            return false
        }
    }

    func dismiss() {
        session = nil
        selectedIndex = 0
        if popover.isShown {
            popover.performClose(nil)
        }
    }

    private func moveSelection(_ delta: Int) {
        guard let session else { return }
        selectedIndex = (selectedIndex + delta + session.items.count) % session.items.count
        refreshContent()
    }

    private func applySelection(in textView: NSTextView) {
        guard let session, session.items.indices.contains(selectedIndex) else { return }
        let item = session.items[selectedIndex]
        textView.insertText(item.insertion, replacementRange: session.queryRange)
        dismiss()
    }

    private func show(_ session: MarkdownDestination.Session, from textView: NSTextView) {
        refreshContent()
        let caret = textView.selectedRange()
        let screenRect = textView.firstRect(forCharacterRange: caret, actualRange: nil)
        let viewRect = textView.convert(screenRect, from: nil)
        if popover.isShown {
            popover.positioningRect = viewRect
        } else {
            popover.show(relativeTo: viewRect, of: textView, preferredEdge: .minY)
        }
        textView.window?.makeFirstResponder(textView)
    }

    private func refreshContent() {
        guard let session else { return }
        let items = session.items
        let selectedIndex = selectedIndex
        let choose: (MarkdownDestination.Item) -> Void = { [weak self] item in
            guard let self, let textView = self.textView else { return }
            textView.insertText(item.insertion, replacementRange: session.queryRange)
            self.dismiss()
        }
        let view = CompletionMenuView(items: items, selectedIndex: selectedIndex, onChoose: choose)
        let hosting = NSHostingController(rootView: view)
        hosting.sizingOptions = [.intrinsicContentSize]
        popover.contentViewController = hosting
        popover.contentSize = hosting.view.fittingSize
    }
}
