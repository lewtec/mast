import AppKit
import SwiftUI

struct CommandPaletteView: View {
    let project: Project?
    let recentProjects: [RecentProject]
    let serverStatus: ServerStatus
    let isPreviewVisible: Bool
    let onCancel: () -> Void
    let onRun: (CommandPalette.Item) -> Void

    @State private var query = ""
    @State private var selectedID: String?
    @FocusState private var isSearchFocused: Bool
    @State private var keyMonitor: Any?

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 0) {
                TextField("Search posts and commands", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isSearchFocused)
                    .padding(14)
                    .onSubmit(runSelected)

                Divider()

                CommandPaletteList(items: items, selectedID: selectedID, onRun: onRun)
            }
            .frame(width: 520)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.separator, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.2), radius: 24, y: 8)
        }
        .onAppear {
            selectedID = items.first?.id
            isSearchFocused = true
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                handleKey(event) ? nil : event
            }
        }
        .onDisappear {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
            }
            keyMonitor = nil
        }
        .onChange(of: query) {
            selectedID = items.first?.id
        }
    }

    private var items: [CommandPalette.Item] {
        CommandPalette.items(
            project: project,
            recentProjects: recentProjects,
            serverStatus: serverStatus,
            isPreviewVisible: isPreviewVisible,
            query: query
        )
    }

    private func runSelected() {
        guard let selectedID, let item = items.first(where: { $0.id == selectedID }) else { return }
        onRun(item)
    }

    private func moveSelection(_ delta: Int) {
        guard !items.isEmpty else { return }
        let current = items.firstIndex(where: { $0.id == selectedID }) ?? 0
        selectedID = items[(current + delta + items.count) % items.count].id
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 125:
            moveSelection(1)
            return true
        case 126:
            moveSelection(-1)
            return true
        case 36, 76:
            runSelected()
            return true
        case 53:
            onCancel()
            return true
        default:
            return false
        }
    }
}

private struct CommandPaletteList: View {
    let items: [CommandPalette.Item]
    let selectedID: String?
    let onRun: (CommandPalette.Item) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(items) { item in
                        CommandPaletteRow(
                            item: item,
                            isSelected: item.id == selectedID,
                            onRun: onRun
                        )
                        .id(item.id)
                    }
                }
            }
            .frame(maxHeight: 320)
            .onChange(of: selectedID) {
                if let selectedID {
                    proxy.scrollTo(selectedID)
                }
            }
        }
    }
}

private struct CommandPaletteRow: View {
    let item: CommandPalette.Item
    let isSelected: Bool
    let onRun: (CommandPalette.Item) -> Void

    var body: some View {
        Button {
            onRun(item)
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
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
