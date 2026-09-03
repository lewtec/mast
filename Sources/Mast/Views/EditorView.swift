import SwiftUI

struct EditorView: View {
    @Binding var text: String
    let post: Post?

    var body: some View {
        Group {
            if let post {
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .accessibilityLabel("Markdown editor for \(post.title)")
            } else {
                ContentUnavailableView(
                    "Select a post",
                    systemImage: "doc.text",
                    description: Text("Choose a post from the list to start editing.")
                )
            }
        }
        .padding()
    }
}
