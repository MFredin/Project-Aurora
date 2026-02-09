import Foundation

/// GoodReads-branded book discovery service powered by Open Library's free API.
/// The original GoodReads public API was retired in 2020, so this uses
/// openlibrary.org as the backend while keeping the GoodReads naming
/// for the UI layer.
@MainActor @Observable
final class GoodReadsService {
    static let shared = GoodReadsService()

    private(set) var isAuthenticated = false
    private(set) var userProfile: GoodReadsUser?
    var apiKey: String?

    // MARK: - Private Helpers

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private let shelvesKey = "goodreads_shelves"
    private let ratingsKey = "goodreads_ratings"

    private init() {}

    // MARK: - Authentication

    /// Open Library requires no authentication; this simply activates the
    /// service so shelf/rating features backed by UserDefaults work.
    func authenticate(apiKey: String) async throws {
        self.apiKey = apiKey
        self.isAuthenticated = true
        self.userProfile = GoodReadsUser(
            id: "local_user",
            name: "Aurora Reader",
            profileURL: nil,
            imageURL: nil
        )
    }

    func signOut() {
        isAuthenticated = false
        userProfile = nil
        apiKey = nil
    }

    // MARK: - Book Search

    /// Search Open Library and return results mapped to `GoodReadsBook`.
    /// GET https://openlibrary.org/search.json?q={query}&limit=20
    func searchBooks(query: String) async throws -> [GoodReadsBook] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://openlibrary.org/search.json?q=\(encoded)&limit=20") else {
            return []
        }

        guard let data = await fetchData(from: url) else { return [] }
        guard let json = parseJSON(data) as? [String: Any],
              let docs = json["docs"] as? [[String: Any]] else {
            return []
        }

        return docs.compactMap { doc in
            parseSearchDoc(doc)
        }
    }

    // MARK: - Book Details

    /// Fetch detailed information for a single work.
    /// The `goodreadsId` is expected to be an Open Library key such as
    /// `/works/OL12345W`.
    /// GET https://openlibrary.org{goodreadsId}.json
    func getBookDetails(goodreadsId: String) async throws -> GoodReadsBookDetail {
        // 1. Fetch the work JSON
        guard let workURL = URL(string: "https://openlibrary.org\(goodreadsId).json") else {
            throw GoodReadsError.bookNotFound
        }

        guard let workData = await fetchData(from: workURL),
              let workJSON = parseJSON(workData) as? [String: Any] else {
            throw GoodReadsError.bookNotFound
        }

        let title = workJSON["title"] as? String ?? "Unknown Title"

        // Description can be a plain string or a dict with a "value" key
        let bookDescription: String = {
            if let desc = workJSON["description"] as? String {
                return desc
            } else if let descDict = workJSON["description"] as? [String: Any],
                      let value = descDict["value"] as? String {
                return value
            }
            return "No description available."
        }()

        // Subjects
        let subjects = workJSON["subjects"] as? [String] ?? []
        let genres = Array(subjects.prefix(10))

        // Cover
        let coverID = workJSON["covers"] as? [Int]
        let coverURL: String? = coverID?.first.map {
            "https://covers.openlibrary.org/b/id/\($0)-M.jpg"
        }

        // Author – resolve from author references
        let authorName = await resolveAuthor(from: workJSON)

        // 2. Fetch similar books via a title search
        let similarBooks = await fetchSimilarBooks(title: title, excludingId: goodreadsId)

        return GoodReadsBookDetail(
            id: goodreadsId,
            title: title,
            author: authorName,
            isbn: nil,
            isbn13: nil,
            averageRating: 0,
            ratingsCount: 0,
            bookDescription: bookDescription,
            coverURL: coverURL,
            pageCount: 0,
            publishedYear: nil,
            genres: genres,
            similarBooks: similarBooks
        )
    }

    // MARK: - ISBN Lookup

    /// GET https://openlibrary.org/isbn/{isbn}.json
    func lookupByISBN(_ isbn: String) async throws -> GoodReadsBook? {
        let cleaned = isbn.replacingOccurrences(of: "-", with: "")
        guard let url = URL(string: "https://openlibrary.org/isbn/\(cleaned).json") else {
            return nil
        }

        guard let data = await fetchData(from: url),
              let json = parseJSON(data) as? [String: Any] else {
            return nil
        }

        let title = json["title"] as? String ?? "Unknown Title"

        // The edition endpoint gives us a works reference
        let workKey: String? = {
            if let works = json["works"] as? [[String: Any]],
               let key = works.first?["key"] as? String {
                return key
            }
            return nil
        }()

        // Cover
        let covers = json["covers"] as? [Int]
        let coverURL: String? = covers?.first.map {
            "https://covers.openlibrary.org/b/id/\($0)-M.jpg"
        }

        // ISBNs
        let isbnList = json["isbn_13"] as? [String] ?? json["isbn_10"] as? [String]
        let isbnValue = isbnList?.first ?? cleaned

        // Author – resolve
        let authorName = await resolveAuthor(from: json)

        return GoodReadsBook(
            id: workKey ?? "/isbn/\(cleaned)",
            title: title,
            author: authorName,
            averageRating: 0,
            ratingsCount: 0,
            coverURL: coverURL,
            isbn: isbnValue
        )
    }

    // MARK: - Reviews

    /// Open Library does not expose user reviews. We return a placeholder
    /// explaining this so the UI can display a helpful message.
    func getReviews(goodreadsId: String, page: Int = 1) async throws -> GoodReadsReviewList {
        let placeholder = GoodReadsReview(
            id: "placeholder",
            userName: "Open Library",
            rating: 0,
            body: "Community reviews are not available through Open Library. "
                + "Visit openlibrary.org or goodreads.com to read and write reviews.",
            date: Date()
        )
        return GoodReadsReviewList(reviews: [placeholder], totalCount: 1, currentPage: page)
    }

    // MARK: - Ratings (stored locally)

    /// Persist a 1-5 star rating in UserDefaults keyed by the book's id.
    func rateBook(goodreadsId: String, rating: Int) async throws {
        guard isAuthenticated else { throw GoodReadsError.notAuthenticated }
        guard rating >= 1 && rating <= 5 else { throw GoodReadsError.invalidRating }

        var ratings = loadRatings()
        ratings[goodreadsId] = rating
        saveRatings(ratings)
    }

    /// Retrieve the locally-stored rating for a book, if any.
    func getRating(goodreadsId: String) -> Int? {
        let ratings = loadRatings()
        return ratings[goodreadsId]
    }

    // MARK: - Shelves (stored locally)

    /// Return the three default shelves with up-to-date book counts
    /// derived from UserDefaults.
    func getUserShelves() async throws -> [GoodReadsShelf] {
        guard isAuthenticated else { throw GoodReadsError.notAuthenticated }

        let defaultShelves = ["Read", "Currently Reading", "Want to Read"]
        return defaultShelves.enumerated().map { index, name in
            let books = loadShelfBooks(shelfName: name)
            return GoodReadsShelf(
                id: "\(index + 1)",
                name: name,
                bookCount: books.count
            )
        }
    }

    /// Add a book id to a named shelf in UserDefaults.
    func addToShelf(goodreadsId: String, shelfName: String) async throws {
        guard isAuthenticated else { throw GoodReadsError.notAuthenticated }

        var books = loadShelfBooks(shelfName: shelfName)
        if !books.contains(goodreadsId) {
            books.append(goodreadsId)
        }
        saveShelfBooks(books, shelfName: shelfName)
    }

    /// Remove a book id from a named shelf.
    func removeFromShelf(goodreadsId: String, shelfName: String) async throws {
        guard isAuthenticated else { throw GoodReadsError.notAuthenticated }

        var books = loadShelfBooks(shelfName: shelfName)
        books.removeAll { $0 == goodreadsId }
        saveShelfBooks(books, shelfName: shelfName)
    }

    /// Return full `GoodReadsBook` objects for every id on the given shelf.
    /// Books whose details can't be fetched are silently skipped.
    func getBooksOnShelf(shelfName: String, page: Int = 1) async throws -> [GoodReadsBook] {
        guard isAuthenticated else { throw GoodReadsError.notAuthenticated }

        let bookIds = loadShelfBooks(shelfName: shelfName)
        if bookIds.isEmpty { return [] }

        // Page through 20 at a time
        let pageSize = 20
        let startIndex = (page - 1) * pageSize
        guard startIndex < bookIds.count else { return [] }
        let endIndex = min(startIndex + pageSize, bookIds.count)
        let pageIds = Array(bookIds[startIndex..<endIndex])

        var results: [GoodReadsBook] = []
        for bookId in pageIds {
            if let book = await fetchBookSummary(workKey: bookId) {
                results.append(book)
            }
        }
        return results
    }

    // MARK: - Private Networking

    /// Perform a GET request and return raw data, or nil on failure.
    private nonisolated func fetchData(from url: URL) async -> Data? {
        do {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                return nil
            }
            return data
        } catch {
            return nil
        }
    }

    /// Deserialize raw JSON data.
    private nonisolated func parseJSON(_ data: Data) -> Any? {
        try? JSONSerialization.jsonObject(with: data, options: [])
    }

    // MARK: - Private Parsing

    /// Map a single search `doc` dictionary to `GoodReadsBook`.
    private nonisolated func parseSearchDoc(_ doc: [String: Any]) -> GoodReadsBook? {
        guard let key = doc["key"] as? String,
              let title = doc["title"] as? String else {
            return nil
        }

        let author: String = {
            if let names = doc["author_name"] as? [String], let first = names.first {
                return first
            }
            return "Unknown Author"
        }()

        let averageRating = doc["ratings_average"] as? Double ?? 0
        let ratingsCount = doc["ratings_count"] as? Int ?? 0

        let coverURL: String? = {
            if let coverID = doc["cover_i"] as? Int {
                return "https://covers.openlibrary.org/b/id/\(coverID)-M.jpg"
            }
            return nil
        }()

        let isbn: String? = {
            if let isbns = doc["isbn"] as? [String], let first = isbns.first {
                return first
            }
            return nil
        }()

        return GoodReadsBook(
            id: key,
            title: title,
            author: author,
            averageRating: averageRating,
            ratingsCount: ratingsCount,
            coverURL: coverURL,
            isbn: isbn
        )
    }

    /// Resolve the first author name from a work or edition JSON that contains
    /// an `authors` array with `author.key` references.
    private func resolveAuthor(from json: [String: Any]) -> String {
        // Works use: authors[].author.key  →  /authors/OL123A
        if let authors = json["authors"] as? [[String: Any]] {
            for entry in authors {
                let authorKey: String? = {
                    if let ref = entry["author"] as? [String: Any],
                       let key = ref["key"] as? String {
                        return key
                    }
                    // Editions sometimes use "key" directly
                    if let key = entry["key"] as? String {
                        return key
                    }
                    return nil
                }()
                if let key = authorKey,
                   let url = URL(string: "https://openlibrary.org\(key).json"),
                   let data = await fetchData(from: url),
                   let authorJSON = parseJSON(data) as? [String: Any],
                   let name = authorJSON["name"] as? String {
                    return name
                }
            }
        }

        // Editions may have a flat "by_statement"
        if let byStatement = json["by_statement"] as? String {
            return byStatement
        }

        return "Unknown Author"
    }

    /// Search for similar books by title, excluding the original book.
    private func fetchSimilarBooks(title: String, excludingId: String) async -> [GoodReadsBook] {
        // Use the first few meaningful words to get related results
        let words = title.split(separator: " ").prefix(3).joined(separator: " ")
        guard let encoded = words.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://openlibrary.org/search.json?q=\(encoded)&limit=6") else {
            return []
        }

        guard let data = await fetchData(from: url),
              let json = parseJSON(data) as? [String: Any],
              let docs = json["docs"] as? [[String: Any]] else {
            return []
        }

        return docs.compactMap { doc in
            guard let book = parseSearchDoc(doc), book.id != excludingId else {
                return nil
            }
            return book
        }.prefix(5).map { $0 }
    }

    /// Fetch minimal book info for a single work key (used when hydrating shelf books).
    private func fetchBookSummary(workKey: String) async -> GoodReadsBook? {
        guard let url = URL(string: "https://openlibrary.org\(workKey).json") else {
            return nil
        }

        guard let data = await fetchData(from: url),
              let json = parseJSON(data) as? [String: Any] else {
            return nil
        }

        let title = json["title"] as? String ?? "Unknown Title"
        let coverURL: String? = {
            if let covers = json["covers"] as? [Int], let first = covers.first {
                return "https://covers.openlibrary.org/b/id/\(first)-M.jpg"
            }
            return nil
        }()

        let authorName = await resolveAuthor(from: json)

        return GoodReadsBook(
            id: workKey,
            title: title,
            author: authorName,
            averageRating: 0,
            ratingsCount: 0,
            coverURL: coverURL,
            isbn: nil
        )
    }

    // MARK: - UserDefaults Persistence

    private nonisolated func shelfKey(for name: String) -> String {
        "\(shelvesKey)_\(name)"
    }

    private nonisolated func loadShelfBooks(shelfName: String) -> [String] {
        let key = shelfKey(for: shelfName)
        guard let data = UserDefaults.standard.data(forKey: key),
              let array = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            return []
        }
        return array
    }

    private nonisolated func saveShelfBooks(_ books: [String], shelfName: String) {
        let key = shelfKey(for: shelfName)
        if let data = try? JSONSerialization.data(withJSONObject: books) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private nonisolated func loadRatings() -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: ratingsKey),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Int] else {
            return [:]
        }
        return dict
    }

    private nonisolated func saveRatings(_ ratings: [String: Int]) {
        if let data = try? JSONSerialization.data(withJSONObject: ratings) {
            UserDefaults.standard.set(data, forKey: ratingsKey)
        }
    }
}

// MARK: - GoodReads Models

struct GoodReadsUser {
    let id: String
    let name: String
    let profileURL: String?
    let imageURL: String?
}

struct GoodReadsBook: Identifiable {
    let id: String
    let title: String
    let author: String
    let averageRating: Double
    let ratingsCount: Int
    let coverURL: String?
    let isbn: String?
}

struct GoodReadsBookDetail {
    let id: String
    let title: String
    let author: String
    let isbn: String?
    let isbn13: String?
    let averageRating: Double
    let ratingsCount: Int
    let bookDescription: String
    let coverURL: String?
    let pageCount: Int
    let publishedYear: Int?
    let genres: [String]
    let similarBooks: [GoodReadsBook]
}

struct GoodReadsReview: Identifiable {
    let id: String
    let userName: String
    let rating: Int
    let body: String
    let date: Date
}

struct GoodReadsReviewList {
    let reviews: [GoodReadsReview]
    let totalCount: Int
    let currentPage: Int
}

struct GoodReadsShelf: Identifiable {
    let id: String
    let name: String
    let bookCount: Int
}

enum GoodReadsError: LocalizedError {
    case notConfigured
    case notAuthenticated
    case bookNotFound
    case rateLimited
    case invalidRating
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "GoodReads API key not configured"
        case .notAuthenticated: return "Not signed in to GoodReads"
        case .bookNotFound: return "Book not found on GoodReads"
        case .rateLimited: return "Too many requests, please try again later"
        case .invalidRating: return "Rating must be between 1 and 5"
        case .networkError(let d): return "Network error: \(d)"
        }
    }
}
