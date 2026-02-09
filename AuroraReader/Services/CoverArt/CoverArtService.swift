import Foundation
import SwiftData

/// Multi-source book cover discovery and download service
/// Searches Open Library and Google Books to find accurate covers by ISBN, title, and author
@MainActor @Observable
final class CoverArtService {
    static let shared = CoverArtService()

    var isFetching = false
    var fetchProgress: Double = 0
    var fetchedCount = 0
    var totalToFetch = 0
    var coversFoundCount = 0

    private init() {}

    // MARK: - Single Book Cover Fetch

    /// Fetches a cover for a single book, trying multiple sources in order of accuracy
    @discardableResult
    func fetchCover(for book: Book, modelContext: ModelContext) async -> Bool {
        // Strategy: ISBN (most accurate) → Open Library search → Google Books search

        // 1. Try by ISBN via Open Library Covers API
        if let isbn = book.isbn, !isbn.isEmpty {
            if let data = await fetchFromOpenLibraryByISBN(isbn) {
                book.coverImageData = data
                try? modelContext.save()
                return true
            }
        }

        // 2. Try Open Library search by title + author
        if let data = await fetchFromOpenLibraryBySearch(title: book.title, author: book.author) {
            book.coverImageData = data
            try? modelContext.save()
            return true
        }

        // 3. Try Google Books API
        if let data = await fetchFromGoogleBooks(title: book.title, author: book.author) {
            book.coverImageData = data
            try? modelContext.save()
            return true
        }

        return false
    }

    // MARK: - Batch Library Cover Fetch

    /// Fetches covers for all books missing cover art
    func fetchMissingCovers(books: [Book], modelContext: ModelContext) async {
        let booksNeedingCovers = books.filter { $0.coverImageData == nil }
        guard !booksNeedingCovers.isEmpty else { return }

        isFetching = true
        totalToFetch = booksNeedingCovers.count
        fetchedCount = 0
        coversFoundCount = 0
        fetchProgress = 0

        defer {
            isFetching = false
            fetchProgress = 0
        }

        for book in booksNeedingCovers {
            let found = await fetchCover(for: book, modelContext: modelContext)
            fetchedCount += 1
            if found { coversFoundCount += 1 }
            fetchProgress = Double(fetchedCount) / Double(totalToFetch)

            // Rate limit between requests
            let delay: UInt64 = found ? 300_000_000 : 200_000_000
            try? await Task.sleep(nanoseconds: delay)
        }
    }

    /// Fetches a cover for a book even if it already has one (force refresh)
    func refreshCover(for book: Book, modelContext: ModelContext) async -> Bool {
        let hadCover = book.coverImageData
        book.coverImageData = nil

        let success = await fetchCover(for: book, modelContext: modelContext)
        if !success {
            // Restore old cover if new fetch failed
            book.coverImageData = hadCover
            try? modelContext.save()
        }
        return success
    }

    // MARK: - Open Library (by ISBN)

    private func fetchFromOpenLibraryByISBN(_ isbn: String) async -> Data? {
        let cleanISBN = isbn.replacingOccurrences(of: "-", with: "")
        guard let url = URL(string: "https://covers.openlibrary.org/b/isbn/\(cleanISBN)-L.jpg?default=false") else {
            return nil
        }
        return await downloadImage(from: url)
    }

    // MARK: - Open Library (by Search)

    private func fetchFromOpenLibraryBySearch(title: String, author: String) async -> Data? {
        let query = buildSearchQuery(title: title, author: author)
        guard let searchURL = URL(
            string: "https://openlibrary.org/search.json?q=\(query)&limit=5&fields=cover_i,title,author_name"
        ) else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: searchURL)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let docs = json?["docs"] as? [[String: Any]] else { return nil }

            let bestMatch = findBestMatch(docs: docs, title: title, author: author)

            guard let coverId = bestMatch?["cover_i"] as? Int else { return nil }
            guard let coverURL = URL(string: "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg") else {
                return nil
            }
            return await downloadImage(from: coverURL)
        } catch {
            return nil
        }
    }

    // MARK: - Google Books

    private func fetchFromGoogleBooks(title: String, author: String) async -> Data? {
        let query = buildSearchQuery(title: title, author: author)
        guard let searchURL = URL(
            string: "https://www.googleapis.com/books/v1/volumes?q=\(query)&maxResults=5"
        ) else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: searchURL)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let items = json?["items"] as? [[String: Any]] else { return nil }

            // Score items and try best matches first
            let scored = items.compactMap { item -> (score: Double, item: [String: Any])? in
                guard let volumeInfo = item["volumeInfo"] as? [String: Any] else { return nil }
                let score = scoreMatch(volumeInfo: volumeInfo, title: title, author: author)
                return (score, item)
            }.sorted { $0.score > $1.score }

            for (_, item) in scored {
                guard let volumeInfo = item["volumeInfo"] as? [String: Any],
                      let imageLinks = volumeInfo["imageLinks"] as? [String: String] else {
                    continue
                }

                // Prefer larger images
                let coverURLString = imageLinks["extraLarge"]
                    ?? imageLinks["large"]
                    ?? imageLinks["medium"]
                    ?? imageLinks["thumbnail"]

                guard let urlString = coverURLString else { continue }

                // Upgrade to HTTPS and request larger zoom
                let secureURL = urlString
                    .replacingOccurrences(of: "http:", with: "https:")
                    .replacingOccurrences(of: "zoom=1", with: "zoom=3")

                guard let coverURL = URL(string: secureURL) else { continue }

                if let imageData = await downloadImage(from: coverURL) {
                    return imageData
                }
            }

            return nil
        } catch {
            return nil
        }
    }

    // MARK: - Helpers

    private func downloadImage(from url: URL) async -> Data? {
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  data.count > 1000 else { // Filter tiny placeholder images
                return nil
            }

            // Verify image format by magic bytes
            guard isValidImageData(data) else { return nil }

            return data
        } catch {
            return nil
        }
    }

    private func isValidImageData(_ data: Data) -> Bool {
        guard data.count >= 4 else { return false }
        let header = [UInt8](data.prefix(12))

        let isJPEG = header[0] == 0xFF && header[1] == 0xD8
        let isPNG = header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47
        let isGIF = header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46
        let isWebP = data.count > 12 && header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50

        return isJPEG || isPNG || isGIF || isWebP
    }

    private func buildSearchQuery(title: String, author: String) -> String {
        var query = title
        if author != "Unknown Author" && !author.isEmpty {
            query += " \(author)"
        }
        return query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }

    private func findBestMatch(docs: [[String: Any]], title: String, author: String) -> [String: Any]? {
        let normalizedTitle = title.lowercased()
        let normalizedAuthor = author.lowercased()

        var bestScore = 0.0
        var bestDoc: [String: Any]?

        for doc in docs {
            guard doc["cover_i"] != nil else { continue }
            var score = 0.0

            if let docTitle = doc["title"] as? String {
                let docLower = docTitle.lowercased()
                if docLower == normalizedTitle { score += 1.0 }
                else if docLower.contains(normalizedTitle) || normalizedTitle.contains(docLower) { score += 0.5 }
            }

            if let authors = doc["author_name"] as? [String] {
                for docAuthor in authors {
                    let authorLower = docAuthor.lowercased()
                    if authorLower.contains(normalizedAuthor) || normalizedAuthor.contains(authorLower) {
                        score += 0.5
                        break
                    }
                }
            }

            if score > bestScore {
                bestScore = score
                bestDoc = doc
            }
        }

        return bestDoc
    }

    private func scoreMatch(volumeInfo: [String: Any], title: String, author: String) -> Double {
        var score = 0.0
        let normalizedTitle = title.lowercased()
        let normalizedAuthor = author.lowercased()

        if let vTitle = volumeInfo["title"] as? String {
            let vLower = vTitle.lowercased()
            if vLower == normalizedTitle { score += 1.0 }
            else if vLower.contains(normalizedTitle) || normalizedTitle.contains(vLower) { score += 0.5 }
        }

        if let authors = volumeInfo["authors"] as? [String] {
            for a in authors {
                let aLower = a.lowercased()
                if aLower.contains(normalizedAuthor) || normalizedAuthor.contains(aLower) {
                    score += 0.5
                    break
                }
            }
        }

        // Bonus for having images
        if let links = volumeInfo["imageLinks"] as? [String: String] {
            if links["large"] != nil || links["extraLarge"] != nil { score += 0.2 }
            else if links["medium"] != nil { score += 0.1 }
        }

        return score
    }
}
