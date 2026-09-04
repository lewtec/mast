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
                Text(posts.count, format: .number)
                    .foregroundStyle(.secondary)
                Button("Configure project", systemImage: "slider.horizontal.3", action: configureProject)
                    .labelStyle(.iconOnly)
            }
            .padding()

            List(posts, selection: $selection) { post in
                VStack(alignment: .leading) {
                    Text(post.title)
                    Text(post.languageLabels.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(post)
            }
        }
        .frame(maxHeight: .infinity)
    }
}
