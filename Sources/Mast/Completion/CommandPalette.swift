import Foundation

enum CommandPalette {
    enum Action: String, Equatable {
        case openProject
        case startServer
        case restartServer
        case stopServer
        case togglePreview
        case configureProject
        case newPost
    }

    struct Item: Equatable, Identifiable {
        enum Payload: Equatable {
            case action(Action)
            case post(Post)
            case recentProject(URL)
        }

        let id: String
        let title: String
        let subtitle: String?
        let keywords: [String]
        let payload: Payload
    }

    static func items(
        project: Project?,
        recentProjects: [RecentProject] = [],
        serverStatus: ServerStatus,
        isPreviewVisible: Bool,
        query: String
    ) -> [Item] {
        var catalog = [openProjectItem]
        catalog.append(contentsOf: recentProjectItems(recentProjects))
        if let project {
            catalog.append(contentsOf: projectActions(
                serverStatus: serverStatus,
                isPreviewVisible: isPreviewVisible
            ))
            catalog.append(contentsOf: postItems(in: project))
        }
        return FuzzySearch.ranked(
            catalog,
            query: query,
            against: { [$0.title, $0.subtitle ?? ""] + $0.keywords }
        )
    }
}

private extension CommandPalette {
    static var openProjectItem: Item {
        Item(
            id: Action.openProject.rawValue,
            title: "Open project",
            subtitle: "Folder",
            keywords: ["folder", "open"],
            payload: .action(.openProject)
        )
    }

    static func projectActions(serverStatus: ServerStatus, isPreviewVisible: Bool) -> [Item] {
        [
            Item(
                id: Action.startServer.rawValue,
                title: "Start server",
                subtitle: "Development server",
                keywords: ["start", "run"],
                payload: .action(.startServer)
            ),
            Item(
                id: Action.restartServer.rawValue,
                title: "Restart server",
                subtitle: "Development server",
                keywords: ["reload"],
                payload: .action(.restartServer)
            ),
            Item(
                id: Action.stopServer.rawValue,
                title: "Stop server",
                subtitle: serverStatus.label,
                keywords: ["halt"],
                payload: .action(.stopServer)
            ),
            Item(
                id: Action.togglePreview.rawValue,
                title: isPreviewVisible ? "Hide preview" : "Show preview",
                subtitle: "Window",
                keywords: ["preview", "pane"],
                payload: .action(.togglePreview)
            ),
            Item(
                id: Action.configureProject.rawValue,
                title: "Configure project",
                subtitle: "Settings",
                keywords: ["settings", "mast.toml"],
                payload: .action(.configureProject)
            ),
            Item(
                id: Action.newPost.rawValue,
                title: "New post",
                subtitle: "Content",
                keywords: ["create", "write"],
                payload: .action(.newPost)
            ),
        ]
    }

    static func recentProjectItems(_ projects: [RecentProject]) -> [Item] {
        projects.map { project in
            Item(
                id: "recent:\(project.path)",
                title: project.name,
                subtitle: project.displayPath,
                keywords: ["recent", "project", project.path],
                payload: .recentProject(project.url)
            )
        }
    }

    static func postItems(in project: Project) -> [Item] {
        project.posts.map { post in
            Item(
                id: "post:\(post.id)",
                title: post.title,
                subtitle: post.packageName,
                keywords: [post.relativePath, post.packageName],
                payload: .post(post)
            )
        }
    }
}
