import SwiftUI

struct WorkspaceView: View {
    @Bindable var model: AppModel
    let project: Project

    var body: some View {
        HSplitView {
            PostListView(posts: project.posts, selection: $model.selectedPost)
                .frame(minWidth: 220, idealWidth: 260)

            EditorView(text: $model.editorText, post: model.selectedPost, save: model.scheduleSave)
                .frame(minWidth: 360)

            Group {
                if let previewURL = model.previewURL {
                    PreviewWebView(url: previewURL)
                } else {
                    PreviewPlaceholderView(urlTemplate: project.configuration.server.url)
                }
            }
                .frame(minWidth: 300, idealWidth: 400)
        }
        .onChange(of: model.selectedPost) { _, post in
            model.selectPost(post)
        }
    }
}
