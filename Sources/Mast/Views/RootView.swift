import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @Bindable var model: AppModel
    @Binding var isCommandPalettePresented: Bool

    var body: some View {
        @Bindable var model = model

        Group {
            if let project = model.project {
                WorkspaceView(model: model, project: project)
            } else {
                WelcomeView(model: model)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if isCommandPalettePresented {
                CommandPaletteView(
                    project: model.project,
                    recentProjects: model.recentProjects,
                    serverStatus: model.server.status,
                    isPreviewVisible: model.isPreviewVisible,
                    onCancel: { isCommandPalettePresented = false },
                    onRun: runPaletteItem
                )
            }
        }
        .fileImporter(isPresented: $model.isProjectPickerPresented, allowedContentTypes: [.folder]) { result in
            switch result {
            case .success(let url):
                model.openProject(at: url)
            case .failure(let error):
                model.errorMessage = error.localizedDescription
                model.isShowingError = true
            }
        }
        .sheet(isPresented: $model.isShowingSetup) {
            if let rootURL = model.setupRootURL {
                NavigationStack {
                    OnboardingView(rootURL: rootURL, complete: model.finishSetup)
                }
            }
        }
        .alert("Could not open project", isPresented: $model.isShowingError) {
            Button("OK") {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private func showProjectPicker() {
        model.isProjectPickerPresented = true
    }

    private func runPaletteItem(_ item: CommandPalette.Item) {
        isCommandPalettePresented = false
        switch item.payload {
        case .post(let post):
            model.selectPost(post)
        case .recentProject(let url):
            model.openProject(at: url)
        case .action(.openProject):
            showProjectPicker()
        case .action(.startServer):
            model.startServer()
        case .action(.restartServer):
            model.restartServer()
        case .action(.stopServer):
            model.stopServer()
        case .action(.togglePreview):
            model.isPreviewVisible.toggle()
        case .action(.configureProject):
            model.isShowingProjectSetup = true
        case .action(.newPost):
            model.isShowingNewPost = true
        }
    }
}
