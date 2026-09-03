import SwiftUI

struct PostEditorPaneView: View {
    let posts: [Post]
    @Binding var selection: Post?
    @Binding var text: String
    let save: () -> Void
    @Binding var previewVisible: Bool
    let previewURL: URL?
    let previewAddress: String?
    let serverStatus: ServerStatus
    let serverMessage: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if languagePosts.count > 1 {
                    Picker("Language", selection: $selection) {
                        ForEach(languagePosts) { post in
                            Text(post.language ?? "Default").tag(Optional(post))
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 180)
                }

                Spacer()

                Button(
                    previewVisible ? "Hide preview" : "Show preview",
                    systemImage: previewVisible ? "rectangle.trailinghalf.inset.filled" : "rectangle.trailinghalf.inset.filled"
                ) {
                    previewVisible.toggle()
                }
                .labelStyle(.iconOnly)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            HSplitView {
                EditorView(text: $text, post: selection, save: save)
                    .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)

                if previewVisible {
                    PreviewPaneView(
                        url: previewURL,
                        address: previewAddress,
                        status: serverStatus,
                        message: serverMessage
                    )
                    .frame(minWidth: 320, idealWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var languagePosts: [Post] {
        guard let selection else { return [] }
        return posts.filter {
            $0.packageName == selection.packageName && $0.relativePath == selection.relativePath
        }
    }
}
