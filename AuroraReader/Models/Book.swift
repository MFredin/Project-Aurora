import Foundation
import SwiftData

/// Supported ebook formats - comprehensive list
enum BookFormat: String, Codable, CaseIterable {
    case epub
    case pdf
    case plainText = "txt"
    case mobi
    case azw3
    case fb2
    case cbz
    case cbr
    case djvu
    case rtf
    case htmlBook = "html"

    var displayName: String {
        switch self {
        case .epub: return "EPUB"
        case .pdf: return "PDF"
        case .plainText: return "Plain Text"
        case .mobi: return "MOBI"
        case .azw3: return "AZW3"
        case .fb2: return "FB2"
        case .cbz: return "CBZ"
        case .cbr: return "CBR"
        case .djvu: return "DjVu"
        case .rtf: return "RTF"
        case .htmlBook: return "HTML"
        }
    }

    var fileExtension: String {
        return rawValue
    }

    var category: FormatCategory {
        switch self {
        case .epub, .mobi, .azw3, .fb2: return .ebook
        case .pdf, .djvu: return .document
        case .plainText, .rtf, .htmlBook: return .text
        case .cbz, .cbr: return .comic
        }
    }

    var iconName: String {
        switch self {
        case .epub: return "book.fill"
        case .pdf: return "book.closed.fill"
        case .plainText: return "text.book.closed.fill"
        case .mobi: return "book.fill"
        case .azw3: return "book.fill"
        case .fb2: return "text.book.closed.fill"
        case .cbz, .cbr: return "books.vertical.fill"
        case .djvu: return "book.closed.fill"
        case .rtf: return "text.book.closed.fill"
        case .htmlBook: return "book.closed.fill"
        }
    }

    var formatDescription: String {
        switch self {
        case .epub: return "Open standard ebook format"
        case .pdf: return "Portable Document Format"
        case .plainText: return "Unformatted text files"
        case .mobi: return "Mobipocket ebook format"
        case .azw3: return "Amazon Kindle format"
        case .fb2: return "FictionBook XML format"
        case .cbz: return "Comic book archive (ZIP)"
        case .cbr: return "Comic book archive (RAR)"
        case .djvu: return "Scanned document format"
        case .rtf: return "Rich Text Format"
        case .htmlBook: return "Web page as book"
        }
    }

    enum FormatCategory: String, CaseIterable {
        case ebook = "Ebooks"
        case document = "Documents"
        case text = "Text"
        case comic = "Comics"
    }

    static func from(fileExtension: String) -> BookFormat? {
        let ext = fileExtension.lowercased()
        switch ext {
        case "epub": return .epub
        case "pdf": return .pdf
        case "txt", "text": return .plainText
        case "mobi", "prc": return .mobi
        case "azw3", "azw": return .azw3
        case "fb2": return .fb2
        case "cbz": return .cbz
        case "cbr": return .cbr
        case "djvu", "djv": return .djvu
        case "rtf": return .rtf
        case "html", "htm", "xhtml": return .htmlBook
        default: return nil
        }
    }

    static var allExtensions: [String] {
        ["epub", "pdf", "txt", "text", "mobi", "prc", "azw3", "azw",
         "fb2", "cbz", "cbr", "djvu", "djv", "rtf", "html", "htm", "xhtml"]
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
    var cloudSource: String?
    var goodreadsId: String?
    var goodreadsRating: Double?
    var isbn: String?

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
        fileSize: Int64 = 0,
        cloudSource: String? = nil
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
        self.cloudSource = cloudSource
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

    var cloudSourceProvider: CloudStorageProvider? {
        guard let source = cloudSource else { return nil }
        return CloudStorageProvider(rawValue: source)
    }
}
