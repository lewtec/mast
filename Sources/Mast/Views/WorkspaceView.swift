import SwiftUI

struct WorkspaceView: View {
    @Bindable var model: AppModel
    let project: Project
    @State private var isShowingConfiguration = false
    @State private var isShowingProjectSetup = false
    @State private var isShowingNewPost = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            PostListView(posts: project.posts, selection: $model.selectedPost)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } content: {
            EditorView(text: $model.editorText, post: model.selectedPost, save: model.scheduleSave)
                .frame(minWidth: 360, maxWidth: .infinity, maxHeight: .infinity)
        } detail: {
            Group {
                if let previewURL = model.previewURL {
                    PreviewWebView(url: previewURL)
                } else {
                    PreviewPlaceholderView(urlTemplate: project.configuration.server.url)
                }
            }
            .frame(minWidth: 300, idealWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: model.selectedPost) { _, post in
            model.selectPost(post)
        }
        .toolbar {
            ToolbarItemGroup {
                ServerStatusIndicator(status: model.serverStatus, message: model.serverMessage)
                Button("New post", systemImage: "plus", action: showNewPost)
                Button("Configure project", systemImage: "slider.horizontal.3", action: showProjectSetup)
                Button("Edit mast.toml", systemImage: "doc.text", action: showConfiguration)
            }
        }
        .sheet(isPresented: $isShowingProjectSetup) {
            NavigationStack {
                OnboardingView(
                    rootURL: project.rootURL,
                    complete: model.finishSetup,
                    configuration: project.configuration,
                    serverOptionsSource: MastConfigurationWriter.serverOptionsSource(from: model.configurationSource)
                )
            }
        }
        .sheet(isPresented: $isShowingConfiguration) {
            ConfigurationEditorView(source: $model.configurationSource, save: model.saveConfiguration)
        }
        .sheet(isPresented: $isShowingNewPost) {
            NewPostView(packages: project.configuration.packages, create: model.createPost)
        }
    }

    private func showNewPost() {
        isShowingNewPost = true
    }

    private func showConfiguration() {
        isShowingConfiguration = true
    }

    private func showProjectSetup() {
        isShowingProjectSetup = true
    }

}
