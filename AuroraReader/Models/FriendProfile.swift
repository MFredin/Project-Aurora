import Foundation
import SwiftData

/// Represents a friend for social reading comparison
@Model
final class FriendProfile {
    var id: UUID
    var username: String
    var displayName: String
    var avatarEmoji: String
    var joinDate: Date

    // Reading stats (synced)
    var booksFinished: Int
    var currentStreak: Int
    var totalReadingMinutes: Int
    var pagesReadThisWeek: Int
    var booksReadThisMonth: Int
    var favoriteGenre: String

    // Currently reading
    var currentBookTitle: String?
    var currentBookProgress: Double

    // Comparison helpers
    var lastActiveDate: Date

    init(
        username: String,
        displayName: String,
        avatarEmoji: String = "📖"
    ) {
        self.id = UUID()
        self.username = username
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.joinDate = Date()
        self.booksFinished = 0
        self.currentStreak = 0
        self.totalReadingMinutes = 0
        self.pagesReadThisWeek = 0
        self.booksReadThisMonth = 0
        self.favoriteGenre = ""
        self.currentBookTitle = nil
        self.currentBookProgress = 0
        self.lastActiveDate = Date()
    }

    var totalReadingHours: Double {
        Double(totalReadingMinutes) / 60.0
    }

    var isActiveToday: Bool {
        Calendar.current.isDateInToday(lastActiveDate)
    }

    var streakEmoji: String {
        if currentStreak >= 30 { return "🔥" }
        if currentStreak >= 7 { return "⚡" }
        if currentStreak >= 3 { return "✨" }
        return ""
    }
}

/// Represents a weekly leaderboard entry
struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let displayName: String
    let avatarEmoji: String
    let value: Int
    let metric: LeaderboardMetric
    let isCurrentUser: Bool

    enum LeaderboardMetric: String, CaseIterable {
        case pagesThisWeek = "Pages This Week"
        case minutesThisWeek = "Minutes This Week"
        case booksThisMonth = "Books This Month"
        case currentStreak = "Current Streak"
    }
}
