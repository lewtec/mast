import SwiftUI

struct PostEditorPaneView: View {
    let selection: Post?
    @Binding var text: String
    let save: () -> Void
    let previewVisible: Bool
    let previewURL: URL?
    let previewAddress: String?
    let serverStatus: ServerStatus
    let serverMessage: String
    let serverCommand: String?
    let serverOutput: String

    var body: some View {
        Group {
            if previewVisible {
                HSplitView {
                    EditorView(text: $text, post: selection, save: save)
                        .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)

                    PreviewPaneView(
                        url: previewURL,
                        address: previewAddress,
                        status: serverStatus,
                        message: serverMessage,
                        command: serverCommand,
                        output: serverOutput
                    )
                    .frame(minWidth: 320, idealWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.move(edge: .trailing))
                }
            } else {
                EditorView(text: $text, post: selection, save: save)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.24), value: previewVisible)
    }
}
