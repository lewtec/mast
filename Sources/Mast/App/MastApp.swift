import SwiftUI

final class MastAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        ServerProcessGroup.stopAll()
    }

    @objc private func windowWillClose(_ notification: Notification) {
        let closing = notification.object as? NSWindow
        DispatchQueue.main.async {
            let hasOpenWindow = NSApp.windows.contains { window in
                window !== closing
                    && window.styleMask.contains(.titled)
                    && (window.isVisible || window.isMiniaturized)
            }
            if !hasOpenWindow {
                NSApp.terminate(nil)
            }
        }
    }
}

@main
struct MastApp: App {
    @NSApplicationDelegateAdaptor(MastAppDelegate.self) private var appDelegate
    @State private var model = AppModel()
    @State private var isCommandPalettePresented = false

    var body: some Scene {
        WindowGroup {
            GeometryReader { _ in
                RootView(model: model, isCommandPalettePresented: $isCommandPalettePresented)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1_280, height: 800)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open project…") {
                    model.isProjectPickerPresented = true
                }
                .keyboardShortcut("o")

                if !model.recentProjects.isEmpty {
                    Menu("Open Recent") {
                        ForEach(model.recentProjects) { project in
                            Button(project.name) {
                                model.openProject(at: project.url)
                            }
                        }
                        Divider()
                        Button("Clear Menu") {
                            model.clearRecents()
                        }
                    }
                }

                Button("Command palette") {
                    isCommandPalettePresented.toggle()
                }
                .keyboardShortcut("k")
            }
        }
    }
}
