import Foundation
import SwiftData
import UIKit

// MARK: - Sync Payload Types

/// Codable snapshot of a reading position for iCloud sync
struct ReadingPositionPayload: Codable, Equatable {
    let bookId: String
    let currentChapter: Int
    let currentPage: Int
    let totalPages: Int
    let scrollOffset: Double
    let progressPercentage: Double
    let lastReadDate: Date
    let timestamp: Date

    init(bookId: UUID, progress: ReadingProgress) {
        self.bookId = bookId.uuidString
        self.currentChapter = progress.currentChapter
        self.currentPage = progress.currentPage
        self.totalPages = progress.totalPages
        self.scrollOffset = 0
        self.progressPercentage = progress.progressPercentage
        self.lastReadDate = progress.lastReadDate
        self.timestamp = Date()
    }
}

/// Codable snapshot of a bookmark for iCloud sync
struct BookmarkPayload: Codable, Equatable {
    let id: String
    let title: String
    let chapter: Int
    let page: Int
    let textSnippet: String
    let dateCreated: Date
    let color: String
    let timestamp: Date

    init(bookmark: Bookmark) {
        self.id = bookmark.id.uuidString
        self.title = bookmark.title
        self.chapter = bookmark.chapter
        self.page = bookmark.page
        self.textSnippet = bookmark.textSnippet
        self.dateCreated = bookmark.dateCreated
        self.color = bookmark.color
        self.timestamp = Date()
    }
}

/// Codable snapshot of a highlight for iCloud sync
struct HighlightPayload: Codable, Equatable {
    let id: String
    let highlightedText: String
    let note: String
    let colorRaw: String
    let chapterIndex: Int
    let chapterTitle: String
    let rangeStart: Int
    let rangeLength: Int
    let dateCreated: Date
    let dateModified: Date
    let tags: [String]
    let timestamp: Date

    init(highlight: Highlight) {
        self.id = highlight.id.uuidString
        self.highlightedText = highlight.highlightedText
        self.note = highlight.note
        self.colorRaw = highlight.colorRaw
        self.chapterIndex = highlight.chapterIndex
        self.chapterTitle = highlight.chapterTitle
        self.rangeStart = highlight.rangeStart
        self.rangeLength = highlight.rangeLength
        self.dateCreated = highlight.dateCreated
        self.dateModified = highlight.dateModified
        self.tags = highlight.tags
        self.timestamp = Date()
    }
}

/// Codable snapshot of user preferences for iCloud sync
struct PreferencesPayload: Codable, Equatable {
    let fontSizeRaw: Double
    let fontFamily: String
    let lineSpacing: Double
    let marginSize: Double
    let themeRaw: String
    let brightnessOverride: Double?
    let isScrollModeEnabled: Bool
    let keepScreenAwake: Bool
    let timestamp: Date

    init(preferences: UserPreferences) {
        self.fontSizeRaw = preferences.fontSizeRaw
        self.fontFamily = preferences.fontFamily
        self.lineSpacing = preferences.lineSpacing
        self.marginSize = preferences.marginSize
        self.themeRaw = preferences.themeRaw
        self.brightnessOverride = preferences.brightnessOverride
        self.isScrollModeEnabled = preferences.isScrollModeEnabled
        self.keepScreenAwake = preferences.keepScreenAwake
        self.timestamp = Date()
    }
}

/// Aggregated sync payload for a single book
struct BookSyncPayload: Codable {
    let bookId: String
    let bookTitle: String
    let readingPosition: ReadingPositionPayload?
    let bookmarks: [BookmarkPayload]
    let highlights: [HighlightPayload]
    let timestamp: Date
}

/// Represents a detected conflict between local and remote data
struct SyncConflict: Identifiable {
    let id = UUID()
    let bookId: UUID
    let bookTitle: String
    let dataType: SyncDataType
    let localTimestamp: Date
    let remoteTimestamp: Date
    var resolution: ConflictResolution = .pending

    enum SyncDataType: String {
        case readingPosition = "Reading Position"
        case bookmarks = "Bookmarks"
        case highlights = "Highlights"
        case preferences = "Preferences"
    }

    enum ConflictResolution {
        case pending
        case useLocal
        case useRemote
    }
}

/// Errors specific to sync operations
enum SyncError: LocalizedError {
    case syncDisabled
    case encodingFailed(String)
    case decodingFailed(String)
    case storageLimitExceeded
    case noDataForBook(UUID)
    case modelContextUnavailable

    var errorDescription: String? {
        switch self {
        case .syncDisabled:
            return "iCloud sync is not enabled"
        case .encodingFailed(let detail):
            return "Failed to encode sync data: \(detail)"
        case .decodingFailed(let detail):
            return "Failed to decode sync data: \(detail)"
        case .storageLimitExceeded:
            return "iCloud key-value storage limit exceeded (1MB)"
        case .noDataForBook(let id):
            return "No sync data found for book \(id.uuidString)"
        case .modelContextUnavailable:
            return "SwiftData model context is unavailable"
        }
    }
}

// MARK: - iCloud Sync Service

/// iCloud sync service using NSUbiquitousKeyValueStore for reading positions,
/// bookmarks, highlights, and user preferences
@MainActor @Observable
final class SyncService {
    static let shared = SyncService()

    // MARK: - Published State

    var isSyncEnabled: Bool = false
    var lastSyncDate: Date?
    var syncStatus: SyncStatus = .idle
    var syncProgress: Double = 0
    var conflictCount: Int = 0
    var pendingConflicts: [SyncConflict] = []
    var lastError: SyncError?

    // MARK: - Private Properties

    private let syncKey = "aurora_sync_enabled"
    private let lastSyncKey = "aurora_last_sync"
    private let preferencesCloudKey = "aurora_preferences"

    private let ubiquitousStore = NSUbiquitousKeyValueStore.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Conflict resolution strategy
    var conflictStrategy: ConflictStrategy = .lastWriterWins

    enum ConflictStrategy: String, CaseIterable {
        case lastWriterWins = "Last Writer Wins"
        case alwaysLocal = "Always Keep Local"
        case alwaysRemote = "Always Keep Remote"
        case askUser = "Ask Me"
    }

    // MARK: - Key Prefixes for NSUbiquitousKeyValueStore

    private enum CloudKey {
        static let readingPositionPrefix = "aurora_pos_"
        static let bookmarksPrefix = "aurora_bm_"
        static let highlightsPrefix = "aurora_hl_"
        static let preferences = "aurora_prefs"
        static let bookManifest = "aurora_manifest"

        static func readingPosition(for bookId: UUID) -> String {
            "\(readingPositionPrefix)\(bookId.uuidString)"
        }

        static func bookmarks(for bookId: UUID) -> String {
            "\(bookmarksPrefix)\(bookId.uuidString)"
        }

        static func highlights(for bookId: UUID) -> String {
            "\(highlightsPrefix)\(bookId.uuidString)"
        }
    }

    // MARK: - Initialization

    private init() {
        isSyncEnabled = UserDefaults.standard.bool(forKey: syncKey)
        if let timestamp = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            lastSyncDate = timestamp
        }

        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if isSyncEnabled {
            registerForRemoteNotifications()
            ubiquitousStore.synchronize()
        }
    }

    // MARK: - Remote Change Notification

    /// Registers for iCloud KVS external change notifications
    private func registerForRemoteNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: ubiquitousStore,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleRemoteChange(notification: notification)
            }
        }
    }

    /// Removes notification observer when sync is disabled
    private func unregisterFromRemoteNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: ubiquitousStore
        )
    }

    /// Handles incoming remote changes from other devices
    private func handleRemoteChange(notification: Notification) {
        guard isSyncEnabled else { return }

        let reasonKey = NSUbiquitousKeyValueStoreChangeReasonKey
        guard let userInfo = notification.userInfo,
              let reason = userInfo[reasonKey] as? Int else {
            return
        }

        switch reason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange:
            // Remote data changed or initial sync completed
            if let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
                processRemoteChangedKeys(changedKeys)
            }

        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            syncStatus = .error
            lastError = .storageLimitExceeded

        case NSUbiquitousKeyValueStoreAccountChange:
            // iCloud account changed, re-sync everything
            syncStatus = .pendingFullSync

        default:
            break
        }
    }

    /// Processes specific keys that changed remotely
    private func processRemoteChangedKeys(_ keys: [String]) {
        var hasConflicts = false

        for key in keys {
            if key.hasPrefix(CloudKey.readingPositionPrefix) {
                // A reading position changed remotely
                hasConflicts = true
            } else if key.hasPrefix(CloudKey.bookmarksPrefix) {
                hasConflicts = true
            } else if key.hasPrefix(CloudKey.highlightsPrefix) {
                hasConflicts = true
            } else if key == CloudKey.preferences {
                // Preferences changed remotely
                hasConflicts = true
            }
        }

        if hasConflicts && conflictStrategy == .askUser {
            syncStatus = .conflict
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            // Auto-resolve based on strategy; full sync will apply changes
            syncStatus = .pendingFullSync
        }
    }

    // MARK: - Sync Control

    /// Enables iCloud sync and triggers initial synchronization
    func enableSync() {
        isSyncEnabled = true
        UserDefaults.standard.set(true, forKey: syncKey)
        syncStatus = .syncing

        registerForRemoteNotifications()
        ubiquitousStore.synchronize()

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            await performSync()
        }
    }

    /// Disables iCloud sync
    func disableSync() {
        isSyncEnabled = false
        UserDefaults.standard.set(false, forKey: syncKey)
        syncStatus = .idle
        pendingConflicts = []
        conflictCount = 0

        unregisterFromRemoteNotifications()

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Forces a full sync cycle
    func forceSync() async {
        guard isSyncEnabled else { return }
        ubiquitousStore.synchronize()
        await performSync()
    }

    // MARK: - Core Sync Operations

    /// Performs a full sync cycle: pushes local data and pulls remote changes for all books
    func performSync(modelContext: ModelContext? = nil) async {
        guard isSyncEnabled else {
            syncStatus = .idle
            return
        }

        syncStatus = .syncing
        syncProgress = 0
        lastError = nil

        guard let context = modelContext else {
            // Without a model context, we can only sync preferences from UserDefaults
            syncProgress = 0.8
            syncPreferencesFromDefaults()
            syncProgress = 1.0
            finalizeSyncCycle()
            return
        }

        do {
            // Step 1: Fetch all books from SwiftData
            syncProgress = 0.1
            let descriptor = FetchDescriptor<Book>()
            let books = try context.fetch(descriptor)

            guard !books.isEmpty else {
                syncProgress = 1.0
                finalizeSyncCycle()
                return
            }

            let progressIncrement = 0.7 / Double(books.count)

            // Step 2: Sync each book's data
            for (index, book) in books.enumerated() {
                try syncBookData(book, modelContext: context)
                try applyRemoteChanges(to: book, modelContext: context)
                syncProgress = 0.1 + progressIncrement * Double(index + 1)
            }

            // Step 3: Sync user preferences
            syncProgress = 0.85
            try syncUserPreferences(modelContext: context)

            // Step 4: Update manifest of synced book IDs
            syncProgress = 0.95
            updateBookManifest(books: books)

            // Step 5: Push all changes
            ubiquitousStore.synchronize()

            syncProgress = 1.0
            try context.save()
            finalizeSyncCycle()

        } catch let error as SyncError {
            lastError = error
            syncStatus = .error
            syncProgress = 0
        } catch {
            lastError = .encodingFailed(error.localizedDescription)
            syncStatus = .error
            syncProgress = 0
        }
    }

    /// Syncs a single book's data to iCloud (push local -> remote)
    func syncBookData(_ book: Book, modelContext: ModelContext) throws {
        guard isSyncEnabled else { throw SyncError.syncDisabled }

        // Sync reading position
        if let progress = book.readingProgress {
            let payload = ReadingPositionPayload(bookId: book.id, progress: progress)
            let key = CloudKey.readingPosition(for: book.id)

            if shouldPushLocal(key: key, localTimestamp: payload.timestamp) {
                let data = try encodePayload(payload)
                ubiquitousStore.set(data, forKey: key)
            }
        }

        // Sync bookmarks
        if !book.bookmarks.isEmpty {
            let payloads = book.bookmarks.map { BookmarkPayload(bookmark: $0) }
            let key = CloudKey.bookmarks(for: book.id)
            let data = try encodePayload(payloads)
            ubiquitousStore.set(data, forKey: key)
        }

        // Sync highlights
        if !book.highlights.isEmpty {
            let payloads = book.highlights.map { HighlightPayload(highlight: $0) }
            let key = CloudKey.highlights(for: book.id)
            let data = try encodePayload(payloads)
            ubiquitousStore.set(data, forKey: key)
        }
    }

    /// Applies remote changes from iCloud to a local book
    func applyRemoteChanges(to book: Book, modelContext: ModelContext) throws {
        guard isSyncEnabled else { throw SyncError.syncDisabled }

        // Apply remote reading position
        try applyRemoteReadingPosition(to: book, modelContext: modelContext)

        // Apply remote bookmarks
        try applyRemoteBookmarks(to: book, modelContext: modelContext)

        // Apply remote highlights
        try applyRemoteHighlights(to: book, modelContext: modelContext)
    }

    // MARK: - Reading Position Sync

    /// Applies a remote reading position to a local book, with conflict resolution
    private func applyRemoteReadingPosition(to book: Book, modelContext: ModelContext) throws {
        let key = CloudKey.readingPosition(for: book.id)
        guard let data = ubiquitousStore.data(forKey: key) else { return }

        let remotePayload: ReadingPositionPayload = try decodePayload(data)
        let localProgress = book.readingProgress

        // Determine if remote is newer or if we need manual resolution
        let resolution = resolveTimestamp(
            localDate: localProgress?.lastReadDate,
            remoteDate: remotePayload.lastReadDate,
            bookId: book.id,
            bookTitle: book.title,
            dataType: .readingPosition
        )

        switch resolution {
        case .useRemote:
            if let progress = localProgress {
                progress.updateProgress(
                    chapter: remotePayload.currentChapter,
                    page: remotePayload.currentPage,
                    totalPages: remotePayload.totalPages
                )
            } else {
                let newProgress = ReadingProgress(
                    currentChapter: remotePayload.currentChapter,
                    currentPage: remotePayload.currentPage,
                    totalPages: remotePayload.totalPages
                )
                modelContext.insert(newProgress)
                book.readingProgress = newProgress
            }

        case .useLocal:
            // Local is newer, push local back to iCloud
            if let progress = localProgress {
                let payload = ReadingPositionPayload(bookId: book.id, progress: progress)
                let encoded = try encodePayload(payload)
                ubiquitousStore.set(encoded, forKey: key)
            }

        case .askUser:
            let conflict = SyncConflict(
                bookId: book.id,
                bookTitle: book.title,
                dataType: .readingPosition,
                localTimestamp: localProgress?.lastReadDate ?? .distantPast,
                remoteTimestamp: remotePayload.lastReadDate
            )
            pendingConflicts.append(conflict)
            conflictCount = pendingConflicts.count
        }
    }

    // MARK: - Bookmark Sync

    /// Applies remote bookmarks to a local book with merge strategy
    private func applyRemoteBookmarks(to book: Book, modelContext: ModelContext) throws {
        let key = CloudKey.bookmarks(for: book.id)
        guard let data = ubiquitousStore.data(forKey: key) else { return }

        let remotePayloads: [BookmarkPayload] = try decodePayload(data)
        let localBookmarkIds = Set(book.bookmarks.map { $0.id.uuidString })
        let remoteBookmarkIds = Set(remotePayloads.map { $0.id })

        // Merge strategy: union of both sets, with last-writer-wins for duplicates
        for remotePayload in remotePayloads {
            if localBookmarkIds.contains(remotePayload.id) {
                // Bookmark exists locally -- update if remote is newer
                if let localBookmark = book.bookmarks.first(where: { $0.id.uuidString == remotePayload.id }) {
                    if remotePayload.timestamp > localBookmark.dateCreated {
                        localBookmark.title = remotePayload.title
                        localBookmark.chapter = remotePayload.chapter
                        localBookmark.page = remotePayload.page
                        localBookmark.textSnippet = remotePayload.textSnippet
                        localBookmark.color = remotePayload.color
                    }
                }
            } else {
                // Bookmark only exists remotely -- add locally
                let newBookmark = Bookmark(
                    title: remotePayload.title,
                    chapter: remotePayload.chapter,
                    page: remotePayload.page,
                    textSnippet: remotePayload.textSnippet,
                    color: remotePayload.color
                )
                modelContext.insert(newBookmark)
                book.bookmarks.append(newBookmark)
            }
        }

        // Bookmarks that were deleted remotely (exist locally but not in remote)
        // Only remove if we have evidence of prior sync (remote data exists)
        if !remotePayloads.isEmpty {
            let bookmarksToRemove = book.bookmarks.filter { !remoteBookmarkIds.contains($0.id.uuidString) }
            for bookmark in bookmarksToRemove {
                // Check timestamp: only delete if the remote data is newer than local creation
                if let latestRemoteTimestamp = remotePayloads.map({ $0.timestamp }).max(),
                   latestRemoteTimestamp > bookmark.dateCreated {
                    book.bookmarks.removeAll { $0.id == bookmark.id }
                    modelContext.delete(bookmark)
                }
            }
        }
    }

    // MARK: - Highlight Sync

    /// Applies remote highlights to a local book with merge strategy
    private func applyRemoteHighlights(to book: Book, modelContext: ModelContext) throws {
        let key = CloudKey.highlights(for: book.id)
        guard let data = ubiquitousStore.data(forKey: key) else { return }

        let remotePayloads: [HighlightPayload] = try decodePayload(data)
        let localHighlightIds = Set(book.highlights.map { $0.id.uuidString })
        let remoteHighlightIds = Set(remotePayloads.map { $0.id })

        // Merge strategy: union of both sets, with last-writer-wins for duplicates
        for remotePayload in remotePayloads {
            if localHighlightIds.contains(remotePayload.id) {
                // Highlight exists locally -- update if remote is newer
                if let localHighlight = book.highlights.first(where: { $0.id.uuidString == remotePayload.id }) {
                    if remotePayload.dateModified > localHighlight.dateModified {
                        localHighlight.highlightedText = remotePayload.highlightedText
                        localHighlight.note = remotePayload.note
                        localHighlight.colorRaw = remotePayload.colorRaw
                        localHighlight.chapterIndex = remotePayload.chapterIndex
                        localHighlight.chapterTitle = remotePayload.chapterTitle
                        localHighlight.rangeStart = remotePayload.rangeStart
                        localHighlight.rangeLength = remotePayload.rangeLength
                        localHighlight.dateModified = remotePayload.dateModified
                        localHighlight.tags = remotePayload.tags
                    }
                }
            } else {
                // Highlight only exists remotely -- add locally
                let newHighlight = Highlight(
                    highlightedText: remotePayload.highlightedText,
                    note: remotePayload.note,
                    color: HighlightColor(rawValue: remotePayload.colorRaw) ?? .auroraTeal,
                    chapterIndex: remotePayload.chapterIndex,
                    chapterTitle: remotePayload.chapterTitle,
                    rangeStart: remotePayload.rangeStart,
                    rangeLength: remotePayload.rangeLength
                )
                newHighlight.tags = remotePayload.tags
                modelContext.insert(newHighlight)
                book.highlights.append(newHighlight)
            }
        }

        // Highlights deleted remotely
        if !remotePayloads.isEmpty {
            let highlightsToRemove = book.highlights.filter { !remoteHighlightIds.contains($0.id.uuidString) }
            for highlight in highlightsToRemove {
                if let latestRemoteTimestamp = remotePayloads.map({ $0.timestamp }).max(),
                   latestRemoteTimestamp > highlight.dateModified {
                    book.highlights.removeAll { $0.id == highlight.id }
                    modelContext.delete(highlight)
                }
            }
        }
    }

    // MARK: - Preferences Sync

    /// Syncs user preferences bidirectionally with iCloud
    private func syncUserPreferences(modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<UserPreferences>()
        guard let localPrefs = (try? modelContext.fetch(descriptor))?.first else { return }

        let localPayload = PreferencesPayload(preferences: localPrefs)

        if let remoteData = ubiquitousStore.data(forKey: CloudKey.preferences) {
            let remotePayload: PreferencesPayload = try decodePayload(remoteData)

            if remotePayload.timestamp > localPayload.timestamp {
                // Remote is newer, apply to local
                applyPreferencesPayload(remotePayload, to: localPrefs)
            } else {
                // Local is newer, push to remote
                let data = try encodePayload(localPayload)
                ubiquitousStore.set(data, forKey: CloudKey.preferences)
            }
        } else {
            // No remote preferences yet, push local
            let data = try encodePayload(localPayload)
            ubiquitousStore.set(data, forKey: CloudKey.preferences)
        }
    }

    /// Lightweight preferences sync without SwiftData context (from UserDefaults)
    private func syncPreferencesFromDefaults() {
        // Trigger KVS sync for preferences that may have changed
        ubiquitousStore.synchronize()
    }

    /// Applies a remote preferences payload to local UserPreferences model
    private func applyPreferencesPayload(_ payload: PreferencesPayload, to prefs: UserPreferences) {
        prefs.fontSizeRaw = payload.fontSizeRaw
        prefs.fontFamily = payload.fontFamily
        prefs.lineSpacing = payload.lineSpacing
        prefs.marginSize = payload.marginSize
        prefs.themeRaw = payload.themeRaw
        prefs.brightnessOverride = payload.brightnessOverride
        prefs.isScrollModeEnabled = payload.isScrollModeEnabled
        prefs.keepScreenAwake = payload.keepScreenAwake
    }

    // MARK: - Book Manifest

    /// Stores the list of synced book IDs so other devices know which books exist
    private func updateBookManifest(books: [Book]) {
        let manifest = books.map { $0.id.uuidString }
        if let data = try? encoder.encode(manifest) {
            ubiquitousStore.set(data, forKey: CloudKey.bookManifest)
        }
    }

    /// Returns the list of book IDs known to iCloud
    func remoteBookManifest() -> [UUID] {
        guard let data = ubiquitousStore.data(forKey: CloudKey.bookManifest),
              let ids = try? decoder.decode([String].self, from: data) else {
            return []
        }
        return ids.compactMap { UUID(uuidString: $0) }
    }

    // MARK: - Conflict Resolution

    /// Determines whether to push local data or accept remote based on timestamps
    private func resolveTimestamp(
        localDate: Date?,
        remoteDate: Date,
        bookId: UUID,
        bookTitle: String,
        dataType: SyncConflict.SyncDataType
    ) -> ConflictAction {
        let local = localDate ?? .distantPast

        switch conflictStrategy {
        case .lastWriterWins:
            return remoteDate > local ? .useRemote : .useLocal

        case .alwaysLocal:
            return .useLocal

        case .alwaysRemote:
            return .useRemote

        case .askUser:
            // If timestamps differ significantly (>2 seconds), ask user
            if abs(remoteDate.timeIntervalSince(local)) > 2.0 {
                return .askUser
            }
            // Near-simultaneous edits, use last writer wins as fallback
            return remoteDate > local ? .useRemote : .useLocal
        }
    }

    private enum ConflictAction {
        case useLocal
        case useRemote
        case askUser
    }

    /// Determines if local data should be pushed (local is newer than remote)
    private func shouldPushLocal(key: String, localTimestamp: Date) -> Bool {
        guard let remoteData = ubiquitousStore.data(forKey: key) else {
            return true // No remote data, always push
        }

        // Try to extract timestamp from remote data
        struct TimestampOnly: Codable {
            let timestamp: Date
        }

        if let remote = try? decoder.decode(TimestampOnly.self, from: remoteData) {
            return localTimestamp > remote.timestamp
        }

        return true // Can't read remote timestamp, push local
    }

    /// Resolves a pending conflict with user choice
    func resolveConflict(_ conflict: SyncConflict, preferLocal: Bool, modelContext: ModelContext? = nil) {
        conflict.resolution = preferLocal ? .useLocal : .useRemote

        pendingConflicts.removeAll { $0.id == conflict.id }
        conflictCount = pendingConflicts.count

        if pendingConflicts.isEmpty {
            syncStatus = .idle
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // If user chose remote and we have a model context, trigger re-sync for that book
        if !preferLocal, let context = modelContext {
            Task {
                let descriptor = FetchDescriptor<Book>()
                if let books = try? context.fetch(descriptor),
                   let book = books.first(where: { $0.id == conflict.bookId }) {
                    try? applyRemoteChanges(to: book, modelContext: context)
                    try? context.save()
                }
            }
        }
    }

    /// Resolves a sync conflict by choosing local or remote version (legacy compatibility)
    func resolveConflict(preferLocal: Bool) {
        guard let conflict = pendingConflicts.first else {
            conflictCount = max(0, conflictCount - 1)
            return
        }
        resolveConflict(conflict, preferLocal: preferLocal)
    }

    // MARK: - Sync Snapshot

    /// Creates a snapshot of syncable data for a book
    func createSyncSnapshot(for book: Book) -> SyncSnapshot {
        SyncSnapshot(
            bookId: book.id,
            bookTitle: book.title,
            currentChapter: book.readingProgress?.currentChapter ?? 0,
            currentPage: book.readingProgress?.currentPage ?? 0,
            totalPages: book.readingProgress?.totalPages ?? 0,
            progressPercentage: book.readingProgress?.progressPercentage ?? 0,
            bookmarkCount: book.bookmarks.count,
            highlightCount: book.highlights.count,
            lastModified: book.readingProgress?.lastReadDate ?? book.dateAdded,
            isSyncedToCloud: hasSyncData(for: book.id)
        )
    }

    /// Checks if iCloud has any sync data for a given book
    func hasSyncData(for bookId: UUID) -> Bool {
        ubiquitousStore.data(forKey: CloudKey.readingPosition(for: bookId)) != nil ||
        ubiquitousStore.data(forKey: CloudKey.bookmarks(for: bookId)) != nil ||
        ubiquitousStore.data(forKey: CloudKey.highlights(for: bookId)) != nil
    }

    /// Removes all iCloud data for a specific book
    func removeSyncData(for bookId: UUID) {
        ubiquitousStore.removeObject(forKey: CloudKey.readingPosition(for: bookId))
        ubiquitousStore.removeObject(forKey: CloudKey.bookmarks(for: bookId))
        ubiquitousStore.removeObject(forKey: CloudKey.highlights(for: bookId))
        ubiquitousStore.synchronize()
    }

    // MARK: - Helpers

    /// Encodes a Codable payload to Data
    private func encodePayload<T: Encodable>(_ payload: T) throws -> Data {
        do {
            return try encoder.encode(payload)
        } catch {
            throw SyncError.encodingFailed(String(describing: T.self))
        }
    }

    /// Decodes Data to a Codable payload
    private func decodePayload<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw SyncError.decodingFailed(String(describing: T.self))
        }
    }

    /// Completes the sync cycle and updates timestamps
    private func finalizeSyncCycle() {
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)

        if pendingConflicts.isEmpty {
            syncStatus = .idle
        } else {
            syncStatus = .conflict
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Display Helpers

    var lastSyncText: String {
        guard let date = lastSyncDate else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var syncStatusDescription: String {
        switch syncStatus {
        case .idle:
            return "All data is up to date across your devices."
        case .syncing:
            return "Syncing your reading data with iCloud..."
        case .error:
            return lastError?.errorDescription ?? "An unknown sync error occurred."
        case .conflict:
            return "\(conflictCount) conflict\(conflictCount == 1 ? "" : "s") need\(conflictCount == 1 ? "s" : "") your attention."
        case .pendingFullSync:
            return "Changes detected on another device. Sync will begin shortly."
        }
    }

    // MARK: - Sync Status Enum

    enum SyncStatus: String {
        case idle = "Up to date"
        case syncing = "Syncing..."
        case error = "Sync error"
        case conflict = "Conflicts found"
        case pendingFullSync = "Pending sync"

        var iconName: String {
            switch self {
            case .idle: return "checkmark.icloud.fill"
            case .syncing: return "arrow.triangle.2.circlepath.icloud.fill"
            case .error: return "exclamationmark.icloud.fill"
            case .conflict: return "exclamationmark.triangle.fill"
            case .pendingFullSync: return "arrow.clockwise.icloud.fill"
            }
        }

        var color: String {
            switch self {
            case .idle: return "green"
            case .syncing: return "blue"
            case .error: return "red"
            case .conflict: return "orange"
            case .pendingFullSync: return "yellow"
            }
        }
    }
}

// MARK: - Sync Snapshot

struct SyncSnapshot {
    let bookId: UUID
    let bookTitle: String
    let currentChapter: Int
    let currentPage: Int
    let totalPages: Int
    let progressPercentage: Double
    let bookmarkCount: Int
    let highlightCount: Int
    let lastModified: Date
    let isSyncedToCloud: Bool

    var formattedProgress: String {
        "\(Int(progressPercentage * 100))%"
    }

    var syncStatusIcon: String {
        isSyncedToCloud ? "checkmark.icloud.fill" : "icloud.slash.fill"
    }
}
