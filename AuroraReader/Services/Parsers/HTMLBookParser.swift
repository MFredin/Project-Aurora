import Foundation

/// Parser for HTML/XHTML book files
final class HTMLBookParser: BookParser {
    let supportedFormat: BookFormat = .htmlBook

    func parse(fileURL: URL) async throws -> ParsedBook {
        let data = try Data(contentsOf: fileURL)
        guard let html = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1) else {
            throw BookParserError.parsingFailed("Could not read HTML file")
        }

        let title = extractTitle(from: html) ?? fileURL.deletingPathExtension().lastPathComponent
        let author = extractMetaContent("author", from: html) ?? "Unknown Author"

        var metadata: [String: String] = ["format": "HTML"]
        if let desc = extractMetaContent("description", from: html) {
            metadata["description"] = desc
        }

        let chapters = extractChapters(from: html)

        guard !chapters.isEmpty else {
            throw BookParserError.parsingFailed("No readable content in HTML")
        }

        return ParsedBook(
            title: title,
            author: author,
            chapters: chapters,
            coverImageData: nil,
            metadata: metadata
        )
    }

    private func extractTitle(from html: String) -> String? {
        let pattern = #"<title[^>]*>(.*?)</title>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else { return nil }
        return stripHTML(String(html[range])).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractMetaContent(_ name: String, from html: String) -> String? {
        let pattern = #"<meta[^>]*name="\#(name)"[^>]*content="([^"]*)"[^>]*/?>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else { return nil }
        return String(html[range])
    }

    private func extractChapters(from html: String) -> [BookChapter] {
        // Try splitting by <h1>, <h2>, or <article> tags
        let headingPattern = #"<h[12][^>]*>(.*?)</h[12]>"#
        if let regex = try? NSRegularExpression(pattern: headingPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            if matches.count >= 2 {
                return buildChaptersFromHeadings(html: html, matches: matches)
            }
        }

        // Fallback: extract body content as one chapter
        let bodyPattern = #"<body[^>]*>([\s\S]*)</body>"#
        let content: String
        if let regex = try? NSRegularExpression(pattern: bodyPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            content = stripHTML(String(html[range]))
        } else {
            content = stripHTML(html)
        }

        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return [BookChapter(index: 0, title: "Full Document", content: content)]
    }

    private func buildChaptersFromHeadings(html: String, matches: [NSTextCheckingResult]) -> [BookChapter] {
        var chapters: [BookChapter] = []
        for (i, match) in matches.enumerated() {
            guard let titleRange = Range(match.range(at: 1), in: html),
                  let fullRange = Range(match.range, in: html) else { continue }

            let title = stripHTML(String(html[titleRange]))
            let contentStart = fullRange.upperBound
            let contentEnd: String.Index
            if i + 1 < matches.count, let nextRange = Range(matches[i + 1].range, in: html) {
                contentEnd = nextRange.lowerBound
            } else {
                contentEnd = html.endIndex
            }

            let content = stripHTML(String(html[contentStart..<contentEnd]))
            if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                chapters.append(BookChapter(index: chapters.count, title: title, content: content))
            }
        }
        return chapters
    }

    private func stripHTML(_ html: String) -> String {
        var text = html
        let blockEnds = ["</p>", "</div>", "</h1>", "</h2>", "</h3>", "</h4>", "</h5>", "</h6>", "<br>", "<br/>", "<br />", "</li>"]
        for tag in blockEnds {
            text = text.replacingOccurrences(of: tag, with: "\n", options: .caseInsensitive)
        }
        if let regex = try? NSRegularExpression(pattern: "<style[^>]*>[\\s\\S]*?</style>", options: .caseInsensitive) {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }
        if let regex = try? NSRegularExpression(pattern: "<script[^>]*>[\\s\\S]*?</script>", options: .caseInsensitive) {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>") {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }
        let entities = [("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"), ("&nbsp;", " "), ("&quot;", "\""), ("&mdash;", "\u{2014}"), ("&ndash;", "\u{2013}")]
        for (e, c) in entities { text = text.replacingOccurrences(of: e, with: c) }
        return text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}
