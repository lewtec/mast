import SwiftUI

struct CompletionMenuView: View {
    let items: [MarkdownDestination.Item]
    let selectedIndex: Int
    let onChoose: (MarkdownDestination.Item) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button {
                    onChoose(item)
                } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.title)
                            .lineLimit(1)
                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(index == selectedIndex ? Color.accentColor.opacity(0.2) : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .frame(width: 280)
    }
}
