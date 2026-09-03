import SwiftUI

struct PostListView: View {
    let posts: [Post]
    @Binding var selection: Post?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Posts")
                    .font(.headline)
                Spacer()
                Text(posts.count, format: .number)
                    .foregroundStyle(.secondary)
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
