import Foundation
import SwiftData

/// Represents an achievement/badge the user can earn
@Model
final class Achievement {
    var id: UUID
    var achievementType: String
    var title: String
    var descriptionText: String
    var iconName: String
    var dateEarned: Date?
    var isUnlocked: Bool
    var progress: Double
    var targetValue: Int
    var currentValue: Int

    var type: AchievementType {
        get { AchievementType(rawValue: achievementType) ?? .firstBook }
        set { achievementType = newValue.rawValue }
    }

    init(type: AchievementType) {
        self.id = UUID()
        self.achievementType = type.rawValue
        self.title = type.title
        self.descriptionText = type.description
        self.iconName = type.iconName
        self.dateEarned = nil
        self.isUnlocked = false
        self.progress = 0
        self.targetValue = type.target
        self.currentValue = 0
    }

    func updateProgress(value: Int) {
        currentValue = value
        progress = min(Double(value) / Double(max(targetValue, 1)), 1.0)
        if progress >= 1.0 && !isUnlocked {
            isUnlocked = true
            dateEarned = Date()
        }
    }
}

/// All available achievement types
enum AchievementType: String, CaseIterable {
    // Reading milestones
    case firstBook = "first_book"
    case bookworm = "bookworm"
    case bibliophile = "bibliophile"
    case librarian = "librarian"
    case scholar = "scholar"

    // Streak achievements
    case threeDayStreak = "streak_3"
    case weekStreak = "streak_7"
    case monthStreak = "streak_30"
    case centuryStreak = "streak_100"

    // Time achievements
    case hourReader = "time_1h"
    case dayDreamer = "time_24h"
    case marathon = "time_100h"

    // Genre diversity
    case explorer = "explorer"
    case formatMaster = "format_master"

    // Social
    case socialReader = "social_reader"
    case bookClub = "book_club"

    // Speed
    case speedReader = "speed_reader"
    case pageturner = "pageturner"

    var title: String {
        switch self {
        case .firstBook: return "First Steps"
        case .bookworm: return "Bookworm"
        case .bibliophile: return "Bibliophile"
        case .librarian: return "Librarian"
        case .scholar: return "Scholar"
        case .threeDayStreak: return "Getting Started"
        case .weekStreak: return "Consistent Reader"
        case .monthStreak: return "Reading Machine"
        case .centuryStreak: return "Unstoppable"
        case .hourReader: return "First Hour"
        case .dayDreamer: return "Day Dreamer"
        case .marathon: return "Marathon Reader"
        case .explorer: return "Explorer"
        case .formatMaster: return "Format Master"
        case .socialReader: return "Social Reader"
        case .bookClub: return "Book Club"
        case .speedReader: return "Speed Reader"
        case .pageturner: return "Pageturner"
        }
    }

    var description: String {
        switch self {
        case .firstBook: return "Finish your first book"
        case .bookworm: return "Finish 5 books"
        case .bibliophile: return "Finish 25 books"
        case .librarian: return "Finish 50 books"
        case .scholar: return "Finish 100 books"
        case .threeDayStreak: return "Read 3 days in a row"
        case .weekStreak: return "Read 7 days in a row"
        case .monthStreak: return "Read 30 days in a row"
        case .centuryStreak: return "Read 100 days in a row"
        case .hourReader: return "Read for a total of 1 hour"
        case .dayDreamer: return "Read for a total of 24 hours"
        case .marathon: return "Read for a total of 100 hours"
        case .explorer: return "Read books in 3 different categories"
        case .formatMaster: return "Read books in 5 different formats"
        case .socialReader: return "Add your first friend"
        case .bookClub: return "Have 5 friends on Aurora Reader"
        case .speedReader: return "Read 50 pages in one session"
        case .pageturner: return "Read 1,000 pages total"
        }
    }

    var iconName: String {
        switch self {
        case .firstBook: return "star.circle.fill"
        case .bookworm: return "book.circle.fill"
        case .bibliophile: return "books.vertical.circle.fill"
        case .librarian: return "building.columns.circle.fill"
        case .scholar: return "graduationcap.circle.fill"
        case .threeDayStreak: return "flame.circle.fill"
        case .weekStreak: return "flame.circle.fill"
        case .monthStreak: return "flame.circle.fill"
        case .centuryStreak: return "flame.circle.fill"
        case .hourReader: return "clock.circle.fill"
        case .dayDreamer: return "moon.circle.fill"
        case .marathon: return "trophy.circle.fill"
        case .explorer: return "safari.fill"
        case .formatMaster: return "square.stack.3d.up.fill"
        case .socialReader: return "person.circle.fill"
        case .bookClub: return "person.3.fill"
        case .speedReader: return "bolt.circle.fill"
        case .pageturner: return "doc.richtext.fill"
        }
    }

    var target: Int {
        switch self {
        case .firstBook: return 1
        case .bookworm: return 5
        case .bibliophile: return 25
        case .librarian: return 50
        case .scholar: return 100
        case .threeDayStreak: return 3
        case .weekStreak: return 7
        case .monthStreak: return 30
        case .centuryStreak: return 100
        case .hourReader: return 60
        case .dayDreamer: return 1440
        case .marathon: return 6000
        case .explorer: return 3
        case .formatMaster: return 5
        case .socialReader: return 1
        case .bookClub: return 5
        case .speedReader: return 50
        case .pageturner: return 1000
        }
    }

    var category: AchievementCategory {
        switch self {
        case .firstBook, .bookworm, .bibliophile, .librarian, .scholar: return .milestones
        case .threeDayStreak, .weekStreak, .monthStreak, .centuryStreak: return .streaks
        case .hourReader, .dayDreamer, .marathon: return .time
        case .explorer, .formatMaster: return .diversity
        case .socialReader, .bookClub: return .social
        case .speedReader, .pageturner: return .speed
        }
    }

    enum AchievementCategory: String, CaseIterable {
        case milestones = "Milestones"
        case streaks = "Streaks"
        case time = "Reading Time"
        case diversity = "Diversity"
        case social = "Social"
        case speed = "Speed"
    }
}
