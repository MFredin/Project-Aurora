import Foundation

/// Parser for plain text (.txt) files
final class PlainTextParser: BookParser {
    let supportedFormat: BookFormat = .plainText

    private let linesPerChapter = 200

    func parse(fileURL: URL) async throws -> ParsedBook {
        // Try multiple encodings
        let encodings: [String.Encoding] = [.utf8, .ascii, .isoLatin1, .windowsCP1252, .utf16]
        var content: String?

        for encoding in encodings {
            if let text = try? String(contentsOf: fileURL, encoding: encoding),
               !text.isEmpty {
                content = text
                break
            }
        }

        guard let text = content else {
            throw BookParserError.parsingFailed("Could not read text file with any supported encoding")
        }

        let title = fileURL.deletingPathExtension().lastPathComponent
        let chapters = splitIntoChapters(text: text, fileName: title)

        guard !chapters.isEmpty else {
            throw BookParserError.parsingFailed("File appears to be empty")
        }

        // Try to extract author from common text file header patterns
        let author = extractAuthor(from: text)

        var metadata: [String: String] = [:]
        metadata["encoding"] = "UTF-8"
        metadata["lineCount"] = "\(text.components(separatedBy: .newlines).count)"

        return ParsedBook(
            title: title,
            author: author ?? "Unknown Author",
            chapters: chapters,
            coverImageData: nil,
            metadata: metadata
        )
    }

    // MARK: - Chapter Splitting

    private func splitIntoChapters(text: String, fileName: String) -> [BookChapter] {
        // First, try to detect chapter markers in the text
        if let markerChapters = splitByChapterMarkers(text: text), !markerChapters.isEmpty {
            return markerChapters
        }

        // Try splitting by double blank lines (common in Project Gutenberg texts)
        if let sectionChapters = splitByBlankLineSections(text: text), !sectionChapters.isEmpty {
            return sectionChapters
        }

        // Fallback: split by line count
        return splitByLineCount(text: text)
    }

    private func splitByChapterMarkers(text: String) -> [BookChapter]? {
        // Common chapter heading patterns
        let patterns = [
            #"(?m)^(?:CHAPTER|Chapter)\s+[\dIVXLCDMivxlcdm]+[.\s]*(.*)$"#,
            #"(?m)^(?:PART|Part)\s+[\dIVXLCDMivxlcdm]+[.\s]*(.*)$"#,
            #"(?m)^(?:BOOK|Book)\s+[\dIVXLCDMivxlcdm]+[.\s]*(.*)$"#,
            #"(?m)^(?:ACT|Act)\s+[\dIVXLCDMivxlcdm]+[.\s]*(.*)$"#,
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

            if matches.count >= 2 {
                return buildChaptersFromMatches(text: text, matches: matches, regex: regex)
            }
        }

        return nil
    }

    private func buildChaptersFromMatches(
        text: String,
        matches: [NSTextCheckingResult],
        regex: NSRegularExpression
    ) -> [BookChapter] {
        var chapters: [BookChapter] = []

        // If there's content before the first chapter marker, include it as a prologue
        if let firstMatch = matches.first,
           let firstRange = Range(firstMatch.range, in: text) {
            let preamble = String(text[text.startIndex..<firstRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if preamble.count > 100 {
                chapters.append(BookChapter(index: 0, title: "Prologue", content: preamble))
            }
        }

        for (i, match) in matches.enumerated() {
            guard let matchRange = Range(match.range, in: text) else { continue }

            let heading = String(text[matchRange]).trimmingCharacters(in: .whitespacesAndNewlines)

            let contentStart = matchRange.upperBound
            let contentEnd: String.Index
            if i + 1 < matches.count,
               let nextRange = Range(matches[i + 1].range, in: text) {
                contentEnd = nextRange.lowerBound
            } else {
                contentEnd = text.endIndex
            }

            let content = String(text[contentStart..<contentEnd])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !content.isEmpty {
                chapters.append(BookChapter(
                    index: chapters.count,
                    title: heading,
                    content: content
                ))
            }
        }

        return chapters
    }

    private func splitByBlankLineSections(text: String) -> [BookChapter]? {
        let sections = text.components(separatedBy: "\n\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Only use this method if there are a reasonable number of sections
        guard sections.count >= 3, sections.count <= 100 else { return nil }

        return sections.enumerated().map { index, content in
            let firstLine = content.components(separatedBy: .newlines).first ?? "Section \(index + 1)"
            let title = firstLine.count <= 80 ? firstLine : "Section \(index + 1)"
            return BookChapter(index: index, title: title, content: content)
        }
    }

    private func splitByLineCount(text: String) -> [BookChapter] {
        let lines = text.components(separatedBy: .newlines)

        if lines.count <= linesPerChapter {
            return [BookChapter(index: 0, title: "Full Text", content: text)]
        }

        var chapters: [BookChapter] = []
        var currentIndex = 0

        while currentIndex < lines.count {
            let endIndex = min(currentIndex + linesPerChapter, lines.count)
            let chapterLines = Array(lines[currentIndex..<endIndex])
            let content = chapterLines.joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !content.isEmpty {
                let chapterNum = chapters.count + 1
                chapters.append(BookChapter(
                    index: chapters.count,
                    title: "Part \(chapterNum)",
                    content: content
                ))
            }

            currentIndex = endIndex
        }

        return chapters
    }

    // MARK: - Metadata Extraction

    private func extractAuthor(from text: String) -> String? {
        let headerLines = text.components(separatedBy: .newlines).prefix(20)
        let header = headerLines.joined(separator: "\n")

        // Common patterns: "by Author Name", "Author: Name"
        let patterns = [
            #"(?i)(?:^|\n)\s*by\s+([A-Z][a-zA-Z\s.'-]+)"#,
            #"(?i)(?:^|\n)\s*author:\s*([A-Z][a-zA-Z\s.'-]+)"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: header, range: NSRange(header.startIndex..., in: header)),
               let range = Range(match.range(at: 1), in: header) {
                let author = String(header[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if author.count >= 3, author.count <= 100 {
                    return author
                }
            }
        }

        return nil
    }
}
