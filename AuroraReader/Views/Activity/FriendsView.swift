import SwiftUI
import SwiftData

struct FriendsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var friends: [FriendProfile]
    @Query private var sessions: [ReadingSession]
    @Query private var streaks: [ReadingStreak]

    @State private var showAddFriend = false
    @State private var friendUsername = ""
    @State private var selectedMetric: LeaderboardEntry.LeaderboardMetric = .pagesThisWeek

    private var streak: ReadingStreak? { streaks.first }

    var body: some View {
        ZStack {
            AuroraTheme.deepSpace.ignoresSafeArea()

            Circle()
                .fill(AuroraTheme.auroraBlue.opacity(0.06))
                .frame(width: 350, height: 350)
                .blur(radius: 90)
                .offset(x: 80, y: -200)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    leaderboardSection
                    friendsListSection
                    inviteSection
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddFriend = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AuroraTheme.auroraTeal)
                }
            }
        }
        .alert("Add Friend", isPresented: $showAddFriend) {
            TextField("Username", text: $friendUsername)
            Button("Add") {
                addFriend()
            }
            Button("Cancel", role: .cancel) {
                friendUsername = ""
            }
        } message: {
            Text("Enter your friend's Aurora Reader username")
        }
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(AuroraTheme.auroraTeal)
                Text("Leaderboard")
                    .font(.headline)
                    .foregroundStyle(AuroraTheme.textPrimary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LeaderboardEntry.LeaderboardMetric.allCases, id: \.self) { metric in
                        Button {
                            selectedMetric = metric
                        } label: {
                            Text(metric.rawValue)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(selectedMetric == metric ? .white : AuroraTheme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedMetric == metric
                                        ? AnyShapeStyle(AuroraTheme.accentGradient)
                                        : AnyShapeStyle(AuroraTheme.surface),
                                    in: Capsule()
                                )
                        }
                    }
                }
            }

            // Leaderboard entries
            let entries = buildLeaderboard()
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                leaderboardRow(entry, rank: index + 1)
            }
        }
        .padding(16)
        .auroraCard()
    }

    private func leaderboardRow(_ entry: LeaderboardEntry, rank: Int) -> some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.caption.weight(.bold))
                .foregroundStyle(rank <= 3 ? AuroraTheme.auroraWarm : AuroraTheme.textTertiary)
                .frame(width: 28)

            // Avatar
            Text(entry.avatarEmoji)
                .font(.title3)
                .frame(width: 32, height: 32)

            // Name
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(entry.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(entry.isCurrentUser ? AuroraTheme.auroraTeal : AuroraTheme.textPrimary)
                    if entry.isCurrentUser {
                        Text("You")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AuroraTheme.auroraTeal)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(AuroraTheme.auroraTeal.opacity(0.12), in: Capsule())
                    }
                }
            }

            Spacer()

            // Value
            Text("\(entry.value)")
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundStyle(rank == 1 ? AuroraTheme.auroraWarm : AuroraTheme.textPrimary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(entry.isCurrentUser ? AuroraTheme.auroraTeal.opacity(0.05) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Friends List

    private var friendsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Friends")
                .font(.headline)
                .foregroundStyle(AuroraTheme.textPrimary)

            if friends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 36))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AuroraTheme.textTertiary)
                    Text("No friends yet")
                        .font(.subheadline)
                        .foregroundStyle(AuroraTheme.textSecondary)
                    Text("Add friends to compare reading habits and compete on the leaderboard")
                        .font(.caption)
                        .foregroundStyle(AuroraTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(friends) { friend in
                    friendRow(friend)
                }
            }
        }
        .padding(16)
        .auroraCard()
    }

    private func friendRow(_ friend: FriendProfile) -> some View {
        HStack(spacing: 12) {
            Text(friend.avatarEmoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(AuroraTheme.surface, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(friend.displayName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(AuroraTheme.textPrimary)
                    if friend.currentStreak > 0 {
                        HStack(spacing: 1) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text("\(friend.currentStreak)")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(AuroraTheme.auroraWarm)
                    }
                }

                if let bookTitle = friend.currentBookTitle {
                    HStack(spacing: 4) {
                        Text("Reading: \(bookTitle)")
                            .font(.caption)
                            .foregroundStyle(AuroraTheme.textSecondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 10) {
                    Label("\(friend.booksFinished) books", systemImage: "book.closed.circle.fill")
                    Label("\(friend.totalReadingMinutes / 60)h read", systemImage: "clock.circle.fill")
                }
                .font(.caption2)
                .foregroundStyle(AuroraTheme.textTertiary)
                .symbolRenderingMode(.hierarchical)
            }

            Spacer()

            // Activity indicator
            Circle()
                .fill(friend.isActiveToday ? AuroraTheme.auroraGreen : AuroraTheme.textTertiary.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Invite Section

    private var inviteSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AuroraTheme.auroraTeal)

            Text("Invite Friends")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AuroraTheme.textPrimary)

            Text("Share Aurora Reader with friends and compare your reading habits together")
                .font(.caption)
                .foregroundStyle(AuroraTheme.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                // Share sheet
            } label: {
                Label("Share Invite Link", systemImage: "link.circle.fill")
            }
            .buttonStyle(AuroraButtonStyle())
        }
        .padding(20)
        .auroraCard()
    }

    // MARK: - Helpers

    private func addFriend() {
        guard !friendUsername.isEmpty else { return }
        let friend = FriendProfile(username: friendUsername, displayName: friendUsername)
        modelContext.insert(friend)
        try? modelContext.save()
        friendUsername = ""
    }

    private func buildLeaderboard() -> [LeaderboardEntry] {
        var entries: [LeaderboardEntry] = []

        // Add current user
        let userValue: Int
        switch selectedMetric {
        case .pagesThisWeek:
            let weekStats = ReadingStatsService.weeklyStats(sessions: sessions)
            userValue = weekStats.totalPages
        case .minutesThisWeek:
            let weekStats = ReadingStatsService.weeklyStats(sessions: sessions)
            userValue = weekStats.totalMinutes
        case .booksThisMonth:
            userValue = 0
        case .currentStreak:
            userValue = streak?.currentStreak ?? 0
        }

        entries.append(LeaderboardEntry(
            rank: 0,
            displayName: "You",
            avatarEmoji: "📚",
            value: userValue,
            metric: selectedMetric,
            isCurrentUser: true
        ))

        // Add friends
        for friend in friends {
            let friendValue: Int
            switch selectedMetric {
            case .pagesThisWeek: friendValue = friend.pagesReadThisWeek
            case .minutesThisWeek: friendValue = friend.totalReadingMinutes / 4
            case .booksThisMonth: friendValue = friend.booksReadThisMonth
            case .currentStreak: friendValue = friend.currentStreak
            }

            entries.append(LeaderboardEntry(
                rank: 0,
                displayName: friend.displayName,
                avatarEmoji: friend.avatarEmoji,
                value: friendValue,
                metric: selectedMetric,
                isCurrentUser: false
            ))
        }

        return entries.sorted { $0.value > $1.value }
    }
}
