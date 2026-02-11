import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import '../services/parser/book_parser_service.dart';
import '../services/cloud/cloud_storage_service.dart';
import '../services/sync/sync_service.dart';
import '../services/ai/ai_companion_service.dart';
import '../services/audio/ambient_service.dart';
import '../services/audio/tts_service.dart';
import '../services/discovery/book_discovery_service.dart';
import '../services/export/data_export_service.dart';
import '../services/dictionary/dictionary_service.dart';
import '../services/stats/reading_stats_service.dart';
import 'database_provider.dart';

/// Book parser — stateless, no DB dependency.
/// Already defined in book_parser_service.dart as bookParserServiceProvider.
/// Re-exported here for convenience.
export '../services/parser/book_parser_service.dart'
    show bookParserServiceProvider;

/// Cloud storage service.
final cloudStorageProvider = Provider<CloudStorageService>((ref) {
  return CloudStorageService();
});

/// Cross-device sync service.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

/// AI reading companion.
final aiCompanionProvider = Provider<AICompanionService>((ref) {
  final db = ref.watch(databaseProvider);
  return AICompanionService(db);
});

/// Ambient soundscape service.
final ambientServiceProvider = Provider<AmbientService>((ref) {
  return AmbientService();
});

/// Text-to-speech service.
final ttsServiceProvider = Provider<TTSService>((ref) {
  return TTSService();
});

/// Book discovery (Open Library / Google Books).
final bookDiscoveryProvider = Provider<BookDiscoveryService>((ref) {
  return BookDiscoveryService();
});

/// Data export service.
final dataExportProvider = Provider<DataExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return DataExportService(db);
});

/// Dictionary lookup service.
final dictionaryProvider = Provider<DictionaryService>((ref) {
  return DictionaryService();
});

/// Reading statistics service.
final readingStatsProvider = Provider<ReadingStatsService>((ref) {
  final db = ref.watch(databaseProvider);
  return ReadingStatsService(db);
});
