import Foundation
import SwiftData

/// Tracks the user's reading streak (consecutive days of reading)
@Model
final class ReadingStreak {
    var id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastReadDate: Date?
    var streakStartDate: Date?
    var totalDaysRead: Int

    /// Weekly reading goal in minutes
    var weeklyGoalMinutes: Int
    /// Daily reading goal in minutes
    var dailyGoalMinutes: Int

    init() {
        self.id = UUID()
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastReadDate = nil
        self.streakStartDate = nil
        self.totalDaysRead = 0
        self.weeklyGoalMinutes = 150
        self.dailyGoalMinutes = 30
    }

    /// Updates streak based on a new reading session
    func recordReadingDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastRead = lastReadDate else {
            // First ever reading day
            currentStreak = 1
            longestStreak = 1
            lastReadDate = today
            streakStartDate = today
            totalDaysRead = 1
            return
        }

        let lastReadDay = calendar.startOfDay(for: lastRead)

        if lastReadDay == today {
            // Already recorded today
            return
        }

        let daysSinceLast = calendar.dateComponents([.day], from: lastReadDay, to: today).day ?? 0

        if daysSinceLast == 1 {
            // Consecutive day
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            // Streak broken
            currentStreak = 1
            streakStartDate = today
        }

        lastReadDate = today
        totalDaysRead += 1
    }

    /// Checks if the streak is still alive (read yesterday or today)
    var isStreakActive: Bool {
        guard let lastRead = lastReadDate else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastReadDay = calendar.startOfDay(for: lastRead)
        let daysSince = calendar.dateComponents([.day], from: lastReadDay, to: today).day ?? 0
        return daysSince <= 1
    }
}
