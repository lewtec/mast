import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @State private var model = AppModel()
    @State private var isProjectPickerPresented = false

    var body: some View {
        @Bindable var model = model

        Group {
            if let project = model.project {
                WorkspaceView(model: model, project: project)
            } else {
                WelcomeView(openProject: showProjectPicker)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fileImporter(isPresented: $isProjectPickerPresented, allowedContentTypes: [.folder]) { result in
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
        isProjectPickerPresented = true
    }
}
