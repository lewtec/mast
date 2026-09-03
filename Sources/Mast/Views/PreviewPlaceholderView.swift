import SwiftUI

struct PreviewPlaceholderView: View {
    let urlTemplate: String

    var body: some View {
        ContentUnavailableView {
            Label("Preview ready", systemImage: "safari")
        } description: {
            Text("Mast will load \(urlTemplate) after it starts the development server.")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
