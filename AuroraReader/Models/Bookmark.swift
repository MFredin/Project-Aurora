import Foundation
import SwiftData

@Model
final class Bookmark {
    var id: UUID
    var title: String
    var chapter: Int
    var page: Int
    var textSnippet: String
    var dateCreated: Date
    var color: String

    @Relationship var book: Book?

    init(
        title: String = "",
        chapter: Int,
        page: Int,
        textSnippet: String = "",
        color: String = "blue"
    ) {
        self.id = UUID()
        self.title = title
        self.chapter = chapter
        self.page = page
        self.textSnippet = textSnippet
        self.dateCreated = Date()
        self.color = color
    }
}
