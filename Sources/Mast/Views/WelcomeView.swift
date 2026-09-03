import SwiftUI

struct WelcomeView: View {
    let openProject: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Open a Mast project", systemImage: "doc.text")
        } description: {
            Text("Choose a folder that contains mast.toml.")
        } actions: {
            Button("Open project", systemImage: "folder", action: openProject)
                .buttonStyle(.borderedProminent)
        }
    }
}
