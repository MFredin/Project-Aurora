import Foundation
import SwiftData

/// Supported ebook formats
enum BookFormat: String, Codable, CaseIterable {
    case epub
    case pdf
    case plainText = "txt"

    var displayName: String {
        switch self {
        case .epub: return "EPUB"
        case .pdf: return "PDF"
        case .plainText: return "Plain Text"
        }
    }

    var fileExtension: String {
        return rawValue
    }

    static func from(fileExtension: String) -> BookFormat? {
        let ext = fileExtension.lowercased()
        switch ext {
        case "epub": return .epub
        case "pdf": return .pdf
        case "txt", "text": return .plainText
        default: return nil
        }
    }
}

@Model
final class Book {
    var id: UUID
    var title: String
    var author: String
    var coverImageData: Data?
    var fileURL: String
    var format: String
    var dateAdded: Date
    var lastOpened: Date?
    var fileSize: Int64

    @Relationship(deleteRule: .cascade) var readingProgress: ReadingProgress?
    @Relationship(deleteRule: .cascade) var bookmarks: [Bookmark]

    var bookFormat: BookFormat {
        get { BookFormat(rawValue: format) ?? .plainText }
        set { format = newValue.rawValue }
    }

    init(
        title: String,
        author: String = "Unknown Author",
        coverImageData: Data? = nil,
        fileURL: URL,
        format: BookFormat,
        fileSize: Int64 = 0
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.coverImageData = coverImageData
        self.fileURL = fileURL.absoluteString
        self.format = format.rawValue
        self.dateAdded = Date()
        self.lastOpened = nil
        self.fileSize = fileSize
        self.bookmarks = []
    }

    var fileURLValue: URL? {
        URL(string: fileURL)
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}
