import SwiftUI

struct NewPostView: View {
    let packages: [ContentPackage]
    let create: (ContentPackage, String, String?) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var packageName: String
    @State private var slug = ""
    @State private var language = ""

    init(packages: [ContentPackage], create: @escaping (ContentPackage, String, String?) -> Bool) {
        self.packages = packages
        self.create = create
        _packageName = State(initialValue: packages.first?.name ?? "")
        _language = State(initialValue: packages.first?.languages.first ?? "")
    }

    var body: some View {
        Form {
            Picker("Package", selection: $packageName) {
                ForEach(packages) { package in
                    Text(package.name).tag(package.name)
                }
            }
            TextField("Post folder", text: $slug, prompt: Text("20260903-my-post"))

            if !selectedPackage.languages.isEmpty {
                Picker("Language", selection: $language) {
                    ForEach(selectedPackage.languages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
        .navigationTitle("New post")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: dismiss.callAsFunction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create", action: createPost)
                    .disabled(slug.isEmpty)
            }
        }
        .onChange(of: packageName) { _, _ in
            language = selectedPackage.languages.first ?? ""
        }
    }

    private var selectedPackage: ContentPackage {
        packages.first { $0.name == packageName } ?? packages[0]
    }

    private func createPost() {
        let selectedLanguage = selectedPackage.languages.isEmpty ? nil : language
        if create(selectedPackage, slug, selectedLanguage) {
            dismiss()
        }
    }
}
