import SwiftUI
import SwiftData

/// Vocabulary builder view for reviewing saved words
struct VocabularyListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VocabularyEntry.dateAdded, order: .reverse) private var entries: [VocabularyEntry]

    @State private var filterMastery: String?
    @State private var searchText = ""

    private var filteredEntries: [VocabularyEntry] {
        var result = entries
        if let mastery = filterMastery {
            result = result.filter { $0.masteryLevel == mastery }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.word.contains(query) || $0.definition.lowercased().contains(query)
            }
        }
        return result
    }

    private var masteryStats: (new: Int, learning: Int, familiar: Int, mastered: Int) {
        let counts = Dictionary(grouping: entries, by: \.masteryLevel).mapValues(\.count)
        return (
            new: counts["New"] ?? 0,
            learning: counts["Learning"] ?? 0,
            familiar: counts["Familiar"] ?? 0,
            mastered: counts["Mastered"] ?? 0
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                if entries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statsCard
                            filterChips
                            wordsList
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Vocabulary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search words")
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        HStack(spacing: 0) {
            statItem("New", count: masteryStats.new, color: AuroraTheme.textSecondary)
            statItem("Learning", count: masteryStats.learning, color: AuroraTheme.auroraWarm)
            statItem("Familiar", count: masteryStats.familiar, color: AuroraTheme.auroraTeal)
            statItem("Mastered", count: masteryStats.mastered, color: AuroraTheme.auroraGreen)
        }
        .padding(12)
        .auroraCard()
    }

    private func statItem(_ label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AuroraTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterMastery == nil) {
                    filterMastery = nil
                }
                FilterChip(title: "New", isSelected: filterMastery == "New") {
                    filterMastery = filterMastery == "New" ? nil : "New"
                }
                FilterChip(title: "Learning", isSelected: filterMastery == "Learning", accentColor: AuroraTheme.auroraWarm) {
                    filterMastery = filterMastery == "Learning" ? nil : "Learning"
                }
                FilterChip(title: "Familiar", isSelected: filterMastery == "Familiar", accentColor: AuroraTheme.auroraTeal) {
                    filterMastery = filterMastery == "Familiar" ? nil : "Familiar"
                }
                FilterChip(title: "Mastered", isSelected: filterMastery == "Mastered", accentColor: AuroraTheme.auroraGreen) {
                    filterMastery = filterMastery == "Mastered" ? nil : "Mastered"
                }
            }
        }
    }

    // MARK: - Words List

    private var wordsList: some View {
        LazyVStack(spacing: 8) {
            ForEach(filteredEntries) { entry in
                wordRow(entry)
            }
        }
    }

    private func wordRow(_ entry: VocabularyEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.word)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AuroraTheme.textPrimary)

                Spacer()

                // Mastery indicator
                Text(entry.masteryLevel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(masteryColor(entry.masteryLevel))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(masteryColor(entry.masteryLevel).opacity(0.12), in: Capsule())
            }

            if !entry.definition.isEmpty {
                Text(entry.definition)
                    .font(.caption)
                    .foregroundStyle(AuroraTheme.textSecondary)
            }

            if !entry.context.isEmpty {
                Text(entry.context)
                    .font(.caption2)
                    .italic()
                    .foregroundStyle(AuroraTheme.textTertiary)
                    .lineLimit(2)
            }

            HStack {
                Text(entry.bookTitle)
                    .font(.caption2)
                    .foregroundStyle(AuroraTheme.textTertiary)
                Spacer()
                // Mastery progress
                ProgressView(value: entry.masteryProgress)
                    .tint(masteryColor(entry.masteryLevel))
                    .frame(width: 60)
            }
        }
        .padding(12)
        .auroraCard()
        .contextMenu {
            Button {
                entry.markReviewed()
                try? modelContext.save()
            } label: {
                Label("Mark Reviewed", systemImage: "checkmark.circle.fill")
            }
            Button(role: .destructive) {
                modelContext.delete(entry)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash.circle.fill")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.book.closed.fill")
                .font(.system(size: 44))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AuroraTheme.textTertiary)

            Text("Vocabulary Builder")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AuroraTheme.textPrimary)

            Text("Save interesting words while reading to build your vocabulary. Use the AI Companion to discover new words.")
                .font(.subheadline)
                .foregroundStyle(AuroraTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private func masteryColor(_ level: String) -> Color {
        switch level {
        case "New": return AuroraTheme.textSecondary
        case "Learning": return AuroraTheme.auroraWarm
        case "Familiar": return AuroraTheme.auroraTeal
        case "Mastered": return AuroraTheme.auroraGreen
        default: return AuroraTheme.textTertiary
        }
    }
}
