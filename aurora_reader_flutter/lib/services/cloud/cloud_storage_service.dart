import '../../core/database/database.dart';

/// Manages cloud storage integration (Dropbox, Google Drive, Proton Drive).
///
/// Handles OAuth authentication, file listing, upload/download, and
/// delta-sync for each supported provider.
class CloudStorageService {
  final AppDatabase _db;

  CloudStorageService(this._db);

  // ── Provider State ──────────────────────────────────────────────────────

  bool get isConnected => _isConnected;
  bool _isConnected = false;

  String? get activeProvider => _activeProvider;
  String? _activeProvider;

  /// Connect to a cloud provider by name (dropbox, googleDrive, protonDrive).
  Future<void> connect(String provider) async {
    // TODO: Implement OAuth flow per provider
    _activeProvider = provider;
    _isConnected = true;
  }

  /// Disconnect current provider.
  Future<void> disconnect() async {
    _activeProvider = null;
    _isConnected = false;
  }

  /// List ebook files available in the connected cloud storage.
  Future<List<CloudFileEntry>> listFiles() async {
    // TODO: Implement per-provider file listing
    return [];
  }

  /// Download a cloud file to local storage and return the local path.
  Future<String> downloadFile(String cloudFileId) async {
    // TODO: Implement per-provider download
    throw UnimplementedError('Cloud download not yet implemented');
  }

  /// Upload a local file to the connected cloud storage.
  Future<void> uploadFile(String localPath) async {
    // TODO: Implement per-provider upload
    throw UnimplementedError('Cloud upload not yet implemented');
  }
}

/// Represents a file entry from a cloud storage provider.
class CloudFileEntry {
  final String id;
  final String name;
  final String path;
  final int fileSize;
  final DateTime modifiedDate;
  final String provider;

  const CloudFileEntry({
    required this.id,
    required this.name,
    required this.path,
    required this.fileSize,
    required this.modifiedDate,
    required this.provider,
  });
}
