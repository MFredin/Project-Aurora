import Foundation

/// Hybrid book formatting service: rule-based quick fixes + Claude API deep clean
@Observable
final class BookFormattingService {
    static let shared = BookFormattingService()

    var isProcessing = false
    var progress: Double = 0
    var lastResult: FormattingResult?

    private init() {}

    // MARK: - Quick Clean (Rule-Based, Offline)

    /// Applies rule-based formatting fixes — fast, offline, no API needed
    func quickClean(_ text: String) -> FormattingResult {
        var cleaned = text
        var fixes: [FormattingFix] = []

        let encodingFixes = fixEncodingArtifacts(&cleaned)
        fixes.append(contentsOf: encodingFixes)

        let whitespaceFixes = normalizeWhitespace(&cleaned)
        fixes.append(contentsOf: whitespaceFixes)

        let paragraphFixes = fixBrokenParagraphs(&cleaned)
        fixes.append(contentsOf: paragraphFixes)

        let quoteFixes = fixQuotesAndDashes(&cleaned)
        fixes.append(contentsOf: quoteFixes)

        let strayFixes = removeStrayArtifacts(&cleaned)
        fixes.append(contentsOf: strayFixes)

        let spaceFixes = normalizeSpacingAfterPunctuation(&cleaned)
        fixes.append(contentsOf: spaceFixes)

        return FormattingResult(
            originalText: text,
            cleanedText: cleaned,
            fixes: fixes,
            method: .ruleBased
        )
    }

    // MARK: - Deep Clean (Claude API)

    /// Uses Claude API for context-aware formatting fixes
    func deepClean(_ text: String, chapterTitle: String = "") async throws -> FormattingResult {
        isProcessing = true
        progress = 0
        defer {
            isProcessing = false
            progress = 0
        }

        // First apply rule-based fixes
        let quickResult = quickClean(text)
        progress = 0.3

        let system = """
        You are a book formatting specialist. Fix ONLY structural formatting issues \
        in ebook text while preserving the author's original writing exactly.

        Fix these issues:
        - Broken paragraphs (lines that end mid-sentence from bad OCR or conversion)
        - Misplaced page numbers, running headers, or footers embedded in text
        - Encoding artifacts or garbled characters
        - Inconsistent paragraph spacing
        - Chapter heading formatting inconsistencies

        NEVER change the author's words, style, or meaning. Only fix structural problems.
        Return the corrected text directly with no explanation or preamble.
        """

        let prompt: String
        if chapterTitle.isEmpty {
            prompt = "Fix the formatting issues in this ebook text:\n\n\(String(quickResult.cleanedText.prefix(12000)))"
        } else {
            prompt = "Fix the formatting issues in this chapter titled \"\(chapterTitle)\":\n\n\(String(quickResult.cleanedText.prefix(12000)))"
        }

        progress = 0.5

        let result = try await ClaudeAPIClient.shared.sendMessage(
            system: system,
            userMessage: prompt,
            maxTokens: 8192
        )

        progress = 0.9

        var allFixes = quickResult.fixes
        if result != quickResult.cleanedText {
            allFixes.append(FormattingFix(
                type: .aiRefinement,
                description: "AI-powered formatting refinement applied",
                count: 1
            ))
        }

        progress = 1.0

        let finalResult = FormattingResult(
            originalText: text,
            cleanedText: result,
            fixes: allFixes,
            method: .claudeAI
        )
        lastResult = finalResult
        return finalResult
    }

    /// Cleans all chapters of a book, applying quick or deep clean
    func cleanBook(chapters: [BookChapter], deep: Bool = false) async -> [FormattingResult] {
        isProcessing = true
        defer {
            isProcessing = false
            progress = 0
        }

        var results: [FormattingResult] = []
        let total = Double(chapters.count)

        for (index, chapter) in chapters.enumerated() {
            progress = Double(index) / total

            if deep {
                if let result = try? await deepClean(chapter.content, chapterTitle: chapter.title) {
                    results.append(result)
                }
            } else {
                results.append(quickClean(chapter.content))
            }
        }

        progress = 1.0
        return results
    }

    // MARK: - Rule-Based Fixers

    private func fixEncodingArtifacts(_ text: inout String) -> [FormattingFix] {
        let replacements: [(String, String)] = [
            // UTF-8 decoded as Latin-1 (mojibake)
            ("\u{00E2}\u{0080}\u{0099}", "\u{2019}"), // '
            ("\u{00E2}\u{0080}\u{0098}", "\u{2018}"), // '
            ("\u{00E2}\u{0080}\u{009C}", "\u{201C}"), // "
            ("\u{00E2}\u{0080}\u{009D}", "\u{201D}"), // "
            ("\u{00E2}\u{0080}\u{0094}", "\u{2014}"), // —
            ("\u{00E2}\u{0080}\u{0093}", "\u{2013}"), // –
            ("\u{00E2}\u{0080}\u{00A6}", "\u{2026}"), // …
            // Common Latin mojibake
            ("\u{00C3}\u{00A9}", "\u{00E9}"),         // é
            ("\u{00C3}\u{00A8}", "\u{00E8}"),         // è
            ("\u{00C3}\u{00B1}", "\u{00F1}"),         // ñ
            ("\u{00C3}\u{00B6}", "\u{00F6}"),         // ö
            ("\u{00C3}\u{00BC}", "\u{00FC}"),         // ü
            ("\u{00C3}\u{00A4}", "\u{00E4}"),         // ä
            // BOM and invisible characters
            ("\u{FEFF}", ""),
            ("\u{00EF}\u{00BB}\u{00BF}", ""),         // UTF-8 BOM as mojibake
            ("\u{00A0}", " "),                         // Non-breaking space
        ]

        var totalCount = 0
        for (bad, good) in replacements {
            let count = text.components(separatedBy: bad).count - 1
            if count > 0 {
                text = text.replacingOccurrences(of: bad, with: good)
                totalCount += count
            }
        }

        guard totalCount > 0 else { return [] }
        return [FormattingFix(type: .encodingArtifact, description: "Fixed encoding artifacts", count: totalCount)]
    }

    private func normalizeWhitespace(_ text: inout String) -> [FormattingFix] {
        let original = text

        // Replace multiple spaces with single space
        while text.contains("  ") {
            text = text.replacingOccurrences(of: "  ", with: " ")
        }

        // Replace 3+ consecutive newlines with 2
        if let regex = try? NSRegularExpression(pattern: "\\n{3,}") {
            text = regex.stringByReplacingMatches(
                in: text, range: NSRange(text.startIndex..., in: text),
                withTemplate: "\n\n"
            )
        }

        // Trim trailing whitespace on each line
        let lines = text.components(separatedBy: "\n")
        text = lines.map { $0.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) }
            .joined(separator: "\n")

        guard text != original else { return [] }
        return [FormattingFix(type: .whitespace, description: "Normalized whitespace", count: 1)]
    }

    private func fixBrokenParagraphs(_ text: inout String) -> [FormattingFix] {
        let lines = text.components(separatedBy: "\n")
        var result: [String] = []
        var fixCount = 0

        var i = 0
        while i < lines.count {
            var line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Join lines that end mid-sentence with the next line if it starts lowercase
            while i + 1 < lines.count {
                let nextLine = lines[i + 1].trimmingCharacters(in: .whitespaces)

                guard !trimmed.isEmpty,
                      !nextLine.isEmpty,
                      let lastChar = trimmed.last,
                      !".!?:;\"\u{2019}\u{201D})".contains(lastChar),
                      let firstNext = nextLine.first,
                      firstNext.isLowercase else {
                    break
                }

                line += " " + nextLine
                fixCount += 1
                i += 1
            }

            result.append(line)
            i += 1
        }

        text = result.joined(separator: "\n")

        guard fixCount > 0 else { return [] }
        return [FormattingFix(type: .brokenParagraph, description: "Rejoined broken paragraphs", count: fixCount)]
    }

    private func fixQuotesAndDashes(_ text: inout String) -> [FormattingFix] {
        let original = text

        // Double-hyphen to em dash
        text = text.replacingOccurrences(of: "--", with: "\u{2014}")
        // Space-hyphen-space to em dash
        text = text.replacingOccurrences(of: " - ", with: " \u{2014} ")

        guard text != original else { return [] }
        return [FormattingFix(type: .punctuation, description: "Fixed dashes and punctuation", count: 1)]
    }

    private func removeStrayArtifacts(_ text: inout String) -> [FormattingFix] {
        var fixCount = 0

        let lines = text.components(separatedBy: "\n")
        let cleanedLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Remove lines that are just a number (stray page numbers)
            if let _ = Int(trimmed), trimmed.count <= 4, !trimmed.isEmpty {
                fixCount += 1
                return false
            }

            // Remove "Page N" patterns
            if trimmed.hasPrefix("Page ") && trimmed.count < 15 {
                let rest = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
                if let _ = Int(rest) {
                    fixCount += 1
                    return false
                }
            }

            return true
        }

        text = cleanedLines.joined(separator: "\n")

        guard fixCount > 0 else { return [] }
        return [FormattingFix(type: .strayArtifact, description: "Removed stray page numbers/headers", count: fixCount)]
    }

    private func normalizeSpacingAfterPunctuation(_ text: inout String) -> [FormattingFix] {
        let original = text

        // Double spaces after sentence-ending punctuation to single
        text = text.replacingOccurrences(of: ".  ", with: ". ")
        text = text.replacingOccurrences(of: "?  ", with: "? ")
        text = text.replacingOccurrences(of: "!  ", with: "! ")

        // Missing space after period before uppercase (e.g., "word.The" → "word. The")
        if let regex = try? NSRegularExpression(pattern: "\\.([A-Z])") {
            text = regex.stringByReplacingMatches(
                in: text, range: NSRange(text.startIndex..., in: text),
                withTemplate: ". $1"
            )
        }

        guard text != original else { return [] }
        return [FormattingFix(type: .spacing, description: "Normalized punctuation spacing", count: 1)]
    }
}

// MARK: - Supporting Types

struct FormattingResult: Identifiable {
    let id = UUID()
    let originalText: String
    let cleanedText: String
    let fixes: [FormattingFix]
    let method: CleanMethod

    var totalFixCount: Int { fixes.reduce(0) { $0 + $1.count } }
    var hasChanges: Bool { originalText != cleanedText }

    enum CleanMethod: String {
        case ruleBased = "Quick Clean"
        case claudeAI = "AI Deep Clean"
    }
}

struct FormattingFix: Identifiable {
    let id = UUID()
    let type: FixType
    let description: String
    let count: Int

    enum FixType: String {
        case encodingArtifact = "Encoding"
        case whitespace = "Whitespace"
        case brokenParagraph = "Paragraphs"
        case punctuation = "Punctuation"
        case strayArtifact = "Artifacts"
        case spacing = "Spacing"
        case aiRefinement = "AI Refinement"

        var iconName: String {
            switch self {
            case .encodingArtifact: return "character.textbox"
            case .whitespace: return "space"
            case .brokenParagraph: return "text.alignleft"
            case .punctuation: return "textformat.abc"
            case .strayArtifact: return "trash"
            case .spacing: return "ruler"
            case .aiRefinement: return "sparkles"
            }
        }
    }
}
