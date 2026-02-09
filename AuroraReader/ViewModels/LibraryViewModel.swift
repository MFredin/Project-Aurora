import Foundation
import SwiftUI
import SwiftData

/// View model for the Library screen
@MainActor @Observable
final class LibraryViewModel {
    var searchText: String = ""
    var sortOrder: SortOrder = .dateAdded
    var isImporting: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    var selectedFormat: BookFormat?

    enum SortOrder: String, CaseIterable {
        case dateAdded = "Date Added"
        case title = "Title"
        case author = "Author"
        case lastOpened = "Last Opened"
    }

    func filteredAndSortedBooks(_ books: [Book]) -> [Book] {
        var result = books

        // Filter by search text
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.author.lowercased().contains(query)
            }
        }

        // Filter by format
        if let format = selectedFormat {
            result = result.filter { $0.bookFormat == format }
        }

        // Sort
        switch sortOrder {
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .title:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .author:
            result.sort { $0.author.localizedCaseInsensitiveCompare($1.author) == .orderedAscending }
        case .lastOpened:
            result.sort { ($0.lastOpened ?? .distantPast) > ($1.lastOpened ?? .distantPast) }
        }

        return result
    }

    func importBook(from url: URL, modelContext: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let (fileURL, format, fileSize) = try await BookImportService.shared.importBook(from: url)

            let parsedBook = try await BookParserService.shared.parse(fileURL: fileURL)

            let book = Book(
                title: parsedBook.title,
                author: parsedBook.author,
                coverImageData: parsedBook.coverImageData,
                fileURL: fileURL,
                format: format,
                fileSize: fileSize
            )

            let progress = ReadingProgress(
                currentChapter: 0,
                currentPage: 0,
                totalPages: parsedBook.chapters.count
            )
            book.readingProgress = progress

            modelContext.insert(book)
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func deleteBook(_ book: Book, modelContext: ModelContext) {
        if let fileURL = book.fileURLValue {
            try? BookImportService.shared.deleteBook(at: fileURL)
        }
        modelContext.delete(book)
        try? modelContext.save()
    }
}
