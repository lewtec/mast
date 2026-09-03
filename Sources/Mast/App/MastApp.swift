import SwiftUI

@main
struct MastApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1_280, height: 800)
    }
}
