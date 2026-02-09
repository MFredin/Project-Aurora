import Foundation

/// GoodReads integration for book discovery, ratings, reviews, and shelves
@MainActor @Observable
final class GoodReadsService {
    static let shared = GoodReadsService()

    private(set) var isAuthenticated = false
    private(set) var userProfile: GoodReadsUser?
    var apiKey: String?

    private init() {}

    // MARK: - Authentication

    func authenticate(apiKey: String) async throws {
        self.apiKey = apiKey
        self.isAuthenticated = true
    }

    func signOut() {
        isAuthenticated = false
        userProfile = nil
        apiKey = nil
    }

    // MARK: - Book Search

    func searchBooks(query: String) async throws -> [GoodReadsBook] {
        guard apiKey != nil else { throw GoodReadsError.notConfigured }
        // GET /search/index.xml?key={key}&q={query}
        return []
    }

    func getBookDetails(goodreadsId: String) async throws -> GoodReadsBookDetail {
        guard apiKey != nil else { throw GoodReadsError.notConfigured }
        // GET /book/show/{id}.xml?key={key}
        return GoodReadsBookDetail(
            id: goodreadsId, title: "", author: "",
            isbn: nil, isbn13: nil, averageRating: 0, ratingsCount: 0,
            bookDescription: "", coverURL: nil, pageCount: 0,
            publishedYear: nil, genres: [], similarBooks: []
        )
    }

    func lookupByISBN(_ isbn: String) async throws -> GoodReadsBook? {
        guard apiKey != nil else { throw GoodReadsError.notConfigured }
        // GET /book/isbn/{isbn}?key={key}
        return nil
    }

    // MARK: - Ratings & Reviews

    func getReviews(goodreadsId: String, page: Int = 1) async throws -> GoodReadsReviewList {
        guard apiKey != nil else { throw GoodReadsError.notConfigured }
        return GoodReadsReviewList(reviews: [], totalCount: 0, currentPage: page)
    }

    func rateBook(goodreadsId: String, rating: Int) async throws {
        guard isAuthenticated else { throw GoodReadsError.notAuthenticated }
        guard rating >= 1 && rating <= 5 else { throw GoodReadsError.invalidRating }
        // POST /rating
    }

    // MARK: - Shelves

    func getUserShelves() async throws -> [GoodReadsShelf] {
        guard isAuthenticated else { throw GoodReadsError.notAuthenticated }
        return [
            GoodReadsShelf(id: "1", name: "Read", bookCount: 0),
            GoodReadsShelf(id: "2", name: "Currently Reading", bookCount: 0),
            GoodReadsShelf(id: "3", name: "Want to Read", bookCount: 0),
        ]
    }

    func addToShelf(goodreadsId: String, shelfName: String) async throws {
        guard isAuthenticated else { throw GoodReadsError.notAuthenticated }
        // POST /shelf/add_to_shelf.xml
    }

    func getBooksOnShelf(shelfName: String, page: Int = 1) async throws -> [GoodReadsBook] {
        guard isAuthenticated else { throw GoodReadsError.notAuthenticated }
        return []
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
