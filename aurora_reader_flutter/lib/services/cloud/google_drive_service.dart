import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../logging/error_logger.dart';

class DriveFile {
  final String id;
  final String name;
  final String? mimeType;
  final int size;
  final DateTime? modifiedTime;
  final bool isFolder;

  const DriveFile({
    required this.id,
    required this.name,
    this.mimeType,
    this.size = 0,
    this.modifiedTime,
    this.isFolder = false,
  });

  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';

  bool get isEbook =>
      mimeType == 'application/epub+zip' ||
      mimeType == 'application/pdf' ||
      mimeType == 'text/plain' ||
      const {'epub', 'pdf', 'txt'}.contains(extension);

  String get sizeLabel {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class DriveListResult {
  final List<DriveFile> files;
  final String? nextPageToken;

  const DriveListResult({required this.files, this.nextPageToken});
}

class GoogleDriveService {
  static const _driveApi = 'https://www.googleapis.com/drive/v3';
  static const _scope = 'https://www.googleapis.com/auth/drive.readonly';
  static const _hiveKey = 'gdrive_connected';

  final Dio _dio;
  String? _accessToken;
  bool _connected = false;

  GoogleDriveService() : _dio = Dio();

  Box get _box => Hive.box('aurora_reader');

  bool get isConnected => _connected;

  void restoreState() {
    _connected = _box.get(_hiveKey, defaultValue: false) as bool;
  }

  Future<void> connect() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const DriveException('Please sign in before connecting Google Drive.');
    }

    try {
      final provider = fb.GoogleAuthProvider();
      provider.addScope(_scope);

      final credential = await _authWithProvider(user, provider);

      final oAuth = credential.credential;
      if (oAuth == null || oAuth is! fb.OAuthCredential || oAuth.accessToken == null) {
        throw const DriveException('Could not obtain Drive access token.');
      }

      _accessToken = oAuth.accessToken;
      _connected = true;
      _box.put(_hiveKey, true);
    } on fb.FirebaseAuthException catch (e) {
      throw DriveException('Drive authorization failed: ${e.message}');
    }
  }

  Future<void> disconnect() async {
    _accessToken = null;
    _connected = false;
    await _box.put(_hiveKey, false);
  }

  Future<fb.UserCredential> _authWithProvider(
      fb.User user, fb.GoogleAuthProvider provider) async {
    try {
      return await user.reauthenticateWithProvider(provider);
    } on UnimplementedError {
      // reauthenticateWithProvider not available on web
      return await fb.FirebaseAuth.instance.signInWithPopup(provider);
    }
  }

  Future<void> _ensureToken() async {
    if (_accessToken != null) return;
    if (!_connected) throw const DriveException('Google Drive is not connected.');

    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) throw const DriveException('Not signed in.');

    try {
      final provider = fb.GoogleAuthProvider();
      provider.addScope(_scope);

      final credential = await _authWithProvider(user, provider);

      final oAuth = credential.credential;
      if (oAuth is fb.OAuthCredential && oAuth.accessToken != null) {
        _accessToken = oAuth.accessToken;
      } else {
        throw const DriveException('Could not refresh Drive access token.');
      }
    } on fb.FirebaseAuthException catch (e) {
      _connected = false;
      _box.put(_hiveKey, false);
      throw DriveException('Drive re-authorization failed: ${e.message}');
    }
  }

  Future<DriveListResult> listFiles({String? folderId, String? pageToken, bool retryOnAuth = true}) async {
    await _ensureToken();

    final queryParts = <String>[
      "trashed = false",
    ];

    if (folderId != null) {
      queryParts.add("'$folderId' in parents");
    } else {
      queryParts.add("'root' in parents");
    }

    queryParts.add(
      "(mimeType = 'application/vnd.google-apps.folder'"
      " or mimeType = 'application/epub+zip'"
      " or mimeType = 'application/pdf'"
      " or mimeType = 'text/plain'"
      ")",
    );

    try {
      final response = await _dio.get(
        '$_driveApi/files',
        queryParameters: {
          'q': queryParts.join(' and '),
          'fields': 'nextPageToken,files(id,name,mimeType,size,modifiedTime)',
          'orderBy': 'folder,name',
          'pageSize': 50,
          if (pageToken != null) 'pageToken': pageToken,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final files = (data['files'] as List<dynamic>? ?? []).map((f) {
        final map = f as Map<String, dynamic>;
        return DriveFile(
          id: map['id'] as String,
          name: map['name'] as String,
          mimeType: map['mimeType'] as String?,
          size: int.tryParse('${map['size'] ?? 0}') ?? 0,
          modifiedTime: map['modifiedTime'] != null
              ? DateTime.tryParse(map['modifiedTime'] as String)
              : null,
          isFolder: map['mimeType'] == 'application/vnd.google-apps.folder',
        );
      }).toList();

      return DriveListResult(
        files: files,
        nextPageToken: data['nextPageToken'] as String?,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && retryOnAuth) {
        _accessToken = null;
        await _ensureToken();
        return listFiles(folderId: folderId, pageToken: pageToken, retryOnAuth: false);
      }
      ErrorLogger.instance.capture(e, source: 'GoogleDrive.listFiles');
      throw DriveException('Failed to list files: ${e.message}');
    }
  }

  Future<List<DriveFile>> searchEbooks(String query, {bool retryOnAuth = true}) async {
    await _ensureToken();

    final q = "name contains '${query.replaceAll("'", "\\'")}'"
        " and trashed = false"
        " and (mimeType = 'application/epub+zip'"
        " or mimeType = 'application/pdf'"
        " or mimeType = 'text/plain')";

    try {
      final response = await _dio.get(
        '$_driveApi/files',
        queryParameters: {
          'q': q,
          'fields': 'files(id,name,mimeType,size,modifiedTime)',
          'orderBy': 'modifiedTime desc',
          'pageSize': 30,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return (data['files'] as List<dynamic>? ?? []).map((f) {
        final map = f as Map<String, dynamic>;
        return DriveFile(
          id: map['id'] as String,
          name: map['name'] as String,
          mimeType: map['mimeType'] as String?,
          size: int.tryParse('${map['size'] ?? 0}') ?? 0,
          modifiedTime: map['modifiedTime'] != null
              ? DateTime.tryParse(map['modifiedTime'] as String)
              : null,
        );
      }).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && retryOnAuth) {
        _accessToken = null;
        await _ensureToken();
        return searchEbooks(query, retryOnAuth: false);
      }
      ErrorLogger.instance.capture(e, source: 'GoogleDrive.search');
      throw DriveException('Search failed: ${e.message}');
    }
  }

  Future<Uint8List> downloadFile(String fileId, {bool retryOnAuth = true}) async {
    await _ensureToken();

    try {
      final response = await _dio.get<List<int>>(
        '$_driveApi/files/$fileId',
        queryParameters: {'alt': 'media'},
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
          responseType: ResponseType.bytes,
        ),
      );

      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && retryOnAuth) {
        _accessToken = null;
        await _ensureToken();
        return downloadFile(fileId, retryOnAuth: false);
      }
      ErrorLogger.instance.capture(e, source: 'GoogleDrive.download');
      throw DriveException('Download failed: ${e.message}');
    }
  }
}

class DriveException implements Exception {
  final String message;
  const DriveException(this.message);

  @override
  String toString() => message;
}
