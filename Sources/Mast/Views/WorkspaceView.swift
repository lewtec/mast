import SwiftUI

struct WorkspaceView: View {
    @Bindable var model: AppModel
    let project: Project
    @State private var isShowingConfiguration = false
    @State private var isShowingProjectSetup = false
    @State private var isShowingNewPost = false
    @State private var isPostsVisible = true
    @State private var isPreviewVisible = true
    @AppStorage("showLanguagesSeparately") private var showLanguagesSeparately = false

    var body: some View {
        NativeWorkspaceSplitView(
            isSidebarVisible: $isPostsVisible,
            isInspectorVisible: $isPreviewVisible,
            sidebar: PostListView(
                posts: project.posts,
                selection: $model.selectedPost,
                showLanguagesSeparately: $showLanguagesSeparately,
                configureProject: showProjectSetup,
                editConfiguration: showConfiguration
            ),
            content: EditorView(
                text: $model.editorText,
                post: model.selectedPost,
                save: model.scheduleSave
            ),
            inspector: PreviewPaneView(
                url: model.previewURL,
                address: model.previewAddress,
                status: model.serverStatus,
                message: model.serverMessage,
                command: model.serverCommand,
                output: model.serverOutput
            )
        )
        .navigationTitle("Mast")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: model.selectedPost) { _, post in
            model.selectPost(post)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 12) {
                    Button("Toggle posts sidebar", systemImage: "sidebar.left") {
                        isPostsVisible.toggle()
                    }
                    ServerStatusIndicator(status: model.serverStatus, message: model.serverMessage)
                    Button("New post", systemImage: "plus", action: showNewPost)
                        .labelStyle(.iconOnly)
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                if languagePosts.count > 1 {
                    Picker("Language", selection: $model.selectedPost) {
                        ForEach(languagePosts) { post in
                            Text(post.language ?? "Default").tag(Optional(post))
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 180)
                }

                if !missingLanguages.isEmpty {
                    Menu("Add language", systemImage: "plus") {
                        ForEach(missingLanguages, id: \.self) { language in
                            Button(language) {
                                guard let post = model.selectedPost else { return }
                                _ = model.addLanguage(language, to: post)
                            }
                        }
                    }
                }

                Button(
                    isPreviewVisible ? "Hide preview" : "Show preview",
                    systemImage: "sidebar.right"
                ) {
                    isPreviewVisible.toggle()
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

    private var languagePosts: [Post] {
        guard let selection = model.selectedPost else { return [] }
        return project.posts.filter {
            $0.packageName == selection.packageName && $0.relativePath == selection.relativePath
        }
    }

    private var missingLanguages: [String] {
        guard let selection = model.selectedPost,
              let package = project.configuration.packages.first(where: { $0.name == selection.packageName })
        else { return [] }
        return package.languages.filter { language in
            !languagePosts.contains { $0.language == language }
        }
    }

}
