import SwiftUI

struct WorkspaceView: View {
    @Bindable var model: AppModel
    let project: Project
    @State private var isShowingConfiguration = false
    @State private var isShowingProjectSetup = false
    @State private var isShowingNewPost = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isPreviewVisible = true

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            PostListView(
                posts: project.posts,
                selection: $model.selectedPost,
                configureProject: showProjectSetup,
                editConfiguration: showConfiguration
            )
                .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } detail: {
            PostEditorPaneView(
                posts: project.posts,
                selection: $model.selectedPost,
                text: $model.editorText,
                save: model.scheduleSave,
                previewVisible: $isPreviewVisible,
                previewURL: model.previewURL,
                previewAddress: model.previewAddress,
                serverStatus: model.serverStatus,
                serverMessage: model.serverMessage
            )
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle("Mast")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: model.selectedPost) { _, post in
            model.selectPost(post)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 12) {
                    ServerStatusIndicator(status: model.serverStatus, message: model.serverMessage)
                    Button("New post", systemImage: "plus", action: showNewPost)
                        .labelStyle(.iconOnly)
                }
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
