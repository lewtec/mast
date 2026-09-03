import SwiftUI

final class MastAppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        ServerProcessGroup.stopAll()
    }
}

@main
struct MastApp: App {
    @NSApplicationDelegateAdaptor(MastAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            GeometryReader { _ in
                RootView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1_280, height: 800)
    }
}
