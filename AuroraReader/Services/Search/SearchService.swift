import Foundation
import SwiftData

/// Full-text search across books and within individual books
@MainActor @Observable
final class SearchService {
    static let shared = SearchService()

    var isSearching: Bool = false
    var searchResults: [SearchResult] = []
    var recentSearches: [String] = []

    private init() {}

    // MARK: - In-Book Search

    /// Search within a single book's chapters
    func searchInBook(
        query: String,
        chapters: [BookChapter],
        bookTitle: String
    ) -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        let lowercaseQuery = query.lowercased()
        var results: [SearchResult] = []

        for chapter in chapters {
            let content = chapter.content
            let lowercaseContent = content.lowercased()
            var searchStartIndex = lowercaseContent.startIndex

            while let range = lowercaseContent.range(of: lowercaseQuery, range: searchStartIndex..<lowercaseContent.endIndex) {
                let matchStart = range.lowerBound
                let contextStart = content.index(matchStart, offsetBy: -60, limitedBy: content.startIndex) ?? content.startIndex
                let contextEnd = content.index(range.upperBound, offsetBy: 60, limitedBy: content.endIndex) ?? content.endIndex
                let contextText = String(content[contextStart..<contextEnd])

                let position = content.distance(from: content.startIndex, to: matchStart)

                results.append(SearchResult(
                    bookTitle: bookTitle,
                    chapterTitle: chapter.title,
                    chapterIndex: chapter.index,
                    matchedText: String(content[range]),
                    contextText: contextText.replacingOccurrences(of: "\n", with: " "),
                    position: position,
                    resultType: .inBook
                ))

                searchStartIndex = range.upperBound
            }
        }

        return results
    }

    // MARK: - Library-Wide Search

    /// Search across all books in the library
    func searchLibrary(
        query: String,
        books: [Book],
        modelContext: ModelContext
    ) async -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        isSearching = true
        defer { isSearching = false }

        var allResults: [SearchResult] = []
        let lowercaseQuery = query.lowercased()

        // Search metadata first (fast)
        for book in books {
            if book.title.lowercased().contains(lowercaseQuery) {
                allResults.append(SearchResult(
                    bookTitle: book.title,
                    chapterTitle: "",
                    chapterIndex: -1,
                    matchedText: book.title,
                    contextText: "by \(book.author) — \(book.bookFormat.displayName)",
                    position: 0,
                    resultType: .metadata
                ))
            }
            if book.author.lowercased().contains(lowercaseQuery) {
                allResults.append(SearchResult(
                    bookTitle: book.title,
                    chapterTitle: "",
                    chapterIndex: -1,
                    matchedText: book.author,
                    contextText: "\(book.title) — \(book.bookFormat.displayName)",
                    position: 0,
                    resultType: .author
                ))
            }
        }

        // Search book content (slower - parse each book)
        for book in books {
            guard let fileURL = book.fileURLValue else { continue }
            do {
                let parsedBook = try await BookParserService.shared.parse(fileURL: fileURL)
                let bookResults = searchInBook(
                    query: query,
                    chapters: parsedBook.chapters,
                    bookTitle: book.title
                )
                allResults.append(contentsOf: bookResults)
            } catch {
                // Skip books that fail to parse
                continue
            }
        }

        // Add to recent searches
        addRecentSearch(query)

        return allResults
    }

    // MARK: - Search Highlights/Annotations

    /// Search through all highlights and annotations
    func searchAnnotations(
        query: String,
        highlights: [Highlight]
    ) -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        let lowercaseQuery = query.lowercased()

        return highlights.compactMap { highlight in
            let matchInText = highlight.highlightedText.lowercased().contains(lowercaseQuery)
            let matchInNote = highlight.note.lowercased().contains(lowercaseQuery)
            let matchInTags = highlight.tags.contains { $0.lowercased().contains(lowercaseQuery) }

            guard matchInText || matchInNote || matchInTags else { return nil }

            return SearchResult(
                bookTitle: highlight.book?.title ?? "Unknown",
                chapterTitle: highlight.chapterTitle,
                chapterIndex: highlight.chapterIndex,
                matchedText: matchInNote ? highlight.note : highlight.highlightedText,
                contextText: highlight.textPreview,
                position: highlight.rangeStart,
                resultType: .annotation
            )
        }
    }

    // MARK: - Recent Searches

    private func addRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        recentSearches.removeAll { $0 == trimmed }
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
    }
}

// MARK: - Search Result Model

struct SearchResult: Identifiable {
    let id = UUID()
    let bookTitle: String
    let chapterTitle: String
    let chapterIndex: Int
    let matchedText: String
    let contextText: String
    let position: Int
    let resultType: ResultType

    enum ResultType: String {
        case inBook = "Content"
        case metadata = "Title"
        case author = "Author"
        case annotation = "Annotation"

        var iconName: String {
            switch self {
            case .inBook: return "text.quote"
            case .metadata: return "book.fill"
            case .author: return "person.fill"
            case .annotation: return "highlighter"
            }
        }
    }
}
