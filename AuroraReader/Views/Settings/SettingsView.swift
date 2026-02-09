import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @Query private var books: [Book]

    private var currentPreferences: UserPreferences {
        if let existing = preferences.first {
            return existing
        }
        let prefs = UserPreferences()
        modelContext.insert(prefs)
        try? modelContext.save()
        return prefs
    }

    var body: some View {
        NavigationStack {
            Form {
                // Library Stats
                Section("Library") {
                    LabeledContent("Total Books", value: "\(books.count)")
                    LabeledContent("EPUB", value: "\(books.filter { $0.bookFormat == .epub }.count)")
                    LabeledContent("PDF", value: "\(books.filter { $0.bookFormat == .pdf }.count)")
                    LabeledContent("Plain Text", value: "\(books.filter { $0.bookFormat == .plainText }.count)")
                }

                // Default Reader Settings
                Section("Default Reader Settings") {
                    NavigationLink {
                        ReaderSettingsSheet(preferences: currentPreferences)
                    } label: {
                        LabeledContent("Font", value: currentPreferences.fontFamily)
                    }

                    LabeledContent("Font Size", value: "\(Int(currentPreferences.fontSizeRaw))pt")
                    LabeledContent("Theme", value: currentPreferences.theme.displayName)
                }

                // Supported Formats
                Section("Supported Formats") {
                    ForEach(BookFormat.allCases, id: \.self) { format in
                        HStack {
                            Image(systemName: iconForFormat(format))
                                .foregroundStyle(.accentColor)
                                .frame(width: 24)
                            Text(format.displayName)
                            Spacer()
                            Text(".\(format.fileExtension)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }

                // About
                Section("About") {
                    LabeledContent("App", value: "Aurora Reader")
                    LabeledContent("Version", value: "1.0.0")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func iconForFormat(_ format: BookFormat) -> String {
        switch format {
        case .epub: return "book.fill"
        case .pdf: return "doc.richtext"
        case .plainText: return "doc.plaintext"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Book.self, ReadingProgress.self, Bookmark.self, UserPreferences.self], inMemory: true)
}
