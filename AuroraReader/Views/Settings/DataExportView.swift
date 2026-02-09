import SwiftUI
import SwiftData

/// View for exporting library data in various formats
struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @Query private var highlights: [Highlight]
    @Query private var bookmarks: [Bookmark]
    @Query private var sessions: [ReadingSession]
    @Query private var vocabulary: [VocabularyEntry]

    @State private var exportService = DataExportService.shared
    @State private var selectedContent: DataExportService.ExportContent = .everything
    @State private var selectedFormat: DataExportService.ExportFormat = .markdown
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var showExportSuccess = false

    var body: some View {
        ZStack {
            AuroraTheme.deepSpace.ignoresSafeArea()

            List {
                // What to export
                Section {
                    ForEach(DataExportService.ExportContent.allCases) { content in
                        Button {
                            selectedContent = content
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: content.iconName)
                                    .foregroundStyle(AuroraTheme.auroraTeal)
                                    .frame(width: 24)
                                Text(content.rawValue)
                                    .foregroundStyle(AuroraTheme.textPrimary)
                                Spacer()
                                if selectedContent == content {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AuroraTheme.auroraTeal)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Export Content").foregroundStyle(AuroraTheme.auroraTeal)
                }
                .listRowBackground(AuroraTheme.surface)

                // Format
                Section {
                    ForEach(DataExportService.ExportFormat.allCases) { format in
                        Button {
                            selectedFormat = format
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: format.iconName)
                                    .foregroundStyle(AuroraTheme.auroraPurple)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(format.rawValue)
                                        .foregroundStyle(AuroraTheme.textPrimary)
                                    Text(".\(format.fileExtension)")
                                        .font(.caption)
                                        .foregroundStyle(AuroraTheme.textTertiary)
                                }
                                Spacer()
                                if selectedFormat == format {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AuroraTheme.auroraTeal)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Format").foregroundStyle(AuroraTheme.auroraTeal)
                }
                .listRowBackground(AuroraTheme.surface)

                // Summary
                Section {
                    statRow("Books", value: "\(books.count)")
                    statRow("Highlights", value: "\(highlights.count)")
                    statRow("Bookmarks", value: "\(bookmarks.count)")
                    statRow("Reading Sessions", value: "\(sessions.count)")
                    statRow("Vocabulary Words", value: "\(vocabulary.count)")
                } header: {
                    Text("Your Data").foregroundStyle(AuroraTheme.auroraTeal)
                }
                .listRowBackground(AuroraTheme.surface)

                // Export button
                Section {
                    Button {
                        performExport()
                    } label: {
                        HStack {
                            Spacer()
                            if exportService.isExporting {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Image(systemName: "square.and.arrow.up.fill")
                            Text("Export \(selectedContent.rawValue)")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 4)
                    }
                    .disabled(exportService.isExporting)
                }
                .listRowBackground(AuroraTheme.auroraTeal)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Export Complete", isPresented: $showExportSuccess) {
            Button("Share") { showShareSheet = true }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your \(selectedContent.rawValue.lowercased()) has been exported as \(selectedFormat.rawValue).")
        }
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(AuroraTheme.textPrimary)
            Spacer()
            Text(value).foregroundStyle(AuroraTheme.auroraTeal)
        }
    }

    private func performExport() {
        exportedFileURL = exportService.exportData(
            content: selectedContent,
            format: selectedFormat,
            books: books,
            highlights: highlights,
            bookmarks: Array(books.flatMap { $0.bookmarks }),
            sessions: sessions,
            vocabulary: vocabulary
        )
        if exportedFileURL != nil {
            showExportSuccess = true
        }
    }
}

/// UIKit share sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
