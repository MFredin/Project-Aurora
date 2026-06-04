import 'package:uuid/uuid.dart';

import '../../core/data/book_repository.dart';
import '../../core/data/models.dart';

const _uuid = Uuid();

/// Result of an import operation.
class ImportResult {
  final int imported;
  final int skipped;
  final int errors;
  final List<String> errorMessages;

  const ImportResult({
    this.imported = 0,
    this.skipped = 0,
    this.errors = 0,
    this.errorMessages = const [],
  });

  int get total => imported + skipped + errors;
}

/// Parses a Goodreads CSV export and creates BookModel entries.
class GoodreadsImportService {
  final BookRepository _repository;

  GoodreadsImportService(this._repository);

  /// Import books from Goodreads CSV content.
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

    // Validate required columns exist
    if (!headerIndex.containsKey('Title') ||
        !headerIndex.containsKey('Author')) {
      return const ImportResult(
        errors: 1,
        errorMessages: [
          'CSV is missing required columns (Title, Author). '
              'Make sure this is a Goodreads export file.',
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
        final author = _getField(row, headerIndex, 'Author')?.trim() ?? '';

        if (title.isEmpty && author.isEmpty) {
          skipped++;
          continue;
        }

        // Extract ISBN — strip surrounding ="..." wrapper if present
        final isbn = _cleanIsbn(
          _getField(row, headerIndex, 'ISBN13') ??
              _getField(row, headerIndex, 'ISBN'),
        );

        // Check for duplicates
        if (_isDuplicate(existingBooks, title, author, isbn)) {
          skipped++;
          continue;
        }

        // Map shelf to ReadingStatus
        final exclusiveShelf =
            _getField(row, headerIndex, 'Exclusive Shelf')?.trim() ?? '';
        final readingStatus = _mapShelfToStatus(exclusiveShelf);

        // Map rating (Goodreads uses 1-5 integers, 0 means unrated)
        final ratingStr =
            _getField(row, headerIndex, 'My Rating')?.trim() ?? '0';
        final ratingInt = int.tryParse(ratingStr) ?? 0;
        final double? rating = ratingInt > 0 ? ratingInt.toDouble() : null;

        // Parse dates
        final dateRead = _parseDate(_getField(row, headerIndex, 'Date Read'));
        final dateAdded =
            _parseDate(_getField(row, headerIndex, 'Date Added')) ??
                DateTime.now();

        // Review
        final review =
            _getField(row, headerIndex, 'My Review')?.trim() ?? '';

        // Binding → BookFormatType
        final binding =
            _getField(row, headerIndex, 'Binding')?.trim() ?? '';
        final bookFormatType = _mapBindingToFormat(binding);

        // Build the BookModel
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
          startDate: readingStatus == ReadingStatus.reading ||
                  readingStatus == ReadingStatus.read
              ? dateAdded
              : null,
          finishDate: readingStatus == ReadingStatus.read ? dateRead : null,
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

  /// Split CSV content into lines, respecting quoted newlines.
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
        // Skip \r\n pairs
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

  /// Parse a single CSV row into fields, handling quoted values.
  List<String> _parseCsvRow(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];

      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
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

  /// Clean ISBN field — Goodreads wraps ISBNs in ="..." format.
  String? _cleanIsbn(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    // Remove =" prefix and " suffix
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

  ReadingStatus _mapShelfToStatus(String shelf) {
    switch (shelf.toLowerCase()) {
      case 'read':
        return ReadingStatus.read;
      case 'currently-reading':
        return ReadingStatus.reading;
      case 'to-read':
        return ReadingStatus.wantToRead;
      default:
        return ReadingStatus.wantToRead;
    }
  }

  BookFormatType? _mapBindingToFormat(String binding) {
    final lower = binding.toLowerCase();
    if (lower.contains('hardcover') ||
        lower.contains('paperback') ||
        lower.contains('mass market')) {
      return BookFormatType.physical;
    }
    if (lower.contains('ebook') || lower.contains('kindle')) {
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

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final trimmed = dateStr.trim();

    // Goodreads uses YYYY/MM/DD format
    try {
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
      // Fallback: try ISO format
      return DateTime.tryParse(trimmed);
    } catch (_) {
      return null;
    }
  }

  /// Check if a book already exists in the library.
  bool _isDuplicate(
      List<BookModel> existing, String title, String author, String? isbn) {
    for (final book in existing) {
      // Match by ISBN if both have one
      if (isbn != null &&
          isbn.isNotEmpty &&
          book.isbn != null &&
          book.isbn!.isNotEmpty) {
        if (book.isbn == isbn) return true;
      }

      // Match by title + author (case-insensitive)
      if (book.title.toLowerCase() == title.toLowerCase() &&
          book.author.toLowerCase() == author.toLowerCase()) {
        return true;
      }
    }
    return false;
  }
}
