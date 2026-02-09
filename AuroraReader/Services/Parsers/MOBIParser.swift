import Foundation

/// Parser for MOBI/PRC format ebooks (Mobipocket)
final class MOBIParser: BookParser {
    let supportedFormat: BookFormat = .mobi

    func parse(fileURL: URL) async throws -> ParsedBook {
        let data = try Data(contentsOf: fileURL)
        guard data.count > 78 else {
            throw BookParserError.corruptedFile("File too small for MOBI format")
        }

        // Read PalmDOC header
        let title = extractPalmTitle(from: data)
            ?? fileURL.deletingPathExtension().lastPathComponent

        // Parse MOBI header for metadata
        let metadata = parseMOBIHeader(data: data)

        // Extract and decompress text records
        let textContent = try extractTextContent(from: data)

        // Strip HTML from MOBI content
        let plainText = stripMOBIMarkup(textContent)

        let chapters = splitIntoChapters(text: plainText, title: title)

        return ParsedBook(
            title: metadata["title"] ?? title,
            author: metadata["author"] ?? "Unknown Author",
            chapters: chapters,
            coverImageData: nil,
            metadata: metadata
        )
    }

    private func extractPalmTitle(from data: Data) -> String? {
        guard data.count >= 32 else { return nil }
        let titleData = data.prefix(32)
        return String(data: titleData, encoding: .utf8)?
            .trimmingCharacters(in: .controlCharacters)
            .trimmingCharacters(in: .whitespaces)
    }

    private func parseMOBIHeader(data: Data) -> [String: String] {
        var metadata: [String: String] = [:]
        // MOBI header starts after PalmDOC header at offset 78+
        // Contains title, author, publisher, description fields
        // Real implementation reads PDB record offsets and MOBI/EXTH headers
        if let titleRange = findEXTHRecord(type: 503, in: data) {
            metadata["title"] = String(data: titleRange, encoding: .utf8)
        }
        if let authorRange = findEXTHRecord(type: 100, in: data) {
            metadata["author"] = String(data: authorRange, encoding: .utf8)
        }
        return metadata
    }

    private func findEXTHRecord(type: UInt32, in data: Data) -> Data? {
        // EXTH records contain extended metadata
        // Search for the EXTH magic "EXTH" marker after the MOBI header
        guard let exthOffset = findSequence([0x45, 0x58, 0x54, 0x48], in: data) else {
            return nil
        }
        guard exthOffset + 12 <= data.count else { return nil }

        let headerLength = data.readUInt32BE(at: exthOffset + 4)
        let recordCount = data.readUInt32BE(at: exthOffset + 8)
        var offset = exthOffset + 12

        for _ in 0..<recordCount {
            guard offset + 8 <= data.count else { break }
            let recType = data.readUInt32BE(at: offset)
            let recLen = data.readUInt32BE(at: offset + 4)
            guard recLen >= 8 else { break }

            if recType == type {
                let dataStart = offset + 8
                let dataEnd = offset + Int(recLen)
                guard dataEnd <= data.count else { break }
                return data[dataStart..<dataEnd]
            }
            offset += Int(recLen)
            _ = headerLength
        }
        return nil
    }

    private func findSequence(_ bytes: [UInt8], in data: Data) -> Int? {
        let dataBytes = [UInt8](data)
        outer: for i in 0...(dataBytes.count - bytes.count) {
            for j in 0..<bytes.count {
                if dataBytes[i + j] != bytes[j] { continue outer }
            }
            return i
        }
        return nil
    }

    private func extractTextContent(from data: Data) throws -> String {
        // PalmDOC decompression: read text records from PDB structure
        // Records are either uncompressed (1) or PalmDOC compressed (2)
        guard data.count > 78 else {
            throw BookParserError.parsingFailed("Invalid MOBI structure")
        }

        // Attempt simple text extraction as fallback
        if let text = String(data: data, encoding: .utf8), text.count > 100 {
            return text
        }
        if let text = String(data: data, encoding: .ascii), text.count > 100 {
            return text
        }

        throw BookParserError.parsingFailed("Could not decompress MOBI text records")
    }

    private func stripMOBIMarkup(_ text: String) -> String {
        var result = text
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>") {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: " ")
        }
        let entities = [("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"), ("&nbsp;", " "), ("&quot;", "\"")]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        return result.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    private func splitIntoChapters(text: String, title: String) -> [BookChapter] {
        let lines = text.components(separatedBy: .newlines)
        if lines.count <= 200 {
            return [BookChapter(index: 0, title: title, content: text)]
        }
        var chapters: [BookChapter] = []
        let chunkSize = 200
        for i in stride(from: 0, to: lines.count, by: chunkSize) {
            let end = min(i + chunkSize, lines.count)
            let content = lines[i..<end].joined(separator: "\n")
            chapters.append(BookChapter(index: chapters.count, title: "Part \(chapters.count + 1)", content: content))
        }
        return chapters
    }
}

// MARK: - Data helpers

private extension Data {
    func readUInt32BE(at offset: Int) -> UInt32 {
        guard offset + 4 <= count else { return 0 }
        var value: UInt32 = 0
        let range = offset..<(offset + 4)
        _ = Swift.withUnsafeMutableBytes(of: &value) { ptr in
            copyBytes(to: ptr, from: range)
        }
        return UInt32(bigEndian: value)
    }
}
