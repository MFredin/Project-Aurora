import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../core/database/database.dart';
import '../services/parser/book_parser_service.dart';
import '../services/cloud/cloud_storage_service.dart';
import '../services/sync/sync_service.dart';
import '../services/ai/ai_companion_service.dart';
import '../services/ai/llm_provider.dart';
import '../services/audio/ambient_service.dart';
import '../services/audio/tts_service.dart';
import '../services/discovery/book_discovery_service.dart';
import '../services/export/data_export_service.dart';
import '../services/dictionary/dictionary_service.dart';
import '../services/stats/reading_stats_service.dart';
import '../services/ai/ai_reading_tools.dart';
import '../services/import/kindle_import_service.dart';
import 'database_provider.dart';

/// Book parser — stateless, no DB dependency.
/// Already defined in book_parser_service.dart as bookParserServiceProvider.
/// Re-exported here for convenience.
export '../services/parser/book_parser_service.dart'
    show bookParserServiceProvider;

/// Dark mode state (persisted in Hive).
final darkModeProvider = NotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

class DarkModeNotifier extends Notifier<bool> {
  static const _key = 'dark_mode';
  Box get _box => Hive.box('aurora_reader');

  @override
  bool build() {
    return _box.get(_key, defaultValue: true) as bool;
  }

  void toggle() {
    state = !state;
    _box.put(_key, state);
  }

  void set(bool value) {
    state = value;
    _box.put(_key, value);
  }
}

/// Cloud storage service.
final cloudStorageProvider = Provider<CloudStorageService>((ref) {
  final db = ref.watch(databaseProvider);
  return CloudStorageService(db);
});

/// Cross-device sync service.
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncService(db);
});

/// LLM settings persistence.
final llmSettingsProvider = Provider<LlmSettingsService>((ref) {
  return LlmSettingsService();
});

/// LLM configuration state (reactive).
final llmConfigProvider = NotifierProvider<LlmConfigNotifier, LlmConfig>(
  LlmConfigNotifier.new,
);

class LlmConfigNotifier extends Notifier<LlmConfig> {
  late final LlmSettingsService _settings;

  @override
  LlmConfig build() {
    _settings = ref.watch(llmSettingsProvider);
    return _settings.load();
  }

  Future<void> setProvider(LlmProviderType provider) async {
    final existingKey = _settings.loadApiKey(provider);
    state = LlmConfig(
      provider: provider,
      apiKey: existingKey,
      model: provider.defaultModel,
    );
    await _settings.save(state);
  }

  Future<void> setModel(String model) async {
    state = state.copyWith(model: model);
    await _settings.save(state);
  }

  Future<void> setApiKey(String apiKey) async {
    state = state.copyWith(apiKey: apiKey);
    await _settings.save(state);
  }
}

/// AI reading companion.
final aiCompanionProvider = Provider<AICompanionService>((ref) {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(llmSettingsProvider);
  return AICompanionService(db, settings);
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

/// AI reading tools (enhanced companion features).
final aiReadingToolsProvider = Provider<AiReadingTools>((ref) {
  final aiService = ref.watch(aiCompanionProvider);
  return AiReadingTools(aiService);
});

/// Kindle clippings import service.
final kindleImportProvider = Provider<KindleImportService>((ref) {
  return KindleImportService();
});
