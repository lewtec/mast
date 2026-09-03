import SwiftUI

struct OnboardingView: View {
    let rootURL: URL
    let complete: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var preset: String
    @State private var command: String
    @State private var url: String
    @State private var packageName = "blog"
    @State private var contentPath = "content"
    @State private var route = "/{path}"
    @State private var errorMessage: String?

    init(rootURL: URL, complete: @escaping (URL) -> Void) {
        let defaults = OnboardingDefaults.detect(at: rootURL)
        self.rootURL = rootURL
        self.complete = complete
        _preset = State(initialValue: defaults.preset)
        _command = State(initialValue: defaults.command)
        _url = State(initialValue: defaults.url)
    }

    var body: some View {
        Form {
            Section("Project") {
                LabeledContent("Folder", value: rootURL.lastPathComponent)
            }

            Section("Development server") {
                Picker("Preset", selection: $preset) {
                    Text("Vite").tag("vite")
                    Text("Hugo").tag("hugo")
                    Text("Custom").tag("custom")
                }
                TextField("Command", text: $command)
                TextField("Preview URL", text: $url)
            }

            Section("Content") {
                TextField("Package name", text: $packageName)
                TextField("Content folder", text: $contentPath)
                TextField("Post route", text: $route)
            }
        }
        .formStyle(.grouped)
        .frame(width: 560)
        .padding()
        .navigationTitle("Set up Mast")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: dismiss.callAsFunction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create project", action: createConfiguration)
                    .disabled(command.isEmpty || url.isEmpty || packageName.isEmpty || contentPath.isEmpty || route.isEmpty)
            }
        }
        .onChange(of: preset) { _, preset in
            applyDefaults(for: preset)
        }
        .alert("Could not create mast.toml", isPresented: isShowingError) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented { errorMessage = nil }
            }
        )
    }

    private func applyDefaults(for preset: String) {
        let defaults = OnboardingDefaults.forPreset(preset)
        command = defaults.command
        url = defaults.url
    }

    private func createConfiguration() {
        do {
            try MastConfigurationWriter.write(
                to: rootURL,
                preset: preset,
                command: command,
                url: url,
                packageName: packageName,
                contentPath: contentPath,
                route: route
            )
            complete(rootURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
