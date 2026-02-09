import Foundation
import SwiftData

/// Smart import & metadata enrichment service
/// Fetches covers, descriptions, ratings from OpenLibrary and Google Books
@MainActor @Observable
final class MetadataService {
    static let shared = MetadataService()

    var isEnriching: Bool = false
    var enrichmentProgress: Double = 0

    private let openLibraryBaseURL = "https://openlibrary.org"
    private let googleBooksBaseURL = "https://www.googleapis.com/books/v1"

    private init() {}

    // MARK: - Metadata Enrichment

    /// Enriches a book with metadata from online sources
    func enrichBook(_ book: Book, modelContext: ModelContext) async {
        isEnriching = true
        defer {
            isEnriching = false
            enrichmentProgress = 0
        }

        enrichmentProgress = 0.2

        // Try by ISBN first, then by title + author
        if let isbn = book.isbn, !isbn.isEmpty {
            if let metadata = await fetchByISBN(isbn) {
                await applyMetadata(metadata, to: book, modelContext: modelContext)
                return
            }
        }

        enrichmentProgress = 0.5

        // Search by title and author
        if let metadata = await searchByTitleAuthor(title: book.title, author: book.author) {
            await applyMetadata(metadata, to: book, modelContext: modelContext)
            return
        }

        enrichmentProgress = 1.0
    }

    /// Enriches all books in the library that lack metadata
    func enrichLibrary(books: [Book], modelContext: ModelContext) async {
        isEnriching = true
        defer {
            isEnriching = false
            enrichmentProgress = 0
        }

        let booksNeedingEnrichment = books.filter { $0.coverImageData == nil || $0.isbn == nil }
        let total = Double(booksNeedingEnrichment.count)

        for (index, book) in booksNeedingEnrichment.enumerated() {
            enrichmentProgress = Double(index) / total
            await enrichBook(book, modelContext: modelContext)
            // Rate limit
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        }
    }

    // MARK: - Duplicate Detection

    /// Checks if a book might be a duplicate of an existing book in the library
    func findDuplicates(for newBook: Book, existingBooks: [Book]) -> [DuplicateMatch] {
        var matches: [DuplicateMatch] = []

        for existing in existingBooks where existing.id != newBook.id {
            var confidence: Double = 0

            // Exact title match
            if existing.title.lowercased() == newBook.title.lowercased() {
                confidence += 0.5
            }
            // Fuzzy title match
            else if levenshteinSimilarity(existing.title, newBook.title) > 0.8 {
                confidence += 0.35
            }

            // Author match
            if existing.author.lowercased() == newBook.author.lowercased() {
                confidence += 0.3
            }

            // ISBN match
            if let existingISBN = existing.isbn, let newISBN = newBook.isbn,
               !existingISBN.isEmpty, !newISBN.isEmpty,
               existingISBN == newISBN {
                confidence = 0.99
            }

            // File size similarity (within 10%)
            if existing.fileSize > 0 && newBook.fileSize > 0 {
                let ratio = Double(min(existing.fileSize, newBook.fileSize)) / Double(max(existing.fileSize, newBook.fileSize))
                if ratio > 0.9 {
                    confidence += 0.1
                }
            }

            if confidence >= 0.5 {
                matches.append(DuplicateMatch(
                    existingBook: existing,
                    confidence: min(confidence, 1.0),
                    reason: confidence >= 0.99 ? "Same ISBN" :
                            confidence >= 0.8 ? "Same title and author" :
                            "Similar title"
                ))
            }
        }

        return matches.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Auto-Categorization

    /// Suggests categories/tags for a book based on its content
    func suggestCategories(for book: Book, chapters: [BookChapter]) -> [String] {
        let allContent = chapters.map(\.content).joined(separator: " ").lowercased()
        var categories: [(String, Int)] = []

        let genreKeywords: [String: [String]] = [
            "Fantasy": ["magic", "wizard", "dragon", "kingdom", "sword", "quest", "enchanted", "elf", "spell", "throne"],
            "Science Fiction": ["space", "planet", "alien", "technology", "future", "robot", "galaxy", "ship", "computer", "artificial"],
            "Mystery": ["detective", "murder", "clue", "suspect", "investigation", "crime", "evidence", "witness", "case", "police"],
            "Romance": ["love", "heart", "kiss", "romance", "passion", "wedding", "desire", "relationship", "affection", "beloved"],
            "Horror": ["fear", "dark", "blood", "ghost", "death", "horror", "scream", "monster", "nightmare", "terror"],
            "History": ["century", "war", "empire", "king", "queen", "revolution", "ancient", "battle", "nation", "colonial"],
            "Philosophy": ["truth", "existence", "consciousness", "moral", "ethics", "reason", "knowledge", "virtue", "being", "reality"],
            "Biography": ["born", "childhood", "career", "life", "memoir", "autobiography", "journey", "legacy", "personal", "experience"],
            "Self-Help": ["success", "habit", "mindset", "productivity", "goal", "motivation", "growth", "improve", "positive", "achieve"],
            "Thriller": ["chase", "escape", "danger", "mission", "agent", "conspiracy", "explosive", "hostage", "kidnap", "pursuit"]
        ]

        for (genre, keywords) in genreKeywords {
            let score = keywords.reduce(0) { $0 + (allContent.contains($1) ? 1 : 0) }
            if score >= 2 {
                categories.append((genre, score))
            }
        }

        return categories
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map(\.0)
    }

    // MARK: - Private API Calls

    private func fetchByISBN(_ isbn: String) async -> BookMetadata? {
        guard let url = URL(string: "\(openLibraryBaseURL)/isbn/\(isbn).json") else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return parseOpenLibraryResponse(json)
        } catch {
            return nil
        }
    }

    private func searchByTitleAuthor(title: String, author: String) async -> BookMetadata? {
        let query = "\(title) \(author)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "\(googleBooksBaseURL)/volumes?q=\(query)&maxResults=1") else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return parseGoogleBooksResponse(json)
        } catch {
            return nil
        }
    }

    private func parseOpenLibraryResponse(_ json: [String: Any]?) -> BookMetadata? {
        guard let json else { return nil }
        let title = json["title"] as? String
        let description = (json["description"] as? [String: Any])?["value"] as? String
            ?? json["description"] as? String
        let isbn = (json["isbn_13"] as? [String])?.first
            ?? (json["isbn_10"] as? [String])?.first
        let coverID = json["covers"] as? [Int]

        var coverURL: String?
        if let id = coverID?.first {
            coverURL = "https://covers.openlibrary.org/b/id/\(id)-L.jpg"
        }

        return BookMetadata(
            title: title,
            description: description,
            isbn: isbn,
            coverURL: coverURL,
            rating: nil,
            pageCount: json["number_of_pages"] as? Int,
            publishDate: json["publish_date"] as? String,
            subjects: json["subjects"] as? [String]
        )
    }

    private func parseGoogleBooksResponse(_ json: [String: Any]?) -> BookMetadata? {
        guard let json,
              let items = json["items"] as? [[String: Any]],
              let volumeInfo = items.first?["volumeInfo"] as? [String: Any] else {
            return nil
        }

        let imageLinks = volumeInfo["imageLinks"] as? [String: String]
        let industryIds = volumeInfo["industryIdentifiers"] as? [[String: String]]
        let isbn = industryIds?.first { $0["type"] == "ISBN_13" }?["identifier"]
            ?? industryIds?.first { $0["type"] == "ISBN_10" }?["identifier"]

        return BookMetadata(
            title: volumeInfo["title"] as? String,
            description: volumeInfo["description"] as? String,
            isbn: isbn,
            coverURL: imageLinks?["thumbnail"]?.replacingOccurrences(of: "http:", with: "https:"),
            rating: volumeInfo["averageRating"] as? Double,
            pageCount: volumeInfo["pageCount"] as? Int,
            publishDate: volumeInfo["publishedDate"] as? String,
            subjects: volumeInfo["categories"] as? [String]
        )
    }

    private func applyMetadata(_ metadata: BookMetadata, to book: Book, modelContext: ModelContext) async {
        if let isbn = metadata.isbn, book.isbn == nil {
            book.isbn = isbn
        }
        if let rating = metadata.rating, book.goodreadsRating == nil {
            book.goodreadsRating = rating
        }

        // Download cover image if we don't have one
        if book.coverImageData == nil, let coverURL = metadata.coverURL {
            if let url = URL(string: coverURL),
               let (data, _) = try? await URLSession.shared.data(from: url) {
                book.coverImageData = data
            }
        }

        enrichmentProgress = 1.0
        try? modelContext.save()
    }

    // MARK: - Utilities

    private func levenshteinSimilarity(_ s1: String, _ s2: String) -> Double {
        let a = Array(s1.lowercased())
        let b = Array(s2.lowercased())
        let m = a.count
        let n = b.count

        guard m > 0 && n > 0 else { return 0 }

        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                if a[i-1] == b[j-1] {
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    dp[i][j] = min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]) + 1
                }
            }
        }

        let maxLen = max(m, n)
        return 1.0 - Double(dp[m][n]) / Double(maxLen)
    }
}

// MARK: - Supporting Types

struct BookMetadata {
    let title: String?
    let description: String?
    let isbn: String?
    let coverURL: String?
    let rating: Double?
    let pageCount: Int?
    let publishDate: String?
    let subjects: [String]?
}

struct DuplicateMatch: Identifiable {
    let id = UUID()
    let existingBook: Book
    let confidence: Double
    let reason: String

    var confidencePercentage: String {
        "\(Int(confidence * 100))%"
    }
}
