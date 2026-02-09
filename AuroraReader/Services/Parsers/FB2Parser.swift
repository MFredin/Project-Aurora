import Foundation

/// Parser for FictionBook 2 (FB2) XML format
final class FB2Parser: BookParser {
    let supportedFormat: BookFormat = .fb2

    func parse(fileURL: URL) async throws -> ParsedBook {
        let data = try Data(contentsOf: fileURL)
        guard let content = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .windowsCP1251) else {
            throw BookParserError.parsingFailed("Could not read FB2 file encoding")
        }

        // Extract metadata from <description><title-info>
        let title = extractElement("book-title", from: content)
            ?? fileURL.deletingPathExtension().lastPathComponent
        let authorFirst = extractElement("first-name", from: content) ?? ""
        let authorLast = extractElement("last-name", from: content) ?? ""
        let author = [authorFirst, authorLast].filter { !$0.isEmpty }.joined(separator: " ")

        var metadata: [String: String] = [:]
        if let genre = extractElement("genre", from: content) { metadata["genre"] = genre }
        if let lang = extractElement("lang", from: content) { metadata["language"] = lang }
        if let annotation = extractElement("annotation", from: content) {
            metadata["description"] = stripXML(annotation)
        }

        // Extract cover image from <binary> with cover id
        let coverData = extractCoverImage(from: content)

        // Parse <body> sections
        let chapters = extractChapters(from: content)

        guard !chapters.isEmpty else {
            throw BookParserError.parsingFailed("No readable content in FB2 file")
        }

        return ParsedBook(
            title: title,
            author: author.isEmpty ? "Unknown Author" : author,
            chapters: chapters,
            coverImageData: coverData,
            metadata: metadata
        )
    }

    private func extractElement(_ name: String, from xml: String) -> String? {
        let pattern = "<\(NSRegularExpression.escapedPattern(for: name))[^>]*>(.*?)</\(NSRegularExpression.escapedPattern(for: name))>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
              let range = Range(match.range(at: 1), in: xml) else { return nil }
        return String(xml[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractChapters(from xml: String) -> [BookChapter] {
        // Find <section> blocks within <body>
        let sectionPattern = #"<section[^>]*>([\s\S]*?)</section>"#
        guard let regex = try? NSRegularExpression(pattern: sectionPattern, options: .caseInsensitive) else {
            return extractFallbackChapters(from: xml)
        }

        let matches = regex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))
        if matches.isEmpty { return extractFallbackChapters(from: xml) }

        var chapters: [BookChapter] = []
        for (index, match) in matches.enumerated() {
            guard let range = Range(match.range(at: 1), in: xml) else { continue }
            let sectionXML = String(xml[range])

            let title = extractElement("title", from: sectionXML).map { stripXML($0) }
                ?? "Chapter \(index + 1)"
            let text = stripXML(sectionXML)

            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                chapters.append(BookChapter(index: index, title: title, content: text))
            }
        }
        return chapters
    }

    private func extractFallbackChapters(from xml: String) -> [BookChapter] {
        // Extract all text from <body>
        guard let bodyContent = extractElement("body", from: xml) else { return [] }
        let text = stripXML(bodyContent)
        guard !text.isEmpty else { return [] }
        return [BookChapter(index: 0, title: "Full Text", content: text)]
    }

    private func extractCoverImage(from xml: String) -> Data? {
        // FB2 stores images as base64 in <binary> tags
        let pattern = #"<binary[^>]*id="cover[^"]*"[^>]*>([\s\S]*?)</binary>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
              let range = Range(match.range(at: 1), in: xml) else { return nil }
        let base64 = String(xml[range])
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Data(base64Encoded: base64)
    }

    private func stripXML(_ xml: String) -> String {
        var text = xml
        if let regex = try? NSRegularExpression(pattern: "</p>|</v>|<empty-line[^/]*/?>", options: .caseInsensitive) {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "\n")
        }
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>") {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }
        return text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}
