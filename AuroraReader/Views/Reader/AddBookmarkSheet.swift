import SwiftUI

struct AddBookmarkSheet: View {
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bookmark Name")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AuroraTheme.textSecondary)

                        TextField("Bookmark name", text: $title)
                            .foregroundStyle(AuroraTheme.textPrimary)
                            .padding(12)
                            .background(AuroraTheme.surface, in: RoundedRectangle(cornerRadius: 10))
                    }

                    Text("Give this bookmark a name to find it later.")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)

                    Spacer()
                }
                .padding()
                .padding(.top, 8)
            }
            .navigationTitle("Add Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AuroraTheme.auroraTeal)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let name = title.isEmpty ? "Bookmark" : title
                        onSave(name)
                        dismiss()
                    }
                    .foregroundStyle(AuroraTheme.auroraTeal)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
