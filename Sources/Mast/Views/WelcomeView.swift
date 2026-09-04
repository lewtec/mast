import AppKit
import SwiftUI

struct WelcomeView: View {
    let recents: [RecentProject]
    let openProject: () -> Void
    let openRecent: (RecentProject) -> Void
    let removeRecent: (RecentProject) -> Void

    var body: some View {
        if recents.isEmpty {
            WelcomeEmptyView(openProject: openProject)
        } else {
            WelcomeRecentsView(
                recents: recents,
                openProject: openProject,
                openRecent: openRecent,
                removeRecent: removeRecent
            )
        }
    }
}

private struct WelcomeEmptyView: View {
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

private struct WelcomeRecentsView: View {
    let recents: [RecentProject]
    let openProject: () -> Void
    let openRecent: (RecentProject) -> Void
    let removeRecent: (RecentProject) -> Void

    var body: some View {
        HStack(spacing: 0) {
            WelcomeOpenPane(openProject: openProject)
                .frame(width: 280)
                .frame(maxHeight: .infinity)

            Divider()

            WelcomeRecentsList(
                recents: recents,
                openRecent: openRecent,
                removeRecent: removeRecent
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct WelcomeOpenPane: View {
    let openProject: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text("Mast")
                .font(.largeTitle)
            Text("Open a project to edit posts beside a live preview.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open project", systemImage: "folder", action: openProject)
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct WelcomeRecentsList: View {
    let recents: [RecentProject]
    let openRecent: (RecentProject) -> Void
    let removeRecent: (RecentProject) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recents")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 24)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(recents) { project in
                        WelcomeRecentRow(
                            project: project,
                            open: { openRecent(project) },
                            remove: { removeRecent(project) }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct WelcomeRecentRow: View {
    let project: RecentProject
    let open: () -> Void
    let remove: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: open) {
                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.name)
                            .lineLimit(1)
                        Text(project.displayPath)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 12)
                    Text(project.openedAt, style: .relative)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(project.path)
            .accessibilityLabel("Open \(project.name)")
            .accessibilityHint(project.displayPath)

            Button("Remove from Recents", systemImage: "xmark.circle.fill", action: remove)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .opacity(isHovering ? 1 : 0)
                .allowsHitTesting(isHovering)
                .accessibilityHidden(!isHovering)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(isHovering ? Color.primary.opacity(0.06) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("Remove from Recents", role: .destructive, action: remove)
        }
    }
}
