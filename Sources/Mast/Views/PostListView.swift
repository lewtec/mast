import SwiftUI

struct PostListView: View {
    let posts: [Post]
    @Binding var selection: Post?

    var body: some View {
        List(posts, selection: $selection) { post in
            VStack(alignment: .leading) {
                Text(post.title)
                Text(post.packageName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .tag(post)
        }
        .navigationTitle("Posts")
    }
}
