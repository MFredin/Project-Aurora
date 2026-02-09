import Foundation
import SwiftData
import SwiftUI

/// Color options for text highlights, themed to Aurora palette
enum HighlightColor: String, Codable, CaseIterable, Identifiable {
    case auroraGreen
    case auroraTeal
    case auroraBlue
    case auroraPurple
    case auroraPink
    case auroraWarm

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .auroraGreen: return AuroraTheme.auroraGreen
        case .auroraTeal: return AuroraTheme.auroraTeal
        case .auroraBlue: return AuroraTheme.auroraBlue
        case .auroraPurple: return AuroraTheme.auroraPurple
        case .auroraPink: return AuroraTheme.auroraPink
        case .auroraWarm: return AuroraTheme.auroraWarm
        }
    }

    var displayName: String {
        switch self {
        case .auroraGreen: return "Green"
        case .auroraTeal: return "Teal"
        case .auroraBlue: return "Blue"
        case .auroraPurple: return "Purple"
        case .auroraPink: return "Pink"
        case .auroraWarm: return "Warm"
        }
    }

    var backgroundColor: Color {
        color.opacity(0.25)
    }

    var underlineColor: Color {
        color.opacity(0.6)
    }
}

/// A text highlight/annotation within a book
@Model
final class Highlight {
    var id: UUID
    var highlightedText: String
    var note: String
    var colorRaw: String
    var chapterIndex: Int
    var chapterTitle: String
    var rangeStart: Int
    var rangeLength: Int
    var dateCreated: Date
    var dateModified: Date
    var tags: [String]

    @Relationship var book: Book?

    var highlightColor: HighlightColor {
        get { HighlightColor(rawValue: colorRaw) ?? .auroraTeal }
        set { colorRaw = newValue.rawValue }
    }

    init(
        highlightedText: String,
        note: String = "",
        color: HighlightColor = .auroraTeal,
        chapterIndex: Int,
        chapterTitle: String = "",
        rangeStart: Int,
        rangeLength: Int
    ) {
        self.id = UUID()
        self.highlightedText = highlightedText
        self.note = note
        self.colorRaw = color.rawValue
        self.chapterIndex = chapterIndex
        self.chapterTitle = chapterTitle
        self.rangeStart = rangeStart
        self.rangeLength = rangeLength
        self.dateCreated = Date()
        self.dateModified = Date()
        self.tags = []
    }

    var hasNote: Bool {
        !note.isEmpty
    }

    var textPreview: String {
        if highlightedText.count > 120 {
            return String(highlightedText.prefix(120)) + "..."
        }
        return highlightedText
    }

    func updateNote(_ newNote: String) {
        note = newNote
        dateModified = Date()
    }

    func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            dateModified = Date()
        }
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        dateModified = Date()
    }
}
