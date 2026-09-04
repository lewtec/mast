import SwiftUI

struct WorkspaceView: View {
    @Bindable var model: AppModel
    let project: Project
    @State private var isPostsVisible = true

    var body: some View {
        @Bindable var openDocument = model.openDocument

        NativeWorkspaceSplitView(
            isSidebarVisible: $isPostsVisible,
            isInspectorVisible: $model.isPreviewVisible,
            sidebar: PostListView(
                posts: project.posts,
                selection: $model.selectedPost,
                configureProject: { model.isShowingProjectSetup = true }
            ),
            content: EditorView(
                text: $openDocument.text,
                post: model.selectedPost,
                document: model.openDocument.document,
                project: project,
                save: model.scheduleSave
            ),
            inspector: PreviewPaneView(
                url: model.previewURL,
                address: model.previewURL?.absoluteString ?? model.server.address,
                status: model.server.status,
                message: model.server.message,
                command: model.server.command,
                output: model.server.output,
                onNavigate: model.previewNavigated
            )
        )
        .navigationTitle("Mast")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: model.selectedPost) { _, post in
            model.selectedPostChanged(to: post)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 12) {
                    Button("Toggle posts sidebar", systemImage: "sidebar.left") {
                        isPostsVisible.toggle()
                    }
                    ServerStatusIndicator(status: model.server.status, message: model.server.message)
                    Button("Restart server", systemImage: "arrow.clockwise") {
                        model.restartServer()
                    }
                    Button("New post", systemImage: "plus") {
                        model.isShowingNewPost = true
                    }
                        .labelStyle(.iconOnly)
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                if let post = model.selectedPost, post.documents.count > 1 {
                    Picker("Language", selection: $model.selectedDocument) {
                        ForEach(post.documents) { document in
                            Text(document.language ?? "Default").tag(Optional(document))
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 180)
                }

                if let post = model.selectedPost, !missingLanguages(for: post).isEmpty {
                    Menu("Add language", systemImage: "plus") {
                        ForEach(missingLanguages(for: post), id: \.self) { language in
                            Button(language) {
                                _ = model.addLanguage(language, to: post)
                            }
                        }
                    }
                }

                Button(
                    model.isPreviewVisible ? "Hide preview" : "Show preview",
                    systemImage: "sidebar.right"
                ) {
                    model.isPreviewVisible.toggle()
                }
            }
        }
        .sheet(isPresented: $model.isShowingProjectSetup) {
            NavigationStack {
                OnboardingView(
                    rootURL: project.rootURL,
                    complete: model.finishSetup,
                    configuration: project.configuration
                )
            }
        }
        .sheet(isPresented: $model.isShowingNewPost) {
            NewPostView(packages: project.configuration.packages, create: model.createPost)
        }
    }

    private func missingLanguages(for post: Post) -> [String] {
        guard let package = project.configuration.packages.first(where: { $0.name == post.packageName }) else {
            return []
        }
        return post.missingLanguages(in: package)
    }
}
