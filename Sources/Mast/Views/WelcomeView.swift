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
            }
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
                VStack(spacing: 0) {
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

    var body: some View {
        HStack {
            Button(action: open) {
                Label {
                    VStack(alignment: .leading) {
                        Text(project.name)
                            .lineLimit(1)
                        Text(project.displayPath)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } icon: {
                    Image(systemName: "folder.fill")
                }
            }
            .buttonStyle(.plain)
            .help(project.path)
            .accessibilityLabel("Open \(project.name)")
            .accessibilityHint(project.displayPath)

            Spacer(minLength: 8)

            Button("Remove from Recents", systemImage: "minus.circle", action: remove)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
        }
    }
}
