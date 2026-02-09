import Foundation
import SwiftData

/// A book club for shared reading experiences
@Model
final class BookClub {
    var id: UUID
    var name: String
    var clubDescription: String
    var bookTitle: String
    var bookAuthor: String
    var targetChapter: Int
    var totalChapters: Int
    var paceType: String
    var startDate: Date
    var endDate: Date?
    var memberUsernames: [String]
    var memberAvatars: [String]
    var creatorUsername: String
    var isActive: Bool

    var pace: PaceType {
        get { PaceType(rawValue: paceType) ?? .weekly }
        set { paceType = newValue.rawValue }
    }

    @Relationship var book: Book?

    init(
        name: String,
        bookTitle: String = "",
        bookAuthor: String = "",
        totalChapters: Int = 0,
        pace: PaceType = .weekly,
        creatorUsername: String = "You"
    ) {
        self.id = UUID()
        self.name = name
        self.clubDescription = ""
        self.bookTitle = bookTitle
        self.bookAuthor = bookAuthor
        self.targetChapter = 0
        self.totalChapters = totalChapters
        self.paceType = pace.rawValue
        self.startDate = Date()
        self.memberUsernames = [creatorUsername]
        self.memberAvatars = ["📚"]
        self.creatorUsername = creatorUsername
        self.isActive = true
    }

    var memberCount: Int { memberUsernames.count }

    var progressPercentage: Double {
        guard totalChapters > 0 else { return 0 }
        return Double(targetChapter) / Double(totalChapters)
    }

    func addMember(username: String, avatar: String = "📖") {
        guard !memberUsernames.contains(username) else { return }
        memberUsernames.append(username)
        memberAvatars.append(avatar)
    }

    enum PaceType: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case biweekly = "Bi-weekly"
        case monthly = "Monthly"
        case custom = "Custom"
    }
}

/// A discussion message within a book club chapter
@Model
final class ClubDiscussion {
    var id: UUID
    var clubId: UUID
    var chapterIndex: Int
    var username: String
    var avatarEmoji: String
    var message: String
    var datePosted: Date
    var highlightedText: String?
    var likeCount: Int

    init(
        clubId: UUID,
        chapterIndex: Int,
        username: String = "You",
        avatarEmoji: String = "📚",
        message: String,
        highlightedText: String? = nil
    ) {
        self.id = UUID()
        self.clubId = clubId
        self.chapterIndex = chapterIndex
        self.username = username
        self.avatarEmoji = avatarEmoji
        self.message = message
        self.datePosted = Date()
        self.highlightedText = highlightedText
        self.likeCount = 0
    }
}
