import Foundation
import SwiftData

/// A vocabulary word saved by the user from their reading
@Model
final class VocabularyEntry {
    var id: UUID
    var word: String
    var definition: String
    var context: String
    var bookTitle: String
    var chapterTitle: String
    var dateAdded: Date
    var isMastered: Bool
    var reviewCount: Int
    var lastReviewDate: Date?

    @Relationship var book: Book?

    init(
        word: String,
        definition: String = "",
        context: String = "",
        bookTitle: String = "",
        chapterTitle: String = ""
    ) {
        self.id = UUID()
        self.word = word.lowercased()
        self.definition = definition
        self.context = context
        self.bookTitle = bookTitle
        self.chapterTitle = chapterTitle
        self.dateAdded = Date()
        self.isMastered = false
        self.reviewCount = 0
    }

    func markReviewed() {
        reviewCount += 1
        lastReviewDate = Date()
        if reviewCount >= 5 {
            isMastered = true
        }
    }

    var masteryLevel: String {
        switch reviewCount {
        case 0: return "New"
        case 1...2: return "Learning"
        case 3...4: return "Familiar"
        default: return "Mastered"
        }
    }

    var masteryProgress: Double {
        min(1.0, Double(reviewCount) / 5.0)
    }
}
