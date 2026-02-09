import SwiftUI

struct AddBookmarkSheet: View {
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Bookmark name", text: $title)
                } footer: {
                    Text("Give this bookmark a name to find it later.")
                }
            }
            .navigationTitle("Add Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let name = title.isEmpty ? "Bookmark" : title
                        onSave(name)
                        dismiss()
                    }
                }
            }
        }
    }
}
