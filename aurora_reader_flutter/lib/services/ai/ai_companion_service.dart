import '../../core/database/database.dart';
import 'llm_provider.dart';

class AICompanionService {
  final AppDatabase _db;
  final LlmSettingsService _settings;

  AICompanionService(this._db, this._settings);

  LlmConfig get _config => _settings.load();

  Future<String> askQuestion({
    required String bookId,
    required String question,
    String? chapterContext,
  }) async {
    final config = _config;
    if (!config.isConfigured) {
      return _notConfiguredMessage(config.provider);
    }
    // TODO: Implement API call via _callLlm
    return 'AI companion response placeholder — '
        '${config.provider.displayName} (${config.activeModel}) is configured.';
  }

  Future<String> summarizeChapter({
    required String bookId,
    required int chapterIndex,
  }) async {
    final config = _config;
    if (!config.isConfigured) {
      return _notConfiguredMessage(config.provider);
    }
    return 'Chapter summary will appear here — '
        '${config.provider.displayName} is ready.';
  }

  Future<List<String>> analyzeThemes({required String bookId}) async {
    return [];
  }

  Future<String> explainWord({
    required String word,
    required String surroundingText,
  }) async {
    final config = _config;
    if (!config.isConfigured) {
      return _notConfiguredMessage(config.provider);
    }
    return 'Definition for "$word" via ${config.provider.displayName}.';
  }

  Future<List<Map<String, dynamic>>> extractConcepts({
    required String bookId,
  }) async {
    return [];
  }

  String _notConfiguredMessage(LlmProviderType provider) {
    return 'Add your ${provider.displayName} API key in Settings → AI Companion '
        'to enable AI features.';
  }
}
