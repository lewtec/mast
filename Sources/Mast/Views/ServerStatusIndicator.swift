import SwiftUI

struct ServerStatusIndicator: View {
    let status: ServerStatus
    let message: String

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .accessibilityLabel(status.label)
            .help("\(status.label). \(message)")
    }

    private var color: Color {
        switch status {
        case .stopped: .secondary
        case .starting: .yellow
        case .running: .green
        case .failed: .red
        }
    }
}
