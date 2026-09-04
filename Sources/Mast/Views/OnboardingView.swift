import SwiftUI

struct OnboardingView: View {
    let rootURL: URL
    let complete: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var preset: String
    @State private var command: String
    @State private var url: String
    @State private var autosaveDelayMilliseconds: Int
    @State private var packages: [SetupPackage]
    @State private var errorMessage: String?
    private let hasRootMarkdown: Bool
    private let serverOptionsSource: String
    private let isEditing: Bool

    init(
        rootURL: URL,
        complete: @escaping (URL) -> Void,
        configuration: MastConfiguration? = nil
    ) {
        let defaults = configuration.map {
            OnboardingDefaults(preset: $0.server.preset, command: $0.server.command, url: $0.server.url)
        } ?? OnboardingDefaults.detect(at: rootURL)
        self.rootURL = rootURL
        self.complete = complete
        _preset = State(initialValue: defaults.preset)
        _command = State(initialValue: defaults.command)
        _url = State(initialValue: defaults.url)
        _autosaveDelayMilliseconds = State(initialValue: configuration?.autosaveDelayMilliseconds ?? 1_000)
        let discovery = MarkdownContentDiscovery.discover(at: rootURL)
        _packages = State(initialValue: configuration.map { configuration in
            configuration.packages.map { package in
                SetupPackage(name: package.name, path: package.path, route: package.route, languages: package.languages)
            }
        } ?? discovery.packages)
        hasRootMarkdown = discovery.hasRootMarkdown
        serverOptionsSource = configuration?.serverOptionsSource ?? ""
        isEditing = configuration != nil
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

            Section("Editor") {
                Stepper(value: $autosaveDelayMilliseconds, in: 250...10_000, step: 250) {
                    LabeledContent("Autosave delay", value: "\(autosaveDelayMilliseconds) ms")
                }
            }

            Section("Content") {
                if hasRootMarkdown {
                    Text("Markdown at the project root cannot keep images beside each post. Put each post in its own folder before you create the configuration.")
                        .foregroundStyle(.secondary)
                }
                ForEach($packages) { $package in
                    VStack(alignment: .leading) {
                        TextField("Package name", text: $package.name)
                        TextField("Content folder", text: $package.path)
                        TextField("Post route", text: $package.route)
                        Button("Remove package", systemImage: "minus.circle", action: { removePackage(package.id) })
                            .labelStyle(.iconOnly)
                    }
                }
                Button("Add content folder", systemImage: "plus", action: addPackage)
            }
        }
        .formStyle(.grouped)
        .frame(width: 560)
        .padding()
        .navigationTitle(isEditing ? "Configure Mast" : "Set up Mast")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: dismiss.callAsFunction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save configuration" : "Create project", action: createConfiguration)
                    .disabled(command.isEmpty || url.isEmpty || packages.isEmpty || packages.contains { $0.name.isEmpty || $0.path.isEmpty || $0.route.isEmpty })
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
                MastConfiguration(
                    server: ServerConfiguration(preset: preset, command: command, url: url),
                    packages: packages.map {
                        ContentPackage(name: $0.name, path: $0.path, route: $0.route, languages: $0.languages)
                    },
                    autosaveDelayMilliseconds: autosaveDelayMilliseconds,
                    serverOptionsSource: serverOptionsSource
                ),
                to: rootURL
            )
            complete(rootURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addPackage() {
        packages.append(SetupPackage(name: "", path: "", route: ""))
    }

    private func removePackage(_ id: SetupPackage.ID) {
        packages.removeAll { $0.id == id }
    }
}
