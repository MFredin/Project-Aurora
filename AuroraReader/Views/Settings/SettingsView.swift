import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @Query private var books: [Book]
    @State private var cloudManager = CloudStorageManager.shared
    @State private var goodreadsService = GoodReadsService.shared

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

                    // Cloud Accounts
                    Section {
                        ForEach(CloudStorageProvider.allCases) { provider in
                            HStack {
                                Image(systemName: provider.iconName)
                                    .foregroundStyle(AuroraTheme.auroraBlue)
                                    .frame(width: 24)
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

                    // GoodReads
                    Section {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(AuroraTheme.auroraWarm)
                                .frame(width: 24)
                            Text("GoodReads")
                                .foregroundStyle(AuroraTheme.textPrimary)
                            Spacer()
                            Text(goodreadsService.isAuthenticated ? "Connected" : "Not Connected")
                                .font(.caption)
                                .foregroundStyle(goodreadsService.isAuthenticated ? AuroraTheme.auroraGreen : AuroraTheme.textTertiary)
                        }
                    } header: {
                        Text("Integrations").foregroundStyle(AuroraTheme.auroraTeal)
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
                            Text("2.0.0").foregroundStyle(AuroraTheme.textSecondary)
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
}

#Preview {
    SettingsView()
        .modelContainer(for: [Book.self, ReadingProgress.self, Bookmark.self, UserPreferences.self], inMemory: true)
}
