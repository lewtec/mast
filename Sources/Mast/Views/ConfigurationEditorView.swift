import SwiftUI

struct ConfigurationEditorView: View {
    @Binding var source: String
    let save: () -> Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("mast.toml")
                .font(.headline)
            TextEditor(text: $source)
                .font(.system(.body, design: .monospaced))
                .accessibilityLabel("mast.toml configuration")
        }
        .padding()
        .frame(minWidth: 640, minHeight: 480)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: dismiss.callAsFunction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: saveAndDismiss)
            }
        }
    }

    private func saveAndDismiss() {
        if save() {
            dismiss()
        }
    }
}
