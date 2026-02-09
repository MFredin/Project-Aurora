import Foundation

/// Represents a parsed chapter from a book, used across all format parsers
struct BookChapter: Identifiable {
    let id: UUID
    let index: Int
    let title: String
    let content: String

    init(index: Int, title: String, content: String) {
        self.id = UUID()
        self.index = index
        self.title = title
        self.content = content
    }

    var wordCount: Int {
        content.split(separator: " ").count
    }

    var estimatedReadingTimeMinutes: Int {
        max(1, wordCount / 250)
    }
}

/// The result of parsing a book file
struct ParsedBook {
    let title: String
    let author: String
    let chapters: [BookChapter]
    let coverImageData: Data?
    let metadata: [String: String]

    var totalWordCount: Int {
        chapters.reduce(0) { $0 + $1.wordCount }
    }

    var estimatedTotalReadingTimeMinutes: Int {
        max(1, totalWordCount / 250)
    }
}
