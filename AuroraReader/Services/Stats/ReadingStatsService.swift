import Foundation
import SwiftData

/// Service for computing reading analytics and managing gamification
@MainActor @Observable
final class ReadingStatsService {
    static let shared = ReadingStatsService()

    private(set) var activeSession: ReadingSession?

    private init() {}

    // MARK: - Session Tracking

    /// Starts a new reading session for the given book
    func startSession(for book: Book, modelContext: ModelContext) -> ReadingSession {
        let session = ReadingSession(book: book)
        modelContext.insert(session)
        try? modelContext.save()
        activeSession = session
        return session
    }

    /// Ends the current reading session
    func endSession(pagesRead: Int = 0, chaptersRead: Int = 0, wordsRead: Int = 0, modelContext: ModelContext) {
        guard let session = activeSession else { return }
        session.endSession(pagesRead: pagesRead, chaptersRead: chaptersRead, wordsRead: wordsRead)
        activeSession = nil

        // Update streak
        updateStreak(modelContext: modelContext)

        // Update achievements
        updateAchievements(modelContext: modelContext)

        try? modelContext.save()
    }

    // MARK: - Streak Management

    private func updateStreak(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ReadingStreak>()
        let streaks = (try? modelContext.fetch(descriptor)) ?? []

        let streak: ReadingStreak
        if let existing = streaks.first {
            streak = existing
        } else {
            streak = ReadingStreak()
            modelContext.insert(streak)
        }

        streak.recordReadingDay()
    }

    // MARK: - Achievement Updates

    private func updateAchievements(modelContext: ModelContext) {
        ensureAchievementsExist(modelContext: modelContext)

        // Only fetch unlocked achievements to reduce work
        let achievementDescriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate { !$0.isUnlocked }
        )
        let achievements = (try? modelContext.fetch(achievementDescriptor)) ?? []

        guard !achievements.isEmpty else { return }

        // Fetch only completed sessions (filter at query level)
        let sessionDescriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate { $0.endTime != nil }
        )
        let completedSessions = (try? modelContext.fetch(sessionDescriptor)) ?? []

        let streakDescriptor = FetchDescriptor<ReadingStreak>()
        let streak = (try? modelContext.fetch(streakDescriptor))?.first

        let bookDescriptor = FetchDescriptor<Book>()
        let books = (try? modelContext.fetch(bookDescriptor)) ?? []

        let friendDescriptor = FetchDescriptor<FriendProfile>()
        let friends = (try? modelContext.fetch(friendDescriptor)) ?? []
        let totalMinutes = completedSessions.reduce(0) { $0 + $1.durationSeconds } / 60
        let totalPages = completedSessions.reduce(0) { $0 + $1.pagesRead }
        let booksFinished = books.filter { ($0.readingProgress?.progressPercentage ?? 0) >= 1.0 }.count
        let uniqueFormats = Set(books.map { $0.format }).count
        let uniqueCategories = Set(books.map { $0.bookFormat.category }).count
        let maxPagesInSession = completedSessions.map(\.pagesRead).max() ?? 0

        for achievement in achievements {
            let type = achievement.type
            switch type {
            // Book milestones
            case .firstBook, .bookworm, .bibliophile, .librarian, .scholar:
                achievement.updateProgress(value: booksFinished)

            // Streak achievements
            case .threeDayStreak, .weekStreak, .monthStreak, .centuryStreak:
                achievement.updateProgress(value: streak?.currentStreak ?? 0)

            // Time achievements (in minutes)
            case .hourReader, .dayDreamer, .marathon:
                achievement.updateProgress(value: totalMinutes)

            // Diversity
            case .explorer:
                achievement.updateProgress(value: uniqueCategories)
            case .formatMaster:
                achievement.updateProgress(value: uniqueFormats)

            // Social
            case .socialReader, .bookClub:
                achievement.updateProgress(value: friends.count)

            // Speed
            case .speedReader:
                achievement.updateProgress(value: maxPagesInSession)
            case .pageturner:
                achievement.updateProgress(value: totalPages)
            }
        }
    }

    private func ensureAchievementsExist(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Achievement>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        let existingTypes = Set(existing.map(\.achievementType))

        for type in AchievementType.allCases where !existingTypes.contains(type.rawValue) {
            let achievement = Achievement(type: type)
            modelContext.insert(achievement)
        }
    }

    // MARK: - Analytics Queries

    /// Returns reading minutes per day for the last N days
    static func dailyReadingMinutes(days: Int, sessions: [ReadingSession]) -> [(date: Date, minutes: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<days).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: date)!

            let daySessions = sessions.filter { session in
                session.startTime >= date && session.startTime < dayEnd && session.endTime != nil
            }

            let totalMinutes = daySessions.reduce(0) { $0 + $1.durationSeconds } / 60
            return (date: date, minutes: totalMinutes)
        }
    }

    /// Returns reading stats for the current week
    static func weeklyStats(sessions: [ReadingSession]) -> WeeklyStats {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!

        let thisWeek = sessions.filter { $0.startTime >= weekStart && $0.endTime != nil }
        let lastWeek = sessions.filter { $0.startTime >= lastWeekStart && $0.startTime < weekStart && $0.endTime != nil }

        let thisWeekMinutes = thisWeek.reduce(0) { $0 + $1.durationSeconds } / 60
        let lastWeekMinutes = lastWeek.reduce(0) { $0 + $1.durationSeconds } / 60
        let thisWeekPages = thisWeek.reduce(0) { $0 + $1.pagesRead }

        return WeeklyStats(
            totalMinutes: thisWeekMinutes,
            totalPages: thisWeekPages,
            sessionsCount: thisWeek.count,
            averageSessionMinutes: thisWeek.isEmpty ? 0 : thisWeekMinutes / thisWeek.count,
            changeFromLastWeek: lastWeekMinutes > 0 ? Double(thisWeekMinutes - lastWeekMinutes) / Double(lastWeekMinutes) : 0
        )
    }

    struct WeeklyStats {
        let totalMinutes: Int
        let totalPages: Int
        let sessionsCount: Int
        let averageSessionMinutes: Int
        let changeFromLastWeek: Double

        var changePercentage: String {
            let pct = Int(changeFromLastWeek * 100)
            return pct >= 0 ? "+\(pct)%" : "\(pct)%"
        }

        var isImproved: Bool { changeFromLastWeek >= 0 }
    }

    /// Returns total all-time stats
    static func allTimeStats(sessions: [ReadingSession], books: [Book]) -> AllTimeStats {
        let completedSessions = sessions.filter { $0.endTime != nil }
        let totalMinutes = completedSessions.reduce(0) { $0 + $1.durationSeconds } / 60
        let totalPages = completedSessions.reduce(0) { $0 + $1.pagesRead }
        let booksFinished = books.filter { ($0.readingProgress?.progressPercentage ?? 0) >= 1.0 }.count

        return AllTimeStats(
            totalMinutes: totalMinutes,
            totalPages: totalPages,
            totalSessions: completedSessions.count,
            booksFinished: booksFinished,
            booksInProgress: books.count - booksFinished
        )
    }

    struct AllTimeStats {
        let totalMinutes: Int
        let totalPages: Int
        let totalSessions: Int
        let booksFinished: Int
        let booksInProgress: Int

        var totalHours: Int { totalMinutes / 60 }

        var formattedTime: String {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if hours > 0 { return "\(hours)h \(minutes)m" }
            return "\(minutes)m"
        }
    }
}
