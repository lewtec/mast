import AppKit
import SwiftUI

struct NativeWorkspaceSplitView<Sidebar: View, Content: View, Inspector: View>: NSViewControllerRepresentable {
    @Binding var isSidebarVisible: Bool
    @Binding var isInspectorVisible: Bool
    let sidebar: Sidebar
    let content: Content
    let inspector: Inspector

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSViewController(context: Context) -> NSSplitViewController {
        let controller = NSSplitViewController()
        let sidebarItem = NSSplitViewItem(viewController: NSHostingController(rootView: sidebar))
        sidebarItem.minimumThickness = 220
        sidebarItem.maximumThickness = 800
        sidebarItem.preferredThicknessFraction = 0.15

        let contentItem = NSSplitViewItem(viewController: NSHostingController(rootView: content))

        let inspectorItem = NSSplitViewItem(viewController: NSHostingController(rootView: inspector))
        inspectorItem.minimumThickness = 320
        inspectorItem.maximumThickness = 800
        inspectorItem.preferredThicknessFraction = 0.22

        controller.addSplitViewItem(sidebarItem)
        controller.addSplitViewItem(contentItem)
        controller.addSplitViewItem(inspectorItem)

        context.coordinator.sidebarItem = sidebarItem
        context.coordinator.contentItem = contentItem
        context.coordinator.inspectorItem = inspectorItem
        setCollapsed(sidebarItem, collapsed: !isSidebarVisible, animated: false)
        setCollapsed(inspectorItem, collapsed: !isInspectorVisible, animated: false)
        return controller
    }

    func updateNSViewController(_ controller: NSSplitViewController, context: Context) {
        (context.coordinator.sidebarItem?.viewController as? NSHostingController<Sidebar>)?.rootView = sidebar
        (context.coordinator.contentItem?.viewController as? NSHostingController<Content>)?.rootView = content
        (context.coordinator.inspectorItem?.viewController as? NSHostingController<Inspector>)?.rootView = inspector

        if let sidebarItem = context.coordinator.sidebarItem {
            setCollapsed(sidebarItem, collapsed: !isSidebarVisible, animated: true)
        }
        if let inspectorItem = context.coordinator.inspectorItem {
            setCollapsed(inspectorItem, collapsed: !isInspectorVisible, animated: true)
        }
    }

    private func setCollapsed(_ item: NSSplitViewItem, collapsed: Bool, animated: Bool) {
        guard item.isCollapsed != collapsed else { return }
        if animated {
            item.animator().isCollapsed = collapsed
        } else {
            item.isCollapsed = collapsed
        }
    }

    final class Coordinator {
        var sidebarItem: NSSplitViewItem?
        var contentItem: NSSplitViewItem?
        var inspectorItem: NSSplitViewItem?
    }
}
