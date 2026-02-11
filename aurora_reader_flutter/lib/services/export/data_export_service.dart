import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';

/// Exports user data (highlights, notes, vocabulary, reading stats) to
/// various formats (JSON, CSV, Markdown) for backup and portability.
class DataExportService {
  final AppDatabase _db;

  DataExportService(this._db);

  /// Export all highlights to a JSON file. Returns the file path.
  Future<String> exportHighlightsJson() async {
    final highlights = await _db.watchAllHighlights().first;
    final data = highlights
        .map((h) => {
              'id': h.id,
              'bookId': h.bookId,
              'text': h.highlightedText,
              'note': h.note,
              'color': h.colorName,
              'chapter': h.chapterTitle,
              'dateCreated': h.dateCreated.toIso8601String(),
            })
        .toList();

    return _writeJsonFile('highlights', data);
  }

  /// Export all vocabulary entries to a JSON file.
  Future<String> exportVocabularyJson() async {
    final vocab = await _db.watchAllVocabulary().first;
    final data = vocab
        .map((v) => {
              'word': v.word,
              'definition': v.definition,
              'context': v.context,
              'bookTitle': v.bookTitle,
              'isMastered': v.isMastered,
              'dateAdded': v.dateAdded.toIso8601String(),
            })
        .toList();

    return _writeJsonFile('vocabulary', data);
  }

  /// Export reading sessions to CSV.
  Future<String> exportSessionsCsv() async {
    final sessions = await _db.watchAllSessions().first;
    final buffer = StringBuffer();
    buffer.writeln('date,book_id,duration_seconds,pages_read,words_read');

    for (final s in sessions) {
      buffer.writeln(
        '${s.startTime.toIso8601String()},${s.bookId ?? ""},${s.durationSeconds},${s.pagesRead},${s.wordsRead}',
      );
    }

    return _writeCsvFile('reading_sessions', buffer.toString());
  }

  /// Export highlights as Markdown grouped by book.
  Future<String> exportHighlightsMarkdown() async {
    final highlights = await _db.watchAllHighlights().first;
    final buffer = StringBuffer();
    buffer.writeln('# Aurora Reader - Highlights Export');
    buffer.writeln('');
    buffer.writeln(
        '_Exported ${DateFormat.yMMMd().format(DateTime.now())}_');
    buffer.writeln('');

    // Group by bookId
    final grouped = <String, List<Highlight>>{};
    for (final h in highlights) {
      grouped.putIfAbsent(h.bookId, () => []).add(h);
    }

    for (final entry in grouped.entries) {
      buffer.writeln('## ${entry.key}');
      buffer.writeln('');
      for (final h in entry.value) {
        buffer.writeln('> ${h.highlightedText}');
        if (h.note.isNotEmpty) {
          buffer.writeln('');
          buffer.writeln('**Note:** ${h.note}');
        }
        buffer.writeln('');
      }
    }

    return _writeTextFile('highlights', buffer.toString(), 'md');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Future<String> _writeJsonFile(
      String name, List<Map<String, dynamic>> data) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/aurora_export_${name}_$timestamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file.path;
  }

  Future<String> _writeCsvFile(String name, String content) async {
    return _writeTextFile(name, content, 'csv');
  }

  Future<String> _writeTextFile(
      String name, String content, String ext) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/aurora_export_${name}_$timestamp.$ext');
    await file.writeAsString(content);
    return file.path;
  }
}
