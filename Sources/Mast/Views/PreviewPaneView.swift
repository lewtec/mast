import SwiftUI

struct PreviewPaneView: View {
    let url: URL?
    let address: String?
    let status: ServerStatus
    let message: String
    let command: String?
    let output: String

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
                VStack(spacing: 12) {
                    ContentUnavailableView(
                        status == .failed ? "Preview unavailable" : "Preparing preview",
                        systemImage: status == .failed ? "exclamationmark.triangle" : "safari",
                        description: Text(message)
                    )

                    if let command {
                        serverDetail("Command", value: command)
                    }

                    if !output.isEmpty {
                        serverDetail("Server output", value: output)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func serverDetail(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .lineLimit(6)
        }
        .padding(10)
        .frame(maxWidth: 460, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
