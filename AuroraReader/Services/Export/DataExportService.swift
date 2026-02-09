import Foundation
import SwiftData
import SwiftUI

/// Service to export library data, reading stats, highlights, and annotations
@MainActor @Observable
final class DataExportService {
    static let shared = DataExportService()

    var isExporting: Bool = false
    var exportProgress: Double = 0

    private init() {}

    // MARK: - Export Formats

    enum ExportFormat: String, CaseIterable, Identifiable {
        case json = "JSON"
        case csv = "CSV"
        case markdown = "Markdown"

        var id: String { rawValue }

        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            case .markdown: return "md"
            }
        }

        var mimeType: String {
            switch self {
            case .json: return "application/json"
            case .csv: return "text/csv"
            case .markdown: return "text/markdown"
            }
        }

        var iconName: String {
            switch self {
            case .json: return "curlybraces"
            case .csv: return "tablecells"
            case .markdown: return "text.document"
            }
        }
    }

    enum ExportContent: String, CaseIterable, Identifiable {
        case library = "Library"
        case highlights = "Highlights"
        case bookmarks = "Bookmarks"
        case readingStats = "Reading Stats"
        case vocabulary = "Vocabulary"
        case everything = "Everything"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .library: return "books.vertical.fill"
            case .highlights: return "highlighter"
            case .bookmarks: return "bookmark.fill"
            case .readingStats: return "chart.bar.fill"
            case .vocabulary: return "text.book.closed.fill"
            case .everything: return "square.and.arrow.up.fill"
            }
        }
    }

    // MARK: - Export

    func exportData(
        content: ExportContent,
        format: ExportFormat,
        books: [Book],
        highlights: [Highlight],
        bookmarks: [Bookmark],
        sessions: [ReadingSession],
        vocabulary: [VocabularyEntry]
    ) -> URL? {
        isExporting = true
        exportProgress = 0
        defer {
            isExporting = false
            exportProgress = 1.0
        }

        let result: String
        switch content {
        case .library:
            result = exportLibrary(books: books, format: format)
        case .highlights:
            result = exportHighlights(highlights: highlights, format: format)
        case .bookmarks:
            result = exportBookmarks(bookmarks: bookmarks, format: format)
        case .readingStats:
            result = exportReadingStats(sessions: sessions, books: books, format: format)
        case .vocabulary:
            result = exportVocabulary(vocabulary: vocabulary, format: format)
        case .everything:
            result = exportEverything(
                books: books,
                highlights: highlights,
                bookmarks: bookmarks,
                sessions: sessions,
                vocabulary: vocabulary,
                format: format
            )
        }

        exportProgress = 0.9
        return writeToTempFile(content: result, name: "aurora-\(content.rawValue.lowercased())", extension: format.fileExtension)
    }

    // MARK: - Library Export

    private func exportLibrary(books: [Book], format: ExportFormat) -> String {
        switch format {
        case .json:
            let entries = books.map { book in
                [
                    "title": book.title,
                    "author": book.author,
                    "format": book.bookFormat.displayName,
                    "dateAdded": ISO8601DateFormatter().string(from: book.dateAdded),
                    "lastOpened": book.lastOpened.map { ISO8601DateFormatter().string(from: $0) } ?? "Never",
                    "isbn": book.isbn ?? "",
                    "progress": "\(Int((book.readingProgress?.progressPercentage ?? 0) * 100))%",
                    "fileSize": book.formattedFileSize
                ]
            }
            return jsonString(entries)

        case .csv:
            var lines = ["Title,Author,Format,Date Added,Last Opened,ISBN,Progress,File Size"]
            for book in books {
                let progress = Int((book.readingProgress?.progressPercentage ?? 0) * 100)
                let lastOpened = book.lastOpened.map { ISO8601DateFormatter().string(from: $0) } ?? "Never"
                lines.append("\"\(book.title)\",\"\(book.author)\",\(book.bookFormat.displayName),\(ISO8601DateFormatter().string(from: book.dateAdded)),\(lastOpened),\(book.isbn ?? ""),\(progress)%,\(book.formattedFileSize)")
            }
            return lines.joined(separator: "\n")

        case .markdown:
            var md = "# Aurora Reader Library\n\n"
            md += "Exported: \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))\n\n"
            md += "| Title | Author | Format | Progress |\n"
            md += "|-------|--------|--------|----------|\n"
            for book in books {
                let progress = Int((book.readingProgress?.progressPercentage ?? 0) * 100)
                md += "| \(book.title) | \(book.author) | \(book.bookFormat.displayName) | \(progress)% |\n"
            }
            md += "\n**Total:** \(books.count) books\n"
            return md
        }
    }

    // MARK: - Highlights Export

    private func exportHighlights(highlights: [Highlight], format: ExportFormat) -> String {
        switch format {
        case .json:
            let entries = highlights.map { h in
                [
                    "text": h.highlightedText,
                    "note": h.note,
                    "chapter": h.chapterTitle,
                    "color": h.highlightColor.rawValue,
                    "date": ISO8601DateFormatter().string(from: h.dateCreated),
                    "book": h.book?.title ?? "Unknown"
                ]
            }
            return jsonString(entries)

        case .csv:
            var lines = ["Text,Note,Chapter,Color,Date,Book"]
            for h in highlights {
                lines.append("\"\(h.highlightedText.replacingOccurrences(of: "\"", with: "\"\""))\",\"\(h.note.replacingOccurrences(of: "\"", with: "\"\""))\",\"\(h.chapterTitle)\",\(h.highlightColor.rawValue),\(ISO8601DateFormatter().string(from: h.dateCreated)),\"\(h.book?.title ?? "Unknown")\"")
            }
            return lines.joined(separator: "\n")

        case .markdown:
            var md = "# Highlights & Notes\n\n"
            md += "Exported: \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))\n\n"
            let grouped = Dictionary(grouping: highlights) { $0.book?.title ?? "Unknown" }
            for (bookTitle, bookHighlights) in grouped.sorted(by: { $0.key < $1.key }) {
                md += "## \(bookTitle)\n\n"
                for h in bookHighlights {
                    md += "> \(h.highlightedText)\n"
                    if !h.note.isEmpty {
                        md += "\n*Note:* \(h.note)\n"
                    }
                    md += "\n— Chapter: \(h.chapterTitle)\n\n---\n\n"
                }
            }
            md += "**Total:** \(highlights.count) highlights\n"
            return md
        }
    }

    // MARK: - Bookmarks Export

    private func exportBookmarks(bookmarks: [Bookmark], format: ExportFormat) -> String {
        switch format {
        case .json:
            let entries = bookmarks.map { b in
                [
                    "title": b.title,
                    "chapter": "\(b.chapter)",
                    "page": "\(b.page)",
                    "textSnippet": b.textSnippet,
                    "date": ISO8601DateFormatter().string(from: b.dateCreated),
                    "book": b.book?.title ?? "Unknown"
                ]
            }
            return jsonString(entries)

        case .csv:
            var lines = ["Title,Chapter,Page,Text Snippet,Date,Book"]
            for b in bookmarks {
                lines.append("\"\(b.title)\",\(b.chapter),\(b.page),\"\(b.textSnippet.replacingOccurrences(of: "\"", with: "\"\""))\",\(ISO8601DateFormatter().string(from: b.dateCreated)),\"\(b.book?.title ?? "Unknown")\"")
            }
            return lines.joined(separator: "\n")

        case .markdown:
            var md = "# Bookmarks\n\n"
            let grouped = Dictionary(grouping: bookmarks) { $0.book?.title ?? "Unknown" }
            for (bookTitle, bmarks) in grouped.sorted(by: { $0.key < $1.key }) {
                md += "## \(bookTitle)\n\n"
                for b in bmarks {
                    md += "- **\(b.title)** — Chapter \(b.chapter + 1)\n"
                    if !b.textSnippet.isEmpty {
                        md += "  > \(b.textSnippet.prefix(80))...\n"
                    }
                }
                md += "\n"
            }
            return md
        }
    }

    // MARK: - Reading Stats Export

    private func exportReadingStats(sessions: [ReadingSession], books: [Book], format: ExportFormat) -> String {
        let totalMinutes = sessions.reduce(0) { $0 + $1.durationSeconds } / 60
        let totalPages = sessions.reduce(0) { $0 + $1.pagesRead }

        switch format {
        case .json:
            let sessionEntries = sessions.map { s in
                [
                    "book": s.book?.title ?? "Unknown",
                    "date": ISO8601DateFormatter().string(from: s.startTime),
                    "duration": s.durationFormatted,
                    "pagesRead": "\(s.pagesRead)",
                    "chaptersRead": "\(s.chaptersRead)"
                ]
            }
            let summaryJSON = """
            {"summary":{"totalReadingMinutes":\(totalMinutes),"totalPagesRead":\(totalPages),"totalSessions":\(sessions.count),"totalBooks":\(books.count)},"sessions":\(jsonString(sessionEntries))}
            """
            return summaryJSON

        case .csv:
            var lines = ["Book,Date,Duration,Pages Read,Chapters Read"]
            for s in sessions {
                lines.append("\"\(s.book?.title ?? "Unknown")\",\(ISO8601DateFormatter().string(from: s.startTime)),\(s.durationFormatted),\(s.pagesRead),\(s.chaptersRead)")
            }
            return lines.joined(separator: "\n")

        case .markdown:
            var md = "# Reading Statistics\n\n"
            md += "Exported: \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))\n\n"
            md += "## Summary\n\n"
            md += "- **Total Reading Time:** \(totalMinutes / 60)h \(totalMinutes % 60)m\n"
            md += "- **Total Pages:** \(totalPages)\n"
            md += "- **Total Sessions:** \(sessions.count)\n"
            md += "- **Books in Library:** \(books.count)\n\n"
            md += "## Recent Sessions\n\n"
            for s in sessions.prefix(20) {
                md += "- \(s.book?.title ?? "Unknown") — \(s.durationFormatted), \(s.pagesRead) pages\n"
            }
            return md
        }
    }

    // MARK: - Vocabulary Export

    private func exportVocabulary(vocabulary: [VocabularyEntry], format: ExportFormat) -> String {
        switch format {
        case .json:
            let entries = vocabulary.map { v in
                [
                    "word": v.word,
                    "definition": v.definition,
                    "context": v.context,
                    "book": v.bookTitle,
                    "date": ISO8601DateFormatter().string(from: v.dateAdded),
                    "mastery": "\(v.masteryLevel)"
                ]
            }
            return jsonString(entries)

        case .csv:
            var lines = ["Word,Definition,Context,Book,Date,Mastery"]
            for v in vocabulary {
                lines.append("\"\(v.word)\",\"\(v.definition.replacingOccurrences(of: "\"", with: "\"\""))\",\"\(v.context.replacingOccurrences(of: "\"", with: "\"\""))\",\"\(v.bookTitle)\",\(ISO8601DateFormatter().string(from: v.dateAdded)),\(v.masteryLevel)")
            }
            return lines.joined(separator: "\n")

        case .markdown:
            var md = "# Vocabulary Builder\n\n"
            md += "**\(vocabulary.count) words learned**\n\n"
            for v in vocabulary {
                md += "### \(v.word)\n\n"
                md += "\(v.definition)\n\n"
                if !v.context.isEmpty {
                    md += "> \(v.context)\n\n"
                }
                md += "*From: \(v.bookTitle)*\n\n---\n\n"
            }
            return md
        }
    }

    // MARK: - Everything Export

    private func exportEverything(
        books: [Book],
        highlights: [Highlight],
        bookmarks: [Bookmark],
        sessions: [ReadingSession],
        vocabulary: [VocabularyEntry],
        format: ExportFormat
    ) -> String {
        switch format {
        case .markdown:
            var md = "# Aurora Reader — Full Export\n\n"
            md += "Exported: \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))\n\n"
            md += "---\n\n"
            md += exportLibrary(books: books, format: .markdown) + "\n\n---\n\n"
            md += exportHighlights(highlights: highlights, format: .markdown) + "\n\n---\n\n"
            md += exportBookmarks(bookmarks: bookmarks, format: .markdown) + "\n\n---\n\n"
            md += exportReadingStats(sessions: sessions, books: books, format: .markdown) + "\n\n---\n\n"
            md += exportVocabulary(vocabulary: vocabulary, format: .markdown)
            return md

        case .json:
            return """
            {
            "exportDate": "\(ISO8601DateFormatter().string(from: Date()))",
            "library": \(exportLibrary(books: books, format: .json)),
            "highlights": \(exportHighlights(highlights: highlights, format: .json)),
            "bookmarks": \(exportBookmarks(bookmarks: bookmarks, format: .json)),
            "readingStats": \(exportReadingStats(sessions: sessions, books: books, format: .json)),
            "vocabulary": \(exportVocabulary(vocabulary: vocabulary, format: .json))
            }
            """

        case .csv:
            // CSV can't combine, just export library
            return exportLibrary(books: books, format: .csv)
        }
    }

    // MARK: - Helpers

    private func jsonString(_ entries: [[String: String]]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: entries, options: .prettyPrinted),
              let str = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return str
    }

    private func writeToTempFile(content: String, name: String, extension ext: String) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        let fileName = "\(name)-\(dateStr).\(ext)"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}
