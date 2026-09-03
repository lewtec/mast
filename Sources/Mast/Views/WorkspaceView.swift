import SwiftUI

struct WorkspaceView: View {
    @Bindable var model: AppModel
    let project: Project

    var body: some View {
        HSplitView {
            PostListView(posts: project.posts, selection: $model.selectedPost)
                .frame(minWidth: 220, idealWidth: 260)

            EditorView(text: $model.editorText, post: model.selectedPost)
                .frame(minWidth: 360)

            PreviewPlaceholderView(urlTemplate: project.configuration.server.url)
                .frame(minWidth: 300, idealWidth: 400)
        }
        .onChange(of: model.selectedPost) { _, post in
            model.selectPost(post)
        }
    }
}
