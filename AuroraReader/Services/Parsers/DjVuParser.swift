import Foundation

/// Parser for DjVu scanned document format
final class DjVuParser: BookParser {
    let supportedFormat: BookFormat = .djvu

    func parse(fileURL: URL) async throws -> ParsedBook {
        let data = try Data(contentsOf: fileURL)

        // Verify DjVu magic bytes: "AT&T"
        guard data.count > 8 else {
            throw BookParserError.corruptedFile("File too small for DjVu format")
        }

        let magic = String(data: data.prefix(4), encoding: .ascii)
        guard magic == "AT&T" else {
            throw BookParserError.invalidFormat("Not a valid DjVu file")
        }

        let title = fileURL.deletingPathExtension().lastPathComponent

        // DjVu text layer extraction
        // DjVu files contain an optional hidden text layer alongside the scanned images
        let textContent = extractTextLayer(from: data)

        let chapters: [BookChapter]
        if let text = textContent, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            chapters = splitIntoChapters(text: text)
        } else {
            // No text layer - create placeholder chapters based on page count
            let pageCount = estimatePageCount(from: data)
            chapters = (0..<max(1, pageCount)).map { i in
                BookChapter(index: i, title: "Page \(i + 1)", content: "[Scanned page \(i + 1) - OCR text not available]")
            }
        }

        return ParsedBook(
            title: title,
            author: "Unknown Author",
            chapters: chapters,
            coverImageData: nil,
            metadata: ["format": "DjVu"]
        )
    }

    private func extractTextLayer(from data: Data) -> String? {
        // DjVu stores text in TXTz/TXTa chunks within the IFF structure
        // Search for text chunk markers
        let bytes = [UInt8](data)
        guard let txtOffset = findChunk(named: "TXTz", in: bytes)
                ?? findChunk(named: "TXTa", in: bytes) else {
            return nil
        }

        let start = txtOffset + 8 // skip chunk header
        guard start < bytes.count else { return nil }
        let textData = Data(bytes[start..<min(start + 50000, bytes.count)])
        return String(data: textData, encoding: .utf8)
    }

    private func findChunk(named name: String, in bytes: [UInt8]) -> Int? {
        let target = Array(name.utf8)
        guard target.count == 4 else { return nil }
        for i in 0...(bytes.count - 4) {
            if bytes[i] == target[0] && bytes[i+1] == target[1]
                && bytes[i+2] == target[2] && bytes[i+3] == target[3] {
                return i
            }
        }
        return nil
    }

    private func estimatePageCount(from data: Data) -> Int {
        // Count DIRM or FORM:DJVU chunks to estimate pages
        let bytes = [UInt8](data)
        var count = 0
        let marker: [UInt8] = Array("DJVU".utf8)
        for i in 0...(max(0, bytes.count - 4)) {
            if bytes[i] == marker[0] && bytes[i+1] == marker[1]
                && bytes[i+2] == marker[2] && bytes[i+3] == marker[3] {
                count += 1
            }
        }
        return max(1, count)
    }

    private func splitIntoChapters(text: String) -> [BookChapter] {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if lines.count <= 200 {
            return [BookChapter(index: 0, title: "Full Document", content: lines.joined(separator: "\n\n"))]
        }
        var chapters: [BookChapter] = []
        for i in stride(from: 0, to: lines.count, by: 200) {
            let end = min(i + 200, lines.count)
            let content = lines[i..<end].joined(separator: "\n")
            chapters.append(BookChapter(index: chapters.count, title: "Part \(chapters.count + 1)", content: content))
        }
        return chapters
    }
}
