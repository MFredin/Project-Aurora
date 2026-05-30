import 'package:hive/hive.dart';

enum LlmProviderType {
  anthropic,
  openai,
  gemini;

  String get displayName {
    switch (this) {
      case LlmProviderType.anthropic:
        return 'Anthropic';
      case LlmProviderType.openai:
        return 'OpenAI';
      case LlmProviderType.gemini:
        return 'Google Gemini';
    }
  }

  String get defaultModel {
    switch (this) {
      case LlmProviderType.anthropic:
        return 'claude-sonnet-4-6';
      case LlmProviderType.openai:
        return 'gpt-5.5';
      case LlmProviderType.gemini:
        return 'gemini-3.5-flash';
    }
  }

  List<String> get availableModels {
    switch (this) {
      case LlmProviderType.anthropic:
        return [
          'claude-haiku-4-5',
          'claude-sonnet-4-6',
          'claude-opus-4-8',
        ];
      case LlmProviderType.openai:
        return ['gpt-5.5', 'gpt-5.2', 'o3', 'o4-mini'];
      case LlmProviderType.gemini:
        return ['gemini-3.5-flash', 'gemini-3.1-pro', 'gemini-2.5-pro', 'gemini-2.5-flash'];
    }
  }

  String get apiKeyHint {
    switch (this) {
      case LlmProviderType.anthropic:
        return 'sk-ant-...';
      case LlmProviderType.openai:
        return 'sk-...';
      case LlmProviderType.gemini:
        return 'AIza...';
    }
  }
}

class LlmConfig {
  final LlmProviderType provider;
  final String? apiKey;
  final String model;

  const LlmConfig({
    this.provider = LlmProviderType.anthropic,
    this.apiKey,
    String? model,
  }) : model = model ?? '';

  String get activeModel => model.isEmpty ? provider.defaultModel : model;

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  LlmConfig copyWith({
    LlmProviderType? provider,
    String? apiKey,
    String? model,
  }) {
    return LlmConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }
}

class LlmSettingsService {
  static const _boxName = 'aurora_reader';
  static const _providerKey = 'llm_provider';
  static const _modelKey = 'llm_model';
  static const _apiKeyPrefix = 'llm_api_key_';

  Box get _box => Hive.box(_boxName);

  LlmConfig load() {
    final providerName = _box.get(_providerKey, defaultValue: 'anthropic') as String;
    final provider = LlmProviderType.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => LlmProviderType.anthropic,
    );
    final model = _box.get(_modelKey, defaultValue: '') as String;
    final apiKey = _box.get('$_apiKeyPrefix${provider.name}', defaultValue: '') as String;

    return LlmConfig(
      provider: provider,
      apiKey: apiKey.isEmpty ? null : apiKey,
      model: model,
    );
  }

  Future<void> save(LlmConfig config) async {
    await _box.put(_providerKey, config.provider.name);
    await _box.put(_modelKey, config.model);
    if (config.apiKey != null) {
      await _box.put('$_apiKeyPrefix${config.provider.name}', config.apiKey!);
    }
  }

  Future<void> saveApiKey(LlmProviderType provider, String apiKey) async {
    await _box.put('$_apiKeyPrefix${provider.name}', apiKey);
  }

  String? loadApiKey(LlmProviderType provider) {
    final key = _box.get('$_apiKeyPrefix${provider.name}', defaultValue: '') as String;
    return key.isEmpty ? null : key;
  }
}
