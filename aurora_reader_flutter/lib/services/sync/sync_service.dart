import '../../core/database/database.dart';

/// Manages iCloud / cross-device sync for reading progress, bookmarks,
/// highlights, and preferences.
///
/// Uses Cloud Firestore as the sync backend with conflict resolution
/// based on last-modified timestamps.
class SyncService {
  final AppDatabase _db;

  SyncService(this._db);

  bool get isSyncEnabled => _isSyncEnabled;
  bool _isSyncEnabled = false;

  DateTime? get lastSyncDate => _lastSyncDate;
  DateTime? _lastSyncDate;

  /// Enable sync and perform initial upload.
  Future<void> enableSync() async {
    // TODO: Authenticate with Firebase and push local data
    _isSyncEnabled = true;
  }

  /// Disable sync.
  Future<void> disableSync() async {
    _isSyncEnabled = false;
  }

  /// Perform a full bi-directional sync.
  Future<SyncResult> syncNow() async {
    if (!_isSyncEnabled) {
      return const SyncResult(uploaded: 0, downloaded: 0, conflicts: 0);
    }
    // TODO: Implement merge logic
    _lastSyncDate = DateTime.now();
    return const SyncResult(uploaded: 0, downloaded: 0, conflicts: 0);
  }
}

/// Summary of a sync operation.
class SyncResult {
  final int uploaded;
  final int downloaded;
  final int conflicts;

  const SyncResult({
    required this.uploaded,
    required this.downloaded,
    required this.conflicts,
  });
}
