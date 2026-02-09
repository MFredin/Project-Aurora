import SwiftUI
import SwiftData

struct ActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [ReadingSession]
    @Query private var books: [Book]
    @Query private var streaks: [ReadingStreak]
    @Query private var achievements: [Achievement]
    @Query private var friends: [FriendProfile]

    @State private var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    private var streak: ReadingStreak? { streaks.first }
    private var weeklyStats: ReadingStatsService.WeeklyStats {
        ReadingStatsService.weeklyStats(sessions: sessions)
    }
    private var allTimeStats: ReadingStatsService.AllTimeStats {
        ReadingStatsService.allTimeStats(sessions: sessions, books: books)
    }
    private var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                // Aurora background glow
                Circle()
                    .fill(AuroraTheme.auroraGreen.opacity(0.08))
                    .frame(width: 350, height: 350)
                    .blur(radius: 90)
                    .offset(x: -80, y: -200)
                    .ignoresSafeArea()

                Circle()
                    .fill(AuroraTheme.auroraPurple.opacity(0.06))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 120, y: 150)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        streakCard
                        weeklyOverviewCard
                        readingChartCard
                        achievementPreviewCard
                        friendsPreviewCard
                        allTimeStatsCard
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Activity")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 0) {
            // Streak flame
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AuroraTheme.auroraWarm.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AuroraTheme.auroraWarm, AuroraTheme.auroraPink],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }

                Text("\(streak?.currentStreak ?? 0)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AuroraTheme.textPrimary)

                Text("Day Streak")
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1, height: 80)

            // Goal progress
            VStack(spacing: 8) {
                let goalMinutes = streak?.dailyGoalMinutes ?? 30
                let todayMinutes = todayReadingMinutes
                let progress = min(Double(todayMinutes) / Double(max(goalMinutes, 1)), 1.0)

                ZStack {
                    Circle()
                        .stroke(AuroraTheme.surface, lineWidth: 6)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: [AuroraTheme.auroraTeal, AuroraTheme.auroraGreen], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AuroraTheme.textPrimary)
                }

                Text("Daily Goal")
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.textSecondary)

                Text("\(todayMinutes)/\(goalMinutes) min")
                    .font(.caption2)
                    .foregroundStyle(AuroraTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1, height: 80)

            // Longest streak
            VStack(spacing: 8) {
                Image(systemName: "trophy.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AuroraTheme.auroraWarm)

                Text("\(streak?.longestStreak ?? 0)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AuroraTheme.textPrimary)

                Text("Best Streak")
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .auroraCard()
    }

    // MARK: - Weekly Overview

    private var weeklyOverviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("This Week")
                    .font(.headline)
                    .foregroundStyle(AuroraTheme.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: weeklyStats.isImproved ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(weeklyStats.changePercentage)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(weeklyStats.isImproved ? AuroraTheme.auroraGreen : AuroraTheme.auroraWarm)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    (weeklyStats.isImproved ? AuroraTheme.auroraGreen : AuroraTheme.auroraWarm).opacity(0.12),
                    in: Capsule()
                )
            }

            HStack(spacing: 0) {
                statPill(value: "\(weeklyStats.totalMinutes)", label: "Minutes", color: AuroraTheme.auroraTeal)
                statPill(value: "\(weeklyStats.totalPages)", label: "Pages", color: AuroraTheme.auroraGreen)
                statPill(value: "\(weeklyStats.sessionsCount)", label: "Sessions", color: AuroraTheme.auroraBlue)
                statPill(value: "\(weeklyStats.averageSessionMinutes)", label: "Avg/Session", color: AuroraTheme.auroraPurple)
            }
        }
        .padding(16)
        .auroraCard()
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AuroraTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reading Chart

    private var readingChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reading Activity")
                    .font(.headline)
                    .foregroundStyle(AuroraTheme.textPrimary)
                Spacer()
                Picker("Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            // Bar chart
            let days = chartDays
            let data = ReadingStatsService.dailyReadingMinutes(days: days, sessions: sessions)
            let maxMinutes = max(data.map(\.minutes).max() ?? 1, 1)

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, entry in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [AuroraTheme.auroraTeal.opacity(0.8), AuroraTheme.auroraGreen],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: max(CGFloat(entry.minutes) / CGFloat(maxMinutes) * 120, entry.minutes > 0 ? 4 : 1))

                        if days <= 7 {
                            Text(dayLabel(entry.date))
                                .font(.system(size: 9))
                                .foregroundStyle(Calendar.current.isDateInToday(entry.date) ? AuroraTheme.auroraTeal : AuroraTheme.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150)
            .padding(.top, 4)
        }
        .padding(16)
        .auroraCard()
    }

    // MARK: - Achievement Preview

    private var achievementPreviewCard: some View {
        NavigationLink {
            AchievementsView()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Achievements")
                        .font(.headline)
                        .foregroundStyle(AuroraTheme.textPrimary)
                    Spacer()
                    Text("\(unlockedAchievements.count)/\(achievements.count)")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)
                }

                if unlockedAchievements.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "trophy.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AuroraTheme.textTertiary)
                        Text("Start reading to unlock achievements!")
                            .font(.subheadline)
                            .foregroundStyle(AuroraTheme.textSecondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    // Show last 4 unlocked achievements
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(unlockedAchievements.prefix(4)) { achievement in
                                VStack(spacing: 6) {
                                    Image(systemName: achievement.iconName)
                                        .font(.title2)
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(AuroraTheme.auroraWarm)

                                    Text(achievement.title)
                                        .font(.caption2)
                                        .foregroundStyle(AuroraTheme.textSecondary)
                                        .lineLimit(1)
                                }
                                .frame(width: 70)
                            }
                        }
                    }
                }

                // Progress on next achievement
                if let nextAchievement = achievements.first(where: { !$0.isUnlocked }) {
                    HStack(spacing: 10) {
                        Image(systemName: nextAchievement.iconName)
                            .font(.body)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AuroraTheme.textTertiary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(nextAchievement.title)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AuroraTheme.textPrimary)
                            ProgressView(value: nextAchievement.progress)
                                .tint(AuroraTheme.auroraTeal)
                        }

                        Text("\(nextAchievement.currentValue)/\(nextAchievement.targetValue)")
                            .font(.caption2)
                            .foregroundStyle(AuroraTheme.textTertiary)
                    }
                    .padding(10)
                    .background(AuroraTheme.surface.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(16)
            .auroraCard()
        }
    }

    // MARK: - Friends Preview

    private var friendsPreviewCard: some View {
        NavigationLink {
            FriendsView()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Friends")
                        .font(.headline)
                        .foregroundStyle(AuroraTheme.textPrimary)
                    Spacer()
                    if !friends.isEmpty {
                        Text("\(friends.count) friends")
                            .font(.caption)
                            .foregroundStyle(AuroraTheme.textSecondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)
                }

                if friends.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AuroraTheme.textTertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add friends to compare reading stats")
                                .font(.subheadline)
                                .foregroundStyle(AuroraTheme.textSecondary)
                            Text("Share your username to connect")
                                .font(.caption)
                                .foregroundStyle(AuroraTheme.textTertiary)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    // Friend avatars row
                    HStack(spacing: -8) {
                        ForEach(friends.prefix(5)) { friend in
                            Text(friend.avatarEmoji)
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(AuroraTheme.surface, in: Circle())
                                .overlay(Circle().strokeBorder(AuroraTheme.deepSpace, lineWidth: 2))
                        }
                        if friends.count > 5 {
                            Text("+\(friends.count - 5)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AuroraTheme.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(AuroraTheme.surface, in: Circle())
                                .overlay(Circle().strokeBorder(AuroraTheme.deepSpace, lineWidth: 2))
                        }
                    }

                    // Top friend this week
                    if let topFriend = friends.sorted(by: { $0.pagesReadThisWeek > $1.pagesReadThisWeek }).first {
                        HStack(spacing: 10) {
                            Text(topFriend.avatarEmoji)
                                .font(.body)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(topFriend.displayName)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AuroraTheme.textPrimary)
                                Text("\(topFriend.pagesReadThisWeek) pages this week")
                                    .font(.caption2)
                                    .foregroundStyle(AuroraTheme.textTertiary)
                            }
                            Spacer()
                            if topFriend.currentStreak > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.caption2)
                                        .foregroundStyle(AuroraTheme.auroraWarm)
                                    Text("\(topFriend.currentStreak)")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(AuroraTheme.auroraWarm)
                                }
                            }
                        }
                        .padding(10)
                        .background(AuroraTheme.surface.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(16)
            .auroraCard()
        }
    }

    // MARK: - All-Time Stats

    private var allTimeStatsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("All Time")
                .font(.headline)
                .foregroundStyle(AuroraTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                allTimeStat(icon: "clock.circle.fill", value: allTimeStats.formattedTime, label: "Total Reading", color: AuroraTheme.auroraTeal)
                allTimeStat(icon: "doc.richtext.fill", value: "\(allTimeStats.totalPages)", label: "Pages Read", color: AuroraTheme.auroraGreen)
                allTimeStat(icon: "checkmark.circle.fill", value: "\(allTimeStats.booksFinished)", label: "Books Finished", color: AuroraTheme.auroraBlue)
                allTimeStat(icon: "book.circle.fill", value: "\(allTimeStats.booksInProgress)", label: "In Progress", color: AuroraTheme.auroraPurple)
            }
        }
        .padding(16)
        .auroraCard()
    }

    private func allTimeStat(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(AuroraTheme.textPrimary)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(AuroraTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private var todayReadingMinutes: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todaySessions = sessions.filter { $0.startTime >= today && $0.endTime != nil }
        return todaySessions.reduce(0) { $0 + $1.durationSeconds } / 60
    }

    private var chartDays: Int {
        switch selectedTimeRange {
        case .week: return 7
        case .month: return 30
        case .year: return 52
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let label = formatter.string(from: date)
        return String(label.prefix(2))
    }
}

#Preview {
    ActivityView()
        .modelContainer(for: [
            Book.self, ReadingProgress.self, Bookmark.self, UserPreferences.self,
            ReadingSession.self, ReadingStreak.self, Achievement.self, FriendProfile.self
        ], inMemory: true)
}
