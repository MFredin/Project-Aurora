import Foundation

/// Parser for EPUB format ebooks
/// EPUB files are ZIP archives containing XHTML content, metadata, and resources
final class EPUBParser: BookParser {
    let supportedFormat: BookFormat = .epub

    func parse(fileURL: URL) async throws -> ParsedBook {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("epub_\(UUID().uuidString)")

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        try extractEPUB(at: fileURL, to: tempDir)

        let containerXML = tempDir.appendingPathComponent("META-INF/container.xml")
        guard FileManager.default.fileExists(atPath: containerXML.path) else {
            throw BookParserError.invalidFormat("Missing META-INF/container.xml")
        }

        let rootFilePath = try parseContainerXML(at: containerXML)
        let contentDir = tempDir.appendingPathComponent(rootFilePath).deletingLastPathComponent()
        let opfURL = tempDir.appendingPathComponent(rootFilePath)

        let opfData = try parseOPF(at: opfURL)

        var coverImageData: Data?
        if let coverHref = opfData.coverImageHref {
            let coverURL = contentDir.appendingPathComponent(coverHref)
            coverImageData = try? Data(contentsOf: coverURL)
        }

        var chapters: [BookChapter] = []
        for (index, spineItem) in opfData.spineItems.enumerated() {
            let chapterURL = contentDir.appendingPathComponent(spineItem.href)
            if let chapterContent = try? String(contentsOf: chapterURL, encoding: .utf8) {
                let plainText = stripHTML(chapterContent)
                let title = spineItem.title ?? extractTitleFromHTML(chapterContent) ?? "Chapter \(index + 1)"
                if !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    chapters.append(BookChapter(index: index, title: title, content: plainText))
                }
            }
        }

        if chapters.isEmpty {
            throw BookParserError.parsingFailed("No readable content found in EPUB")
        }

        return ParsedBook(
            title: opfData.title ?? fileURL.deletingPathExtension().lastPathComponent,
            author: opfData.author ?? "Unknown Author",
            chapters: chapters,
            coverImageData: coverImageData,
            metadata: opfData.metadata
        )
    }

    // MARK: - EPUB Extraction

    private func extractEPUB(at sourceURL: URL, to destinationURL: URL) throws {
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)

        // EPUB files are ZIP archives - use built-in archive support
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", "-q", sourceURL.path, "-d", destinationURL.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            // Fallback: try to read as ZIP using Foundation
            try extractEPUBFallback(at: sourceURL, to: destinationURL)
        }
    }

    private func extractEPUBFallback(at sourceURL: URL, to destinationURL: URL) throws {
        // Basic ZIP extraction using FileManager
        let data = try Data(contentsOf: sourceURL)
        guard data.count > 4 else {
            throw BookParserError.corruptedFile("File too small to be a valid EPUB")
        }

        // Check for ZIP magic bytes (PK\x03\x04)
        let magic = data.prefix(4)
        guard magic[magic.startIndex] == 0x50,
              magic[magic.startIndex + 1] == 0x4B else {
            throw BookParserError.invalidFormat("File is not a valid EPUB (ZIP) archive")
        }

        throw BookParserError.parsingFailed("ZIP extraction requires system unzip utility")
    }

    // MARK: - XML Parsing

    private func parseContainerXML(at url: URL) throws -> String {
        let content = try String(contentsOf: url, encoding: .utf8)

        // Extract rootfile full-path attribute
        guard let rootfileRange = content.range(of: "full-path=\""),
              let endQuote = content[rootfileRange.upperBound...].range(of: "\"") else {
            throw BookParserError.invalidFormat("Cannot find rootfile path in container.xml")
        }

        return String(content[rootfileRange.upperBound..<endQuote.lowerBound])
    }

    private func parseOPF(at url: URL) throws -> OPFData {
        let content = try String(contentsOf: url, encoding: .utf8)

        let title = extractXMLElement(named: "dc:title", from: content)
            ?? extractXMLElement(named: "title", from: content)
        let author = extractXMLElement(named: "dc:creator", from: content)
            ?? extractXMLElement(named: "creator", from: content)
        let language = extractXMLElement(named: "dc:language", from: content)
        let publisher = extractXMLElement(named: "dc:publisher", from: content)

        var metadata: [String: String] = [:]
        if let language { metadata["language"] = language }
        if let publisher { metadata["publisher"] = publisher }

        // Parse manifest items
        var manifestItems: [String: ManifestItem] = [:]
        let manifestPattern = #"<item\s+[^>]*id="([^"]*)"[^>]*href="([^"]*)"[^>]*media-type="([^"]*)"[^>]*/?\s*>"#
        let altPattern = #"<item\s+[^>]*href="([^"]*)"[^>]*id="([^"]*)"[^>]*media-type="([^"]*)"[^>]*/?\s*>"#

        if let regex = try? NSRegularExpression(pattern: manifestPattern) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
            for match in matches {
                if let idRange = Range(match.range(at: 1), in: content),
                   let hrefRange = Range(match.range(at: 2), in: content),
                   let typeRange = Range(match.range(at: 3), in: content) {
                    let id = String(content[idRange])
                    let href = String(content[hrefRange]).removingPercentEncoding ?? String(content[hrefRange])
                    let mediaType = String(content[typeRange])
                    manifestItems[id] = ManifestItem(id: id, href: href, mediaType: mediaType)
                }
            }
        }

        if let regex = try? NSRegularExpression(pattern: altPattern) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
            for match in matches {
                if let hrefRange = Range(match.range(at: 1), in: content),
                   let idRange = Range(match.range(at: 2), in: content),
                   let typeRange = Range(match.range(at: 3), in: content) {
                    let id = String(content[idRange])
                    let href = String(content[hrefRange]).removingPercentEncoding ?? String(content[hrefRange])
                    let mediaType = String(content[typeRange])
                    if manifestItems[id] == nil {
                        manifestItems[id] = ManifestItem(id: id, href: href, mediaType: mediaType)
                    }
                }
            }
        }

        // Parse spine
        var spineItemRefs: [String] = []
        let spinePattern = #"<itemref\s+[^>]*idref="([^"]*)"[^>]*/?\s*>"#
        if let regex = try? NSRegularExpression(pattern: spinePattern) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
            for match in matches {
                if let idRange = Range(match.range(at: 1), in: content) {
                    spineItemRefs.append(String(content[idRange]))
                }
            }
        }

        // Build spine items from manifest
        let spineItems: [SpineItem] = spineItemRefs.compactMap { idref in
            guard let manifest = manifestItems[idref] else { return nil }
            return SpineItem(href: manifest.href, title: nil)
        }

        // Find cover image
        var coverImageHref: String?
        let coverMeta = #"<meta\s+[^>]*name="cover"[^>]*content="([^"]*)"[^>]*/?\s*>"#
        if let regex = try? NSRegularExpression(pattern: coverMeta),
           let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
           let range = Range(match.range(at: 1), in: content) {
            let coverId = String(content[range])
            coverImageHref = manifestItems[coverId]?.href
        }

        if coverImageHref == nil {
            coverImageHref = manifestItems.values
                .first { $0.mediaType.starts(with: "image/") && $0.id.lowercased().contains("cover") }?
                .href
        }

        return OPFData(
            title: title,
            author: author,
            coverImageHref: coverImageHref,
            spineItems: spineItems,
            metadata: metadata
        )
    }

    // MARK: - HTML Processing

    private func stripHTML(_ html: String) -> String {
        var text = html

        // Remove script and style blocks
        let blockPatterns = [
            #"<script[^>]*>[\s\S]*?</script>"#,
            #"<style[^>]*>[\s\S]*?</style>"#
        ]
        for pattern in blockPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
            }
        }

        // Replace block elements with newlines
        let blockElements = ["</p>", "</div>", "</h1>", "</h2>", "</h3>", "</h4>", "</h5>", "</h6>", "<br", "</li>", "</tr>"]
        for element in blockElements {
            text = text.replacingOccurrences(of: element, with: "\n", options: .caseInsensitive)
        }

        // Remove all remaining HTML tags
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>") {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }

        // Decode common HTML entities
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&apos;", "'"), ("&#39;", "'"),
            ("&nbsp;", " "), ("&mdash;", "—"), ("&ndash;", "–"),
            ("&lsquo;", "\u{2018}"), ("&rsquo;", "\u{2019}"),
            ("&ldquo;", "\u{201C}"), ("&rdquo;", "\u{201D}"),
            ("&hellip;", "…")
        ]
        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }

        // Decode numeric entities
        if let regex = try? NSRegularExpression(pattern: #"&#(\d+);"#) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches.reversed() {
                if let range = Range(match.range, in: text),
                   let numRange = Range(match.range(at: 1), in: text),
                   let code = UInt32(text[numRange]),
                   let scalar = Unicode.Scalar(code) {
                    text.replaceSubrange(range, with: String(scalar))
                }
            }
        }

        // Clean up whitespace
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return lines.joined(separator: "\n\n")
    }

    private func extractTitleFromHTML(_ html: String) -> String? {
        let titlePatterns = [
            #"<title[^>]*>(.*?)</title>"#,
            #"<h1[^>]*>(.*?)</h1>"#,
            #"<h2[^>]*>(.*?)</h2>"#
        ]

        for pattern in titlePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let title = stripHTML(String(html[range])).trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty { return title }
            }
        }

        return nil
    }

    private func extractXMLElement(named name: String, from xml: String) -> String? {
        let pattern = "<\(NSRegularExpression.escapedPattern(for: name))[^>]*>(.*?)</\(NSRegularExpression.escapedPattern(for: name))>"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
           let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
           let range = Range(match.range(at: 1), in: xml) {
            return String(xml[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
}

// MARK: - Supporting Types

private struct ManifestItem {
    let id: String
    let href: String
    let mediaType: String
}

private struct SpineItem {
    let href: String
    let title: String?
}

private struct OPFData {
    let title: String?
    let author: String?
    let coverImageHref: String?
    let spineItems: [SpineItem]
    let metadata: [String: String]
}
