import SwiftUI

struct PreviewPaneView: View {
    let url: URL?
    let address: String?
    let status: ServerStatus
    let message: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ServerStatusIndicator(status: status, message: message)
                Text(address ?? "Preview unavailable")
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if let url {
                PreviewWebView(url: url)
            } else {
                ContentUnavailableView(
                    status == .failed ? "Preview unavailable" : "Preparing preview",
                    systemImage: status == .failed ? "exclamationmark.triangle" : "safari",
                    description: Text(message)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
