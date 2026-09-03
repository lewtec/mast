import SwiftUI

struct PostListView: View {
    let posts: [Post]
    @Binding var selection: Post?
    let configureProject: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Posts")
                    .font(.headline)
                Spacer()
                Text(displayPosts.count, format: .number)
                    .foregroundStyle(.secondary)
                Button("Configure project", systemImage: "slider.horizontal.3", action: configureProject)
                    .labelStyle(.iconOnly)
            }
            .padding()

            List(displayPosts, selection: listSelection) { post in
                VStack(alignment: .leading) {
                    Text(post.title)
                    Text(languages(for: post).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(post)
            }
        }
        .frame(maxHeight: .infinity)
    }

    var displayPosts: [Post] {
        return posts.reduce(into: [Post]()) { result, post in
            guard !result.contains(where: {
                $0.packageName == post.packageName && $0.relativePath == post.relativePath
            }) else { return }
            result.append(post)
        }
    }

    func languages(for post: Post) -> [String] {
        posts
            .filter { $0.packageName == post.packageName && $0.relativePath == post.relativePath }
            .map { $0.language ?? "Default" }
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
