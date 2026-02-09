import Foundation
import SwiftData

/// AI-powered reading companion providing summaries, character maps, vocab, and Q&A
@MainActor @Observable
final class AICompanionService {
    static let shared = AICompanionService()

    var isProcessing: Bool = false

    private init() {}

    // MARK: - Reading Recap

    /// Generates a "where you left off" recap based on reading progress
    func generateRecap(
        book: Book,
        chapters: [BookChapter],
        currentChapter: Int
    ) -> ReadingRecap {
        let chaptersRead = Array(chapters.prefix(currentChapter + 1))
        let lastChapter = chaptersRead.last

        // Extract key info from recent chapters
        let recentContent = chaptersRead.suffix(3).map(\.content).joined(separator: " ")
        let characters = extractCharacters(from: recentContent)
        let recentEvents = extractKeyEvents(from: lastChapter?.content ?? "")

        return ReadingRecap(
            bookTitle: book.title,
            currentChapter: currentChapter,
            chapterTitle: lastChapter?.title ?? "",
            summary: buildRecapSummary(chapters: chaptersRead),
            keyCharacters: characters,
            recentEvents: recentEvents,
            readingProgress: Double(currentChapter + 1) / Double(max(chapters.count, 1)),
            estimatedTimeToFinish: estimateRemainingTime(
                chaptersRead: currentChapter + 1,
                totalChapters: chapters.count
            )
        )
    }

    // MARK: - Character Map

    /// Builds a character map from the book's content
    func buildCharacterMap(chapters: [BookChapter]) -> [CharacterInfo] {
        var characterMentions: [String: Int] = [:]
        var characterContexts: [String: [String]] = [:]

        for chapter in chapters {
            let words = chapter.content.components(separatedBy: .whitespacesAndNewlines)
            let sentences = chapter.content.components(separatedBy: ". ")

            // Find capitalized words that appear multiple times (likely character names)
            for word in words {
                let cleaned = word.trimmingCharacters(in: .punctuationCharacters)
                guard cleaned.count > 2,
                      let first = cleaned.first,
                      first.isUppercase,
                      !commonWords.contains(cleaned.lowercased()) else { continue }

                characterMentions[cleaned, default: 0] += 1
            }

            // Collect context sentences for frequent names
            for (name, count) in characterMentions where count >= 3 {
                for sentence in sentences where sentence.contains(name) {
                    let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.count < 200 {
                        characterContexts[name, default: []].append(trimmed)
                    }
                }
            }
        }

        return characterMentions
            .filter { $0.value >= 3 }
            .sorted { $0.value > $1.value }
            .prefix(20)
            .map { name, mentions in
                let contexts = Array((characterContexts[name] ?? []).prefix(3))
                return CharacterInfo(
                    name: name,
                    mentionCount: mentions,
                    contextSnippets: contexts,
                    firstAppearanceChapter: findFirstAppearance(of: name, in: chapters)
                )
            }
    }

    // MARK: - Vocabulary Analysis

    /// Finds uncommon/interesting words in the text
    func extractVocabulary(from chapter: BookChapter) -> [VocabSuggestion] {
        let words = chapter.content
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
            .filter { $0.count > 6 && !commonWords.contains($0) }

        let wordCounts = Dictionary(grouping: words, by: { $0 }).mapValues(\.count)

        return wordCounts
            .filter { $0.value >= 1 && $0.key.count > 6 }
            .sorted { $0.key < $1.key }
            .prefix(15)
            .map { word, count in
                let context = findContext(for: word, in: chapter.content)
                return VocabSuggestion(
                    word: word,
                    context: context,
                    frequency: count,
                    chapterTitle: chapter.title
                )
            }
    }

    // MARK: - Q&A / Chat

    /// Processes a question about the book content (keyword-based fallback)
    func answerQuestion(
        question: String,
        chapters: [BookChapter],
        currentChapter: Int
    ) -> CompanionResponse {
        let relevantContent = findRelevantContent(for: question, in: chapters, upTo: currentChapter)

        return CompanionResponse(
            question: question,
            answer: generateAnswer(question: question, content: relevantContent),
            relevantChapters: findRelevantChapterIndices(for: question, in: chapters),
            confidence: calculateConfidence(question: question, content: relevantContent)
        )
    }

    /// AI-powered Q&A using Claude API — falls back to keyword-based if unavailable
    func answerQuestionWithAI(
        question: String,
        chapters: [BookChapter],
        currentChapter: Int,
        bookTitle: String
    ) async -> CompanionResponse {
        guard await ClaudeAPIClient.shared.isConfigured else {
            return answerQuestion(question: question, chapters: chapters, currentChapter: currentChapter)
        }

        isProcessing = true
        defer { isProcessing = false }

        let recentChapters = Array(chapters.prefix(currentChapter + 1).suffix(3))
        let context = recentChapters
            .map { "[\($0.title)]\n\($0.content.prefix(3000))" }
            .joined(separator: "\n\n---\n\n")

        let system = """
        You are an AI reading companion for "\(bookTitle)". Answer based only on the \
        book content provided. Be concise, helpful, and spoiler-free (don't reveal events \
        beyond what was provided). If the answer isn't in the text, say so honestly.
        """

        let prompt = "Book content from recent chapters:\n\n\(String(context.prefix(10000)))\n\nReader's question: \(question)"

        do {
            let answer = try await ClaudeAPIClient.shared.sendMessage(
                system: system,
                userMessage: prompt,
                maxTokens: 1024
            )

            return CompanionResponse(
                question: question,
                answer: answer,
                relevantChapters: findRelevantChapterIndices(for: question, in: chapters),
                confidence: 0.9
            )
        } catch {
            return answerQuestion(question: question, chapters: chapters, currentChapter: currentChapter)
        }
    }

    /// Generates an AI-powered recap using Claude API
    func generateRecapWithAI(
        book: Book,
        chapters: [BookChapter],
        currentChapter: Int
    ) async -> ReadingRecap {
        guard await ClaudeAPIClient.shared.isConfigured else {
            return generateRecap(book: book, chapters: chapters, currentChapter: currentChapter)
        }

        isProcessing = true
        defer { isProcessing = false }

        let chaptersRead = Array(chapters.prefix(currentChapter + 1))
        let summaryContent = chaptersRead.suffix(3)
            .map { "[\($0.title)]\n\($0.content.prefix(2000))" }
            .joined(separator: "\n\n")

        let system = """
        You are a reading companion. Provide a brief recap of where the reader left off. \
        Include: key characters involved, recent events, and what was happening. \
        Keep it to 2-3 sentences. Be warm and engaging. No spoilers beyond what's provided.
        """

        do {
            let summary = try await ClaudeAPIClient.shared.sendMessage(
                system: system,
                userMessage: "The reader is on chapter \(currentChapter + 1) of \"\(book.title)\" by \(book.author). Recent content:\n\n\(String(summaryContent.prefix(8000)))",
                maxTokens: 512
            )

            let characters = extractCharacters(from: chaptersRead.suffix(3).map(\.content).joined(separator: " "))
            let events = extractKeyEvents(from: chaptersRead.last?.content ?? "")

            return ReadingRecap(
                bookTitle: book.title,
                currentChapter: currentChapter,
                chapterTitle: chaptersRead.last?.title ?? "",
                summary: summary,
                keyCharacters: characters,
                recentEvents: events,
                readingProgress: Double(currentChapter + 1) / Double(max(chapters.count, 1)),
                estimatedTimeToFinish: estimateRemainingTime(chaptersRead: currentChapter + 1, totalChapters: chapters.count)
            )
        } catch {
            return generateRecap(book: book, chapters: chapters, currentChapter: currentChapter)
        }
    }

    // MARK: - Private Helpers

    private let commonWords: Set<String> = [
        "the", "and", "but", "for", "not", "you", "all", "can", "had", "her",
        "was", "one", "our", "out", "day", "get", "has", "him", "his", "how",
        "its", "may", "new", "now", "old", "see", "way", "who", "did", "let",
        "say", "she", "too", "use", "would", "about", "could", "their", "there",
        "these", "thing", "think", "those", "through", "time", "very", "when",
        "which", "while", "after", "again", "because", "been", "before", "being",
        "between", "both", "came", "come", "each", "from", "have", "here", "just",
        "like", "long", "look", "make", "many", "more", "most", "much", "must",
        "name", "never", "next", "only", "other", "over", "said", "same", "some",
        "still", "such", "take", "than", "them", "then", "this", "what", "with",
        "your", "into", "that", "they", "will", "also", "back", "been", "call",
        "chapter", "first", "hand", "high", "keep", "last", "made", "might",
        "part", "place", "point", "right", "should", "small", "something",
        "state", "tell", "turn", "under", "upon", "well", "went", "were",
        "where", "work", "year", "every", "found", "great", "house", "know",
        "large", "little", "people", "though", "thought", "world", "young",
        "asked", "another", "away", "began", "however", "nothing", "really",
        "seemed", "since", "toward", "turned", "until", "want", "without"
    ]

    private func extractCharacters(from text: String) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var candidates: [String: Int] = [:]

        for word in words {
            let cleaned = word.trimmingCharacters(in: .punctuationCharacters)
            guard cleaned.count > 2,
                  let first = cleaned.first,
                  first.isUppercase,
                  !commonWords.contains(cleaned.lowercased()) else { continue }
            candidates[cleaned, default: 0] += 1
        }

        return candidates
            .filter { $0.value >= 3 }
            .sorted { $0.value > $1.value }
            .prefix(8)
            .map(\.key)
    }

    private func extractKeyEvents(from text: String) -> [String] {
        let sentences = text.components(separatedBy: ". ")
        let actionWords = ["discovered", "found", "realized", "decided", "escaped",
                          "fought", "arrived", "revealed", "learned", "met",
                          "lost", "killed", "married", "died", "won", "created",
                          "destroyed", "saved", "betrayed", "confessed"]

        return sentences
            .filter { sentence in
                actionWords.contains { sentence.lowercased().contains($0) }
            }
            .prefix(5)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private func buildRecapSummary(chapters: [BookChapter]) -> String {
        guard let lastChapter = chapters.last else {
            return "You haven't started reading yet."
        }

        let totalWords = chapters.reduce(0) { $0 + $1.wordCount }
        let chaptersStr = chapters.count == 1 ? "1 chapter" : "\(chapters.count) chapters"

        return "You've read \(chaptersStr) (\(totalWords.formatted()) words). " +
               "Your last chapter was \"\(lastChapter.title)\"."
    }

    private func estimateRemainingTime(chaptersRead: Int, totalChapters: Int) -> String {
        let remaining = totalChapters - chaptersRead
        guard remaining > 0 else { return "Almost done!" }
        let estimatedMinutes = remaining * 15 // ~15 min per chapter average
        if estimatedMinutes >= 60 {
            return "~\(estimatedMinutes / 60)h \(estimatedMinutes % 60)m remaining"
        }
        return "~\(estimatedMinutes)m remaining"
    }

    private func findFirstAppearance(of name: String, in chapters: [BookChapter]) -> Int {
        for chapter in chapters {
            if chapter.content.contains(name) {
                return chapter.index
            }
        }
        return 0
    }

    private func findContext(for word: String, in text: String) -> String {
        let lowered = text.lowercased()
        guard let range = lowered.range(of: word) else { return "" }
        let start = text.index(range.lowerBound, offsetBy: -40, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: 40, limitedBy: text.endIndex) ?? text.endIndex
        return "..." + text[start..<end].replacingOccurrences(of: "\n", with: " ") + "..."
    }

    private func findRelevantContent(for question: String, in chapters: [BookChapter], upTo: Int) -> String {
        let keywords = question.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 && !commonWords.contains($0) }

        let relevantChapters = chapters.prefix(upTo + 1)
        var relevantSentences: [(sentence: String, score: Int)] = []

        for chapter in relevantChapters {
            let sentences = chapter.content.components(separatedBy: ". ")
            for sentence in sentences {
                let score = keywords.reduce(0) { acc, keyword in
                    acc + (sentence.lowercased().contains(keyword) ? 1 : 0)
                }
                if score > 0 {
                    relevantSentences.append((sentence.trimmingCharacters(in: .whitespacesAndNewlines), score))
                }
            }
        }

        return relevantSentences
            .sorted { $0.score > $1.score }
            .prefix(5)
            .map(\.sentence)
            .joined(separator: ". ")
    }

    private func generateAnswer(question: String, content: String) -> String {
        if content.isEmpty {
            return "I couldn't find specific information about that in the chapters you've read so far. Try reading further or rephrasing your question."
        }
        return "Based on what you've read: \(String(content.prefix(500)))"
    }

    private func findRelevantChapterIndices(for question: String, in chapters: [BookChapter]) -> [Int] {
        let keywords = question.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }

        return chapters.compactMap { chapter in
            let matchCount = keywords.filter { chapter.content.lowercased().contains($0) }.count
            return matchCount > 0 ? chapter.index : nil
        }
    }

    private func calculateConfidence(question: String, content: String) -> Double {
        if content.isEmpty { return 0.1 }
        let words = content.components(separatedBy: .whitespacesAndNewlines).count
        return min(0.95, Double(words) / 200.0)
    }
}

// MARK: - Supporting Types

struct ReadingRecap {
    let bookTitle: String
    let currentChapter: Int
    let chapterTitle: String
    let summary: String
    let keyCharacters: [String]
    let recentEvents: [String]
    let readingProgress: Double
    let estimatedTimeToFinish: String
}

struct CharacterInfo: Identifiable {
    let id = UUID()
    let name: String
    let mentionCount: Int
    let contextSnippets: [String]
    let firstAppearanceChapter: Int
}

struct VocabSuggestion: Identifiable {
    let id = UUID()
    let word: String
    let context: String
    let frequency: Int
    let chapterTitle: String
}

struct CompanionResponse: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let relevantChapters: [Int]
    let confidence: Double
}
