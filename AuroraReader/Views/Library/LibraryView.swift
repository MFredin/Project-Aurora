import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @State private var viewModel = LibraryViewModel()
    @State private var showFileImporter = false
    @State private var selectedBook: Book?
    @State private var isGridView = true

    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty && !viewModel.isLoading {
                    emptyLibraryView
                } else {
                    bookListContent
                }
            }
            .navigationTitle("Library")
            .toolbar { toolbarContent }
            .searchable(text: $viewModel.searchText, prompt: "Search books")
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: BookImportService.supportedContentTypes,
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.showError = false }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .overlay {
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .fullScreenCover(item: $selectedBook) { book in
                ReaderView(book: book)
            }
        }
    }

    // MARK: - Subviews

    private var emptyLibraryView: some View {
        ContentUnavailableView {
            Label("No Books Yet", systemImage: "book.closed")
        } description: {
            Text("Import EPUB, PDF, or text files to start reading.")
        } actions: {
            Button(action: { showFileImporter = true }) {
                Label("Import Books", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var bookListContent: some View {
        let filtered = viewModel.filteredAndSortedBooks(books)

        return ScrollView {
            if isGridView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                    ForEach(filtered) { book in
                        BookGridCell(book: book)
                            .onTapGesture { selectedBook = book }
                            .contextMenu { bookContextMenu(for: book) }
                    }
                }
                .padding()
            } else {
                LazyVStack(spacing: 2) {
                    ForEach(filtered) { book in
                        BookListRow(book: book)
                            .onTapGesture { selectedBook = book }
                            .contextMenu { bookContextMenu(for: book) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func bookContextMenu(for book: Book) -> some View {
        Button(role: .destructive) {
            viewModel.deleteBook(book, modelContext: modelContext)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            ProgressView("Importing...")
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { showFileImporter = true }) {
                Image(systemName: "plus")
            }
        }

        ToolbarItem(placement: .secondaryAction) {
            Menu {
                Picker("Sort By", selection: $viewModel.sortOrder) {
                    ForEach(LibraryViewModel.SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }

                Divider()

                Button {
                    isGridView.toggle()
                } label: {
                    Label(
                        isGridView ? "List View" : "Grid View",
                        systemImage: isGridView ? "list.bullet" : "square.grid.2x2"
                    )
                }

                Divider()

                Menu("Filter by Format") {
                    Button("All Formats") { viewModel.selectedFormat = nil }
                    ForEach(BookFormat.allCases, id: \.self) { format in
                        Button(format.displayName) { viewModel.selectedFormat = format }
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - File Import

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                Task {
                    await viewModel.importBook(from: url, modelContext: modelContext)
                }
            }
        case .failure(let error):
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [Book.self, ReadingProgress.self, Bookmark.self, UserPreferences.self], inMemory: true)
}
