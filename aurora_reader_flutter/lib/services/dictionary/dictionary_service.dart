import 'package:dio/dio.dart';

/// Provides dictionary lookups using the Free Dictionary API.
///
/// Returns definitions, phonetics, part of speech, and example usage
/// for words encountered while reading.
class DictionaryService {
  final Dio _dio = Dio();

  static const _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  /// Look up a word and return its definition entry.
  Future<DictionaryEntry?> lookup(String word) async {
    if (word.trim().isEmpty) return null;

    try {
      final response = await _dio.get('$_baseUrl/${word.trim().toLowerCase()}');
      final data = response.data as List;
      if (data.isEmpty) return null;

      final entry = data.first;
      final meanings = entry['meanings'] as List? ?? [];

      final definitions = <WordDefinition>[];
      for (final meaning in meanings) {
        final partOfSpeech = meaning['partOfSpeech'] as String? ?? '';
        final defs = meaning['definitions'] as List? ?? [];
        for (final def in defs) {
          definitions.add(WordDefinition(
            definition: def['definition'] ?? '',
            partOfSpeech: partOfSpeech,
            example: def['example'],
          ));
        }
      }

      // Extract phonetics
      String? phonetic;
      String? audioUrl;
      final phonetics = entry['phonetics'] as List? ?? [];
      for (final p in phonetics) {
        phonetic ??= p['text'];
        final audio = p['audio'] as String?;
        if (audio != null && audio.isNotEmpty) {
          audioUrl = audio;
          phonetic = p['text'] ?? phonetic;
          break;
        }
      }

      return DictionaryEntry(
        word: entry['word'] ?? word,
        phonetic: phonetic,
        audioUrl: audioUrl,
        definitions: definitions,
      );
    } on DioException {
      return null;
    }
  }
}

/// A dictionary entry with phonetics and definitions.
class DictionaryEntry {
  final String word;
  final String? phonetic;
  final String? audioUrl;
  final List<WordDefinition> definitions;

  const DictionaryEntry({
    required this.word,
    this.phonetic,
    this.audioUrl,
    required this.definitions,
  });
}

/// A single definition with part of speech and optional example.
class WordDefinition {
  final String definition;
  final String partOfSpeech;
  final String? example;

  const WordDefinition({
    required this.definition,
    required this.partOfSpeech,
    this.example,
  });
}
