import SwiftUI

struct EditorView: View {
    @Binding var text: String
    let post: Post?
    let save: () -> Void

    var body: some View {
        Group {
            if let post {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    MarkdownTextEditor(text: $text, post: post, onTextChange: save)
                        .accessibilityLabel("Markdown editor for \(post.title)")
                        .frame(maxWidth: 860, maxHeight: .infinity)
                    Spacer(minLength: 0)
                }
            } else {
                ContentUnavailableView(
                    "Select a post",
                    systemImage: "doc.text",
                    description: Text("Choose a post from the list to start editing.")
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
