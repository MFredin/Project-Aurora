import Foundation
import SwiftData

/// Tracks individual reading sessions for habit analytics
@Model
final class ReadingSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var durationSeconds: Int
    var pagesRead: Int
    var chaptersRead: Int
    var wordsRead: Int

    @Relationship var book: Book?

    var isActive: Bool {
        endTime == nil
    }

    var durationMinutes: Double {
        Double(durationSeconds) / 60.0
    }

    var durationFormatted: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    init(book: Book? = nil) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.durationSeconds = 0
        self.pagesRead = 0
        self.chaptersRead = 0
        self.wordsRead = 0
        self.book = book
    }

    func endSession(pagesRead: Int = 0, chaptersRead: Int = 0, wordsRead: Int = 0) {
        self.endTime = Date()
        self.durationSeconds = Int(Date().timeIntervalSince(startTime))
        self.pagesRead = pagesRead
        self.chaptersRead = chaptersRead
        self.wordsRead = wordsRead
    }
}
