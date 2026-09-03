import SwiftUI

struct PostListView: View {
    let posts: [Post]
    @Binding var selection: Post?
    let configureProject: () -> Void
    let editConfiguration: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Posts")
                    .font(.headline)
                Spacer()
                Text(displayPosts.count, format: .number)
                    .foregroundStyle(.secondary)
                Menu {
                    Button("Configure project", systemImage: "slider.horizontal.3", action: configureProject)
                    Button("Edit mast.toml", systemImage: "doc.text", action: editConfiguration)
                } label: {
                    Label("Project options", systemImage: "ellipsis")
                }
                .menuStyle(.borderlessButton)
            }
            .padding()

            List(displayPosts, selection: listSelection) { post in
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

    var displayPosts: [Post] {
        posts.reduce(into: []) { result, post in
            guard !result.contains(where: {
                $0.packageName == post.packageName && $0.relativePath == post.relativePath
            }) else { return }
            result.append(post)
        }
    }

    private var listSelection: Binding<Post?> {
        Binding(
            get: {
                guard let selection else { return nil }
                return displayPosts.first {
                    $0.packageName == selection.packageName && $0.relativePath == selection.relativePath
                }
            },
            set: { selection = $0 }
        )
    }
}
