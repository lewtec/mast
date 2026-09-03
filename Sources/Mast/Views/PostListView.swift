import SwiftUI

struct PostListView: View {
    let posts: [Post]
    @Binding var selection: Post?
    let serverStatus: ServerStatus
    let serverMessage: String
    let createPost: () -> Void
    let configureProject: () -> Void
    let editConfiguration: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Posts")
                    .font(.headline)
                ServerStatusIndicator(status: serverStatus, message: serverMessage)
                Spacer()
                Text(posts.count, format: .number)
                    .foregroundStyle(.secondary)
                Button("New post", systemImage: "plus", action: createPost)
                    .labelStyle(.iconOnly)
                Menu {
                    Button("Configure project", systemImage: "slider.horizontal.3", action: configureProject)
                    Button("Edit mast.toml", systemImage: "doc.text", action: editConfiguration)
                } label: {
                    Label("Project options", systemImage: "ellipsis")
                }
                .menuStyle(.borderlessButton)
            }
            .padding()

            List(posts, selection: $selection) { post in
                VStack(alignment: .leading) {
                    Text(post.title)
                    Text(post.packageName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(post)
            }
        }
        .frame(maxHeight: .infinity)
    }
}
