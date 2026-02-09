import Foundation
import SwiftData

/// iCloud sync service for reading position, bookmarks, annotations, and preferences
@MainActor @Observable
final class SyncService {
    static let shared = SyncService()

    var isSyncEnabled: Bool = false
    var lastSyncDate: Date?
    var syncStatus: SyncStatus = .idle
    var syncProgress: Double = 0
    var conflictCount: Int = 0

    private let syncKey = "aurora_sync_enabled"
    private let lastSyncKey = "aurora_last_sync"

    private init() {
        isSyncEnabled = UserDefaults.standard.bool(forKey: syncKey)
        if let timestamp = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            lastSyncDate = timestamp
        }
    }

    // MARK: - Sync Control

    func enableSync() {
        isSyncEnabled = true
        UserDefaults.standard.set(true, forKey: syncKey)
        syncStatus = .syncing
        // In production: configure CloudKit container
        Task {
            await performSync()
        }
    }

    func disableSync() {
        isSyncEnabled = false
        UserDefaults.standard.set(false, forKey: syncKey)
        syncStatus = .idle
    }

    // MARK: - Sync Operations

    func performSync() async {
        guard isSyncEnabled else { return }
        syncStatus = .syncing
        syncProgress = 0

        // Simulated sync stages
        syncProgress = 0.2
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Sync reading positions
        syncProgress = 0.4
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Sync bookmarks
        syncProgress = 0.6
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Sync highlights & annotations
        syncProgress = 0.8
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Sync preferences
        syncProgress = 1.0

        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
        syncStatus = .idle
    }

    /// Resolves a sync conflict by choosing local or remote version
    func resolveConflict(preferLocal: Bool) {
        conflictCount = max(0, conflictCount - 1)
        // In production: apply chosen version to CloudKit
    }

    // MARK: - Sync Data Types

    /// Creates a snapshot of syncable data for a book
    func createSyncSnapshot(for book: Book) -> SyncSnapshot {
        SyncSnapshot(
            bookId: book.id,
            bookTitle: book.title,
            currentChapter: book.readingProgress?.currentChapter ?? 0,
            currentPage: book.readingProgress?.currentPage ?? 0,
            bookmarkCount: book.bookmarks.count,
            lastModified: Date()
        )
    }

    var lastSyncText: String {
        guard let date = lastSyncDate else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    enum SyncStatus: String {
        case idle = "Up to date"
        case syncing = "Syncing..."
        case error = "Sync error"
        case conflict = "Conflicts found"

        var iconName: String {
            switch self {
            case .idle: return "checkmark.icloud.fill"
            case .syncing: return "arrow.triangle.2.circlepath.icloud.fill"
            case .error: return "exclamationmark.icloud.fill"
            case .conflict: return "exclamationmark.triangle.fill"
            }
        }

        var color: String {
            switch self {
            case .idle: return "green"
            case .syncing: return "blue"
            case .error: return "red"
            case .conflict: return "orange"
            }
        }
    }
}

struct SyncSnapshot {
    let bookId: UUID
    let bookTitle: String
    let currentChapter: Int
    let currentPage: Int
    let bookmarkCount: Int
    let lastModified: Date
}
