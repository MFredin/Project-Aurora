import 'package:uuid/uuid.dart';

import '../../core/data/book_repository.dart';
import '../../core/data/models.dart';
import 'goodreads_import_service.dart' show ImportResult;

const _uuid = Uuid();

/// Parses a StoryGraph CSV export and creates BookModel entries.
///
/// StoryGraph CSV columns typically include:
/// Title, Authors, Contributors, ISBN/UID, Format, Shelves, Read Status,
/// Star Rating, Moods, Pace, Date Added, Last Date Read, Tags, Review
class StorygraphImportService {
  final BookRepository _repository;

  StorygraphImportService(this._repository);

  /// Import books from StoryGraph CSV content.
  ///
  /// Calls [onProgress] with (current, total) for UI updates.
  Future<ImportResult> importFromCsv(
    String csvContent, {
    void Function(int current, int total)? onProgress,
  }) async {
    final lines = _parseCsvLines(csvContent);
    if (lines.length < 2) {
      return const ImportResult(
        errors: 1,
        errorMessages: ['CSV file is empty or has no data rows.'],
      );
    }

    final headers = _parseCsvRow(lines[0]);
    final headerIndex = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      headerIndex[headers[i].trim()] = i;
    }

    // Validate required columns
    if (!headerIndex.containsKey('Title') &&
        !headerIndex.containsKey('Authors')) {
      return const ImportResult(
        errors: 1,
        errorMessages: [
          'CSV is missing required columns (Title, Authors). '
              'Make sure this is a StoryGraph export file.',
        ],
      );
    }

    final existingBooks = _repository.state;
    final dataRows = lines.sublist(1);
    int imported = 0;
    int skipped = 0;
    int errors = 0;
    final errorMessages = <String>[];

    for (var i = 0; i < dataRows.length; i++) {
      onProgress?.call(i + 1, dataRows.length);

      try {
        final row = _parseCsvRow(dataRows[i]);
        if (row.isEmpty) {
          skipped++;
          continue;
        }

        final title = _getField(row, headerIndex, 'Title')?.trim() ?? '';
        final author = _getField(row, headerIndex, 'Authors')?.trim() ?? '';

        if (title.isEmpty && author.isEmpty) {
          skipped++;
          continue;
        }

        // ISBN/UID
        final isbn = _cleanIsbn(
          _getField(row, headerIndex, 'ISBN/UID'),
        );

        // Check for duplicates
        if (_isDuplicate(existingBooks, title, author, isbn)) {
          skipped++;
          continue;
        }

        // Map read status
        final readStatusStr =
            _getField(row, headerIndex, 'Read Status')?.trim() ?? '';
        final readingStatus = _mapReadStatus(readStatusStr);

        // Map star rating — StoryGraph uses half-star ratings (0.5 - 5)
        final ratingStr =
            _getField(row, headerIndex, 'Star Rating')?.trim() ?? '';
        final ratingVal = double.tryParse(ratingStr);
        final double? rating =
            ratingVal != null && ratingVal > 0 ? ratingVal : null;

        // Parse dates
        final lastDateRead =
            _parseDate(_getField(row, headerIndex, 'Last Date Read'));
        final dateAdded =
            _parseDate(_getField(row, headerIndex, 'Date Added')) ??
                DateTime.now();

        // Review
        final review =
            _getField(row, headerIndex, 'Review')?.trim() ?? '';

        // Format
        final formatStr =
            _getField(row, headerIndex, 'Format')?.trim() ?? '';
        final bookFormatType = _mapFormatToType(formatStr);

        // Moods (StoryGraph provides mood tags)
        final moodsStr =
            _getField(row, headerIndex, 'Moods')?.trim() ?? '';
        final moods = moodsStr.isNotEmpty
            ? moodsStr
                .split(',')
                .map((m) => m.trim().toLowerCase())
                .where((m) => m.isNotEmpty)
                .toList()
            : <String>[];

        // Pace
        final paceStr =
            _getField(row, headerIndex, 'Pace')?.trim() ?? '';
        final pace = _mapPace(paceStr);

        // Tags
        final tagsStr =
            _getField(row, headerIndex, 'Tags')?.trim() ?? '';
        final tags = tagsStr.isNotEmpty
            ? tagsStr
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList()
            : <String>[];

        final book = BookModel(
          id: _uuid.v4(),
          title: title,
          author: author,
          isbn: isbn,
          format: 'imported',
          fileSize: 0,
          dateAdded: dateAdded,
          chapters: const [],
          readingStatus: readingStatus,
          rating: rating,
          review: review,
          bookFormatType: bookFormatType,
          moods: moods,
          pace: pace,
          customTags: tags,
          startDate: readingStatus == ReadingStatus.reading ||
                  readingStatus == ReadingStatus.read
              ? dateAdded
              : null,
          finishDate: readingStatus == ReadingStatus.read ? lastDateRead : null,
        );

        _repository.addImportedBook(book);
        imported++;
      } catch (e) {
        errors++;
        errorMessages.add('Row ${i + 2}: $e');
      }
    }

    return ImportResult(
      imported: imported,
      skipped: skipped,
      errors: errors,
      errorMessages: errorMessages,
    );
  }

  // ── CSV Parsing ──────────────────────────────────────────────────────────

  List<String> _parseCsvLines(String content) {
    final lines = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < content.length; i++) {
      final ch = content[i];

      if (ch == '"') {
        inQuotes = !inQuotes;
        buffer.write(ch);
      } else if ((ch == '\n' || ch == '\r') && !inQuotes) {
        final line = buffer.toString().trim();
        if (line.isNotEmpty) {
          lines.add(line);
        }
        buffer.clear();
        if (ch == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++;
        }
      } else {
        buffer.write(ch);
      }
    }

    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      lines.add(remaining);
    }

    return lines;
  }

  List<String> _parseCsvRow(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];

      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }

    fields.add(buffer.toString());
    return fields;
  }

  String? _getField(
      List<String> row, Map<String, int> headerIndex, String column) {
    final idx = headerIndex[column];
    if (idx == null || idx >= row.length) return null;
    final value = row[idx];
    return value.isEmpty ? null : value;
  }

  String? _cleanIsbn(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var cleaned = raw.trim();
    if (cleaned.startsWith('="')) {
      cleaned = cleaned.substring(2);
    }
    if (cleaned.endsWith('"')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    cleaned = cleaned.trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  // ── Mapping ──────────────────────────────────────────────────────────────

  ReadingStatus _mapReadStatus(String status) {
    switch (status.toLowerCase()) {
      case 'read':
        return ReadingStatus.read;
      case 'currently-reading':
      case 'currently reading':
        return ReadingStatus.reading;
      case 'to-read':
      case 'want to read':
        return ReadingStatus.wantToRead;
      case 'did not finish':
      case 'dnf':
        return ReadingStatus.dnf;
      default:
        return ReadingStatus.wantToRead;
    }
  }

  BookFormatType? _mapFormatToType(String format) {
    final lower = format.toLowerCase();
    if (lower.contains('physical') ||
        lower.contains('hardcover') ||
        lower.contains('paperback')) {
      return BookFormatType.physical;
    }
    if (lower.contains('ebook') ||
        lower.contains('kindle') ||
        lower.contains('digital')) {
      return BookFormatType.ebook;
    }
    if (lower.contains('audio')) {
      return BookFormatType.audiobook;
    }
    if (lower.contains('arc') || lower.contains('advance')) {
      return BookFormatType.arc;
    }
    return null;
  }

  ReadingPace? _mapPace(String pace) {
    switch (pace.toLowerCase()) {
      case 'slow':
        return ReadingPace.slow;
      case 'medium':
        return ReadingPace.medium;
      case 'fast':
        return ReadingPace.fast;
      default:
        return null;
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final trimmed = dateStr.trim();

    try {
      // StoryGraph uses YYYY-MM-DD format
      if (trimmed.contains('-')) {
        return DateTime.tryParse(trimmed);
      }
      // Also try YYYY/MM/DD
      if (trimmed.contains('/')) {
        final parts = trimmed.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      }
      return DateTime.tryParse(trimmed);
    } catch (_) {
      return null;
    }
  }

  bool _isDuplicate(
      List<BookModel> existing, String title, String author, String? isbn) {
    for (final book in existing) {
      if (isbn != null &&
          isbn.isNotEmpty &&
          book.isbn != null &&
          book.isbn!.isNotEmpty) {
        if (book.isbn == isbn) return true;
      }

      if (book.title.toLowerCase() == title.toLowerCase() &&
          book.author.toLowerCase() == author.toLowerCase()) {
        return true;
      }
    }
    return false;
  }
}
