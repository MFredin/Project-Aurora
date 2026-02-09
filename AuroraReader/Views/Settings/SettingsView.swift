import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @Query private var books: [Book]
    @Query private var highlights: [Highlight]
    @Query private var vocabEntries: [VocabularyEntry]
    @State private var cloudManager = CloudStorageManager.shared
    @State private var goodreadsService = GoodReadsService.shared
    @State private var syncService = SyncService.shared
    @State private var metadataService = MetadataService.shared

    private var currentPreferences: UserPreferences {
        if let existing = preferences.first {
            return existing
        }
        let prefs = UserPreferences()
        modelContext.insert(prefs)
        try? modelContext.save()
        return prefs
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraTheme.deepSpace.ignoresSafeArea()

                List {
                    // Library Stats
                    Section {
                        statRow("Total Books", value: "\(books.count)")
                        statRow("Highlights", value: "\(highlights.count)")
                        statRow("Vocabulary Words", value: "\(vocabEntries.count)")
                        let categories = Dictionary(grouping: books) { $0.bookFormat.category }
                        ForEach(BookFormat.FormatCategory.allCases, id: \.self) { category in
                            let count = categories[category]?.count ?? 0
                            if count > 0 {
                                statRow(category.rawValue, value: "\(count)")
                            }
                        }
                    } header: {
                        Text("Library").foregroundStyle(AuroraTheme.auroraTeal)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // iCloud Sync
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: syncService.syncStatus.iconName)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(syncStatusColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("iCloud Sync")
                                    .foregroundStyle(AuroraTheme.textPrimary)
                                Text(syncService.isSyncEnabled ? syncService.syncStatus.rawValue : "Disabled")
                                    .font(.caption)
                                    .foregroundStyle(AuroraTheme.textTertiary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { syncService.isSyncEnabled },
                                set: { enabled in
                                    if enabled { syncService.enableSync() }
                                    else { syncService.disableSync() }
                                }
                            ))
                            .tint(AuroraTheme.auroraTeal)
                            .labelsHidden()
                        }

                        if syncService.isSyncEnabled {
                            HStack {
                                Text("Last Synced")
                                    .foregroundStyle(AuroraTheme.textPrimary)
                                Spacer()
                                Text(syncService.lastSyncText)
                                    .foregroundStyle(AuroraTheme.textSecondary)
                            }

                            Button {
                                Task { await syncService.performSync() }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Sync Now")
                                }
                                .foregroundStyle(AuroraTheme.auroraTeal)
                            }
                        }
                    } header: {
                        Text("Sync").foregroundStyle(AuroraTheme.auroraTeal)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // Features
                    Section {
                        NavigationLink {
                            VocabularyListView()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "text.book.closed.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(AuroraTheme.auroraTeal)
                                    .frame(width: 24)
                                Text("Vocabulary Builder")
                                    .foregroundStyle(AuroraTheme.textPrimary)
                                Spacer()
                                Text("\(vocabEntries.count) words")
                                    .font(.caption)
                                    .foregroundStyle(AuroraTheme.textTertiary)
                            }
                        }

                        NavigationLink {
                            BookClubView()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "person.3.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(AuroraTheme.auroraPurple)
                                    .frame(width: 24)
                                Text("Book Clubs")
                                    .foregroundStyle(AuroraTheme.textPrimary)
                            }
                        }

                        NavigationLink {
                            GoodReadsView()
                        } label: {
                            HStack(spacing: 10) {
                                BrandAssets.BrandIcon(brand: .goodReads, size: 24)
                                Text("GoodReads")
                                    .foregroundStyle(AuroraTheme.textPrimary)
                                Spacer()
                                Text(goodreadsService.isAuthenticated ? "Connected" : "Not Connected")
                                    .font(.caption)
                                    .foregroundStyle(goodreadsService.isAuthenticated ? AuroraTheme.auroraGreen : AuroraTheme.textTertiary)
                            }
                        }
                    } header: {
                        Text("Features").foregroundStyle(AuroraTheme.auroraTeal)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // Smart Import
                    Section {
                        Button {
                            Task {
                                await metadataService.enrichLibrary(books: books, modelContext: modelContext)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkle.magnifyingglass")
                                    .foregroundStyle(AuroraTheme.auroraGreen)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Enrich Library Metadata")
                                        .foregroundStyle(AuroraTheme.textPrimary)
                                    Text("Auto-fetch covers, ISBNs, and ratings")
                                        .font(.caption)
                                        .foregroundStyle(AuroraTheme.textTertiary)
                                }
                                Spacer()
                                if metadataService.isEnriching {
                                    ProgressView()
                                        .tint(AuroraTheme.auroraTeal)
                                }
                            }
                        }
                        .disabled(metadataService.isEnriching)

                        if metadataService.isEnriching {
                            ProgressView(value: metadataService.enrichmentProgress)
                                .tint(AuroraTheme.auroraGreen)
                        }
                    } header: {
                        Text("Smart Import").foregroundStyle(AuroraTheme.auroraTeal)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // Cloud Accounts
                    Section {
                        ForEach(CloudStorageProvider.allCases) { provider in
                            HStack(spacing: 10) {
                                BrandAssets.BrandIcon(brand: BrandAssets.BrandIcon.brand(for: provider), size: 28)
                                Text(provider.displayName)
                                    .foregroundStyle(AuroraTheme.textPrimary)
                                Spacer()
                                Text(cloudManager.isConnected(provider) ? "Connected" : "Not Connected")
                                    .font(.caption)
                                    .foregroundStyle(cloudManager.isConnected(provider) ? AuroraTheme.auroraGreen : AuroraTheme.textTertiary)
                            }
                        }
                    } header: {
                        Text("Cloud Storage").foregroundStyle(AuroraTheme.auroraTeal)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // Reader Settings
                    Section {
                        NavigationLink {
                            ReaderSettingsSheet(preferences: currentPreferences)
                        } label: {
                            HStack {
                                Text("Font").foregroundStyle(AuroraTheme.textPrimary)
                                Spacer()
                                Text(currentPreferences.fontFamily).foregroundStyle(AuroraTheme.textSecondary)
                            }
                        }
                        HStack {
                            Text("Font Size").foregroundStyle(AuroraTheme.textPrimary)
                            Spacer()
                            Text("\(Int(currentPreferences.fontSizeRaw))pt").foregroundStyle(AuroraTheme.textSecondary)
                        }
                        HStack {
                            Text("Theme").foregroundStyle(AuroraTheme.textPrimary)
                            Spacer()
                            Text(currentPreferences.theme.displayName).foregroundStyle(AuroraTheme.textSecondary)
                        }
                    } header: {
                        Text("Default Reader Settings").foregroundStyle(AuroraTheme.auroraTeal)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // Supported Formats
                    Section {
                        ForEach(BookFormat.FormatCategory.allCases, id: \.self) { category in
                            let formats = BookFormat.allCases.filter { $0.category == category }
                            ForEach(formats, id: \.self) { format in
                                HStack {
                                    Image(systemName: format.iconName)
                                        .foregroundStyle(AuroraTheme.auroraTeal)
                                        .frame(width: 24)
                                    VStack(alignment: .leading) {
                                        Text(format.displayName)
                                            .foregroundStyle(AuroraTheme.textPrimary)
                                        Text(format.formatDescription)
                                            .font(.caption)
                                            .foregroundStyle(AuroraTheme.textTertiary)
                                    }
                                    Spacer()
                                    Text(".\(format.fileExtension)")
                                        .font(.caption)
                                        .foregroundStyle(AuroraTheme.textSecondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AuroraTheme.auroraPurple.opacity(0.15), in: Capsule())
                                }
                            }
                        }
                    } header: {
                        Text("Supported Formats (\(BookFormat.allCases.count))").foregroundStyle(AuroraTheme.auroraTeal)
                    }
                    .listRowBackground(AuroraTheme.surface)

                    // About
                    Section {
                        HStack {
                            Text("App").foregroundStyle(AuroraTheme.textPrimary)
                            Spacer()
                            Text("Aurora Reader").foregroundStyle(AuroraTheme.textSecondary)
                        }
                        HStack {
                            Text("Version").foregroundStyle(AuroraTheme.textPrimary)
                            Spacer()
                            Text("3.0.0").foregroundStyle(AuroraTheme.textSecondary)
                        }
                    } header: {
                        Text("About").foregroundStyle(AuroraTheme.auroraTeal)
                    }
                    .listRowBackground(AuroraTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(AuroraTheme.textPrimary)
            Spacer()
            Text(value).foregroundStyle(AuroraTheme.auroraTeal)
        }
    }

    private var syncStatusColor: Color {
        switch syncService.syncStatus {
        case .idle: return AuroraTheme.auroraGreen
        case .syncing: return AuroraTheme.auroraBlue
        case .error: return AuroraTheme.auroraWarm
        case .conflict: return AuroraTheme.auroraWarm
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [
            Book.self, ReadingProgress.self, Bookmark.self, UserPreferences.self,
            Highlight.self, VocabularyEntry.self
        ], inMemory: true)
}
