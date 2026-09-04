import AppKit

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
