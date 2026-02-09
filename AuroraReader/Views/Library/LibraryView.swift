import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @State private var viewModel = LibraryViewModel()
    @State private var coverArtService = CoverArtService.shared
    @State private var showFileImporter = false
    @State private var selectedBook: Book?
    @State private var isGridView = true

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                Group {
                    if books.isEmpty && !viewModel.isLoading {
                        emptyLibraryView
                    } else {
                        bookListContent
                    }
                }
            }
            .navigationTitle("Library")
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews

    private var emptyLibraryView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AuroraTheme.auroraTeal.opacity(0.1))
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(AuroraTheme.auroraPurple.opacity(0.08))
                    .frame(width: 160, height: 160)
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AuroraTheme.auroraTeal)
            }

            Text("No Books Yet")
                .font(.title2.weight(.bold))
                .foregroundStyle(AuroraTheme.textPrimary)

            Text("Import ebooks in any format to start reading.\nSupports EPUB, PDF, MOBI, FB2, CBZ, and more.")
                .font(.subheadline)
                .foregroundStyle(AuroraTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: { showFileImporter = true }) {
                Label("Import Books", systemImage: "plus.circle.fill")
            }
            .buttonStyle(AuroraButtonStyle())
        }
        .padding(40)
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
        if book.coverImageData == nil {
            Button {
                Task {
                    await coverArtService.fetchCover(for: book, modelContext: modelContext)
                }
            } label: {
                Label("Fetch Cover", systemImage: "photo.on.rectangle.angled")
            }
        } else {
            Button {
                Task {
                    await coverArtService.refreshCover(for: book, modelContext: modelContext)
                }
            } label: {
                Label("Refresh Cover", systemImage: "arrow.triangle.2.circlepath")
            }
        }

        Button(role: .destructive) {
            viewModel.deleteBook(book, modelContext: modelContext)
        } label: {
            Label("Delete", systemImage: "trash.circle")
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .tint(AuroraTheme.auroraTeal)
                Text("Importing...")
                    .font(.subheadline)
                    .foregroundStyle(AuroraTheme.textSecondary)
            }
            .padding(24)
            .auroraCard()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { showFileImporter = true }) {
                Image(systemName: "plus.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AuroraTheme.auroraTeal)
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

                Divider()

                Button {
                    Task {
                        await coverArtService.fetchMissingCovers(books: books, modelContext: modelContext)
                    }
                } label: {
                    Label("Fetch Missing Covers", systemImage: "photo.on.rectangle.angled")
                }
                .disabled(coverArtService.isFetching)
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AuroraTheme.auroraTeal)
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

                    // Auto-fetch cover for newly imported books missing covers
                    if let imported = books.first(where: { $0.fileURL == url.absoluteString }),
                       imported.coverImageData == nil {
                        await coverArtService.fetchCover(for: imported, modelContext: modelContext)
                    }
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
