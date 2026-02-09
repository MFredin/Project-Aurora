import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var achievements: [Achievement]

    private var groupedAchievements: [(category: AchievementType.AchievementCategory, items: [Achievement])] {
        let grouped = Dictionary(grouping: achievements) { $0.type.category }
        return AchievementType.AchievementCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category: category, items: items.sorted { $0.progress > $1.progress })
        }
    }

    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var body: some View {
        ZStack {
            AuroraTheme.deepSpace.ignoresSafeArea()

            // Aurora glow
            Circle()
                .fill(AuroraTheme.auroraWarm.opacity(0.06))
                .frame(width: 350, height: 350)
                .blur(radius: 100)
                .offset(x: -50, y: -300)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Summary header
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.circle.fill")
                            .font(.system(size: 44))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AuroraTheme.auroraWarm)

                        Text("\(unlockedCount) of \(achievements.count)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AuroraTheme.textPrimary)

                        Text("Achievements Unlocked")
                            .font(.subheadline)
                            .foregroundStyle(AuroraTheme.textSecondary)

                        ProgressView(value: Double(unlockedCount), total: Double(max(achievements.count, 1)))
                            .tint(AuroraTheme.auroraWarm)
                            .padding(.horizontal, 40)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 16)

                    // Categories
                    ForEach(groupedAchievements, id: \.category) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.category.rawValue.uppercased())
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AuroraTheme.auroraTeal)
                                .tracking(1)
                                .padding(.horizontal, 4)

                            ForEach(group.items) { achievement in
                                achievementRow(achievement)
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func achievementRow(_ achievement: Achievement) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? AuroraTheme.auroraWarm.opacity(0.15) : AuroraTheme.surface)
                    .frame(width: 48, height: 48)

                Image(systemName: achievement.iconName)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(achievement.isUnlocked ? AuroraTheme.auroraWarm : AuroraTheme.textTertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(achievement.isUnlocked ? AuroraTheme.textPrimary : AuroraTheme.textSecondary)

                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(AuroraTheme.auroraGreen)
                    }
                }

                Text(achievement.descriptionText)
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.textTertiary)

                if !achievement.isUnlocked {
                    ProgressView(value: achievement.progress)
                        .tint(AuroraTheme.auroraTeal)

                    Text("\(achievement.currentValue)/\(achievement.targetValue)")
                        .font(.caption2)
                        .foregroundStyle(AuroraTheme.textTertiary)
                }
            }

            Spacer()

            if achievement.isUnlocked, let date = achievement.dateEarned {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(AuroraTheme.textTertiary)
            }
        }
        .padding(12)
        .auroraCard()
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}
