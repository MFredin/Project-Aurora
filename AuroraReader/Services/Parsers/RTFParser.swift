import Foundation

/// Parser for RTF (Rich Text Format) files
final class RTFParser: BookParser {
    let supportedFormat: BookFormat = .rtf

    func parse(fileURL: URL) async throws -> ParsedBook {
        let data = try Data(contentsOf: fileURL)

        // Use NSAttributedString to parse RTF
        guard let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else {
            throw BookParserError.parsingFailed("Could not parse RTF document")
        }

        let text = attributed.string
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BookParserError.parsingFailed("RTF document is empty")
        }

        let title = fileURL.deletingPathExtension().lastPathComponent
        let chapters = splitIntoChapters(text: text)

        return ParsedBook(
            title: title,
            author: "Unknown Author",
            chapters: chapters,
            coverImageData: nil,
            metadata: ["format": "RTF"]
        )
    }

    private func splitIntoChapters(text: String) -> [BookChapter] {
        let lines = text.components(separatedBy: .newlines)
        if lines.count <= 200 {
            return [BookChapter(index: 0, title: "Full Document", content: text)]
        }

        var chapters: [BookChapter] = []
        let chunkSize = 200
        for i in stride(from: 0, to: lines.count, by: chunkSize) {
            let end = min(i + chunkSize, lines.count)
            let content = lines[i..<end].joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                chapters.append(BookChapter(index: chapters.count, title: "Part \(chapters.count + 1)", content: content))
            }
        }
        return chapters
    }
}
