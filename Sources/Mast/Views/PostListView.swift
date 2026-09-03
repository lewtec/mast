import SwiftUI

struct PostListView: View {
    let posts: [Post]
    @Binding var selection: Post?
    @Binding var showLanguagesSeparately: Bool
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
                Menu {
                    Toggle("Always show languages", isOn: $showLanguagesSeparately)
                } label: {
                    Label("Project options", systemImage: "ellipsis")
                }
                .menuStyle(.borderlessButton)
            }
            .padding()

            List(displayPosts, selection: listSelection) { post in
                VStack(alignment: .leading) {
                    Text(post.title)
                    Text([post.packageName, post.language ?? "Default"].joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(post)
            }
        }
        .frame(maxHeight: .infinity)
    }

    var displayPosts: [Post] {
        guard !showLanguagesSeparately else { return posts }
        return posts.reduce(into: [Post]()) { result, post in
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
                guard !showLanguagesSeparately else { return selection }
                return displayPosts.first {
                    $0.packageName == selection.packageName && $0.relativePath == selection.relativePath
                }
            },
            set: { selection = $0 }
        )
    }
}
