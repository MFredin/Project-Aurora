import Foundation
import SwiftData

@Model
final class ReadingProgress {
    var id: UUID
    var currentChapter: Int
    var currentPage: Int
    var totalPages: Int
    var progressPercentage: Double
    var lastReadDate: Date

    @Relationship var book: Book?

    init(
        currentChapter: Int = 0,
        currentPage: Int = 0,
        totalPages: Int = 1
    ) {
        self.id = UUID()
        self.currentChapter = currentChapter
        self.currentPage = currentPage
        self.totalPages = max(totalPages, 1)
        self.progressPercentage = totalPages > 0 ? Double(currentPage) / Double(totalPages) : 0
        self.lastReadDate = Date()
    }

    func updateProgress(chapter: Int, page: Int, totalPages: Int) {
        self.currentChapter = chapter
        self.currentPage = page
        self.totalPages = max(totalPages, 1)
        self.progressPercentage = Double(page) / Double(self.totalPages)
        self.lastReadDate = Date()
    }
}
