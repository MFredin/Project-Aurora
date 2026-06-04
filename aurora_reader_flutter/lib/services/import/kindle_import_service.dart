import '../../core/data/models.dart';

/// Parsed result from a Kindle clippings file.
class KindleClipping {
  final String bookTitle;
  final String author;
  final String type; // highlight, note, bookmark
  final int? page;
  final int? locationStart;
  final int? locationEnd;
  final DateTime? dateAdded;
  final String content;

  const KindleClipping({
    required this.bookTitle,
    required this.author,
    required this.type,
    this.page,
    this.locationStart,
    this.locationEnd,
    this.dateAdded,
    required this.content,
  });
}

/// Grouped clippings for a single book.
class KindleBookClippings {
  final String bookTitle;
  final String author;
  final List<KindleClipping> clippings;

  const KindleBookClippings({
    required this.bookTitle,
    required this.author,
    required this.clippings,
  });

  List<KindleClipping> get highlights =>
      clippings.where((c) => c.type == 'highlight').toList();

  List<KindleClipping> get notes =>
      clippings.where((c) => c.type == 'note').toList();

  List<KindleClipping> get bookmarks =>
      clippings.where((c) => c.type == 'bookmark').toList();
}

/// Service for parsing Kindle's "My Clippings.txt" format.
///
/// The Kindle clippings format is:
/// ```
/// Book Title (Author Name)
/// - Your Highlight on page 42 | Location 645-648 | Added on Sunday, March 15, 2024 9:30:22 PM
///
/// The highlighted text goes here
/// ==========
/// ```
class KindleImportService {
  /// Parse raw clippings text content into structured clipping objects.
  List<KindleClipping> parseClippings(String fileContent) {
    final clippings = <KindleClipping>[];
    final entries = fileContent.split('==========');

    for (final entry in entries) {
      final trimmed = entry.trim();
      if (trimmed.isEmpty) continue;

      final lines = trimmed.split('\n');
      if (lines.length < 2) continue;

      // Line 1: Book Title (Author Name)
      final titleLine = lines[0].trim();
      final titleAuthor = _parseTitleAuthor(titleLine);

      // Line 2: - Your Highlight/Note/Bookmark on page X | Location Y-Z | Added on ...
      final metaLine = lines.length > 1 ? lines[1].trim() : '';
      final meta = _parseMetaLine(metaLine);

      // Lines 3+: Content (skip empty lines between meta and content)
      final contentLines = <String>[];
      bool foundContent = false;
      for (int i = 2; i < lines.length; i++) {
        final line = lines[i];
        if (!foundContent && line.trim().isEmpty) continue;
        foundContent = true;
        contentLines.add(line);
      }
      final content = contentLines.join('\n').trim();

      if (titleAuthor != null) {
        clippings.add(KindleClipping(
          bookTitle: titleAuthor.$1,
          author: titleAuthor.$2,
          type: meta.type,
          page: meta.page,
          locationStart: meta.locationStart,
          locationEnd: meta.locationEnd,
          dateAdded: meta.dateAdded,
          content: content,
        ));
      }
    }

    return clippings;
  }

  /// Group clippings by book title.
  List<KindleBookClippings> groupByBook(List<KindleClipping> clippings) {
    final grouped = <String, List<KindleClipping>>{};
    final authors = <String, String>{};

    for (final clip in clippings) {
      grouped.putIfAbsent(clip.bookTitle, () => []).add(clip);
      authors.putIfAbsent(clip.bookTitle, () => clip.author);
    }

    return grouped.entries
        .map((e) => KindleBookClippings(
              bookTitle: e.key,
              author: authors[e.key] ?? '',
              clippings: e.value,
            ))
        .toList()
      ..sort((a, b) => a.bookTitle.compareTo(b.bookTitle));
  }

  /// Try to match a Kindle book to an existing book in the library (by title).
  BookModel? findMatchingBook(
      String kindleTitle, List<BookModel> libraryBooks) {
    final normalizedKindle = _normalize(kindleTitle);

    for (final book in libraryBooks) {
      if (_normalize(book.title) == normalizedKindle) {
        return book;
      }
    }

    // Fuzzy match: check if one contains the other
    for (final book in libraryBooks) {
      final normalizedLib = _normalize(book.title);
      if (normalizedLib.contains(normalizedKindle) ||
          normalizedKindle.contains(normalizedLib)) {
        return book;
      }
    }

    return null;
  }

  /// Convert Kindle highlights to HighlightModel entries for a matched book.
  List<HighlightModel> convertToHighlights(
    KindleBookClippings bookClippings,
    String bookId,
  ) {
    return bookClippings.highlights
        .where((h) => h.content.isNotEmpty)
        .map((h) => HighlightModel(
              id: 'kindle_${h.bookTitle.hashCode}_${h.content.hashCode}',
              bookId: bookId,
              highlightedText: h.content,
              note: '',
              colorName: 'manuscriptGold',
              chapterIndex: 0, // Kindle doesn't provide chapter info directly
              dateCreated: h.dateAdded ?? DateTime.now(),
            ))
        .toList();
  }

  // ── Private parsing helpers ───────────────────────────────────────────────

  /// Parse "Book Title (Author Name)" -> (title, author)
  (String, String)? _parseTitleAuthor(String line) {
    if (line.isEmpty) return null;

    // Find the last opening parenthesis to extract author
    final lastParen = line.lastIndexOf('(');
    if (lastParen > 0 && line.endsWith(')')) {
      final title = line.substring(0, lastParen).trim();
      final author =
          line.substring(lastParen + 1, line.length - 1).trim();
      return (title, author);
    }

    // No author in parens — whole line is the title
    return (line, '');
  }

  /// Parse the metadata line.
  _ClippingMeta _parseMetaLine(String line) {
    String type = 'highlight';
    int? page;
    int? locationStart;
    int? locationEnd;
    DateTime? dateAdded;

    final lower = line.toLowerCase();

    // Determine type
    if (lower.contains('highlight')) {
      type = 'highlight';
    } else if (lower.contains('note')) {
      type = 'note';
    } else if (lower.contains('bookmark')) {
      type = 'bookmark';
    }

    // Extract page number
    final pageMatch = RegExp(r'page\s+(\d+)', caseSensitive: false).firstMatch(line);
    if (pageMatch != null) {
      page = int.tryParse(pageMatch.group(1)!);
    }

    // Extract location range
    final locMatch =
        RegExp(r'Location\s+(\d+)(?:-(\d+))?', caseSensitive: false)
            .firstMatch(line);
    if (locMatch != null) {
      locationStart = int.tryParse(locMatch.group(1)!);
      if (locMatch.group(2) != null) {
        locationEnd = int.tryParse(locMatch.group(2)!);
      }
    }

    // Extract date: "Added on ..."
    final dateMatch =
        RegExp(r'Added on\s+(.+)$', caseSensitive: false).firstMatch(line);
    if (dateMatch != null) {
      dateAdded = _tryParseDate(dateMatch.group(1)!.trim());
    }

    return _ClippingMeta(
      type: type,
      page: page,
      locationStart: locationStart,
      locationEnd: locationEnd,
      dateAdded: dateAdded,
    );
  }

  DateTime? _tryParseDate(String dateStr) {
    try {
      // Kindle date format: "Sunday, March 15, 2024 9:30:22 PM"
      // Try multiple patterns
      final cleaned = dateStr
          .replaceFirst(
              RegExp(
                  r'^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday),\s*'),
              '')
          .trim();

      // Try: "March 15, 2024 9:30:22 PM"
      final match = RegExp(
              r'(\w+)\s+(\d+),\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})\s+(AM|PM)',
              caseSensitive: false)
          .firstMatch(cleaned);

      if (match != null) {
        final monthName = match.group(1)!;
        final day = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        var hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        final second = int.parse(match.group(6)!);
        final period = match.group(7)!.toUpperCase();

        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;

        final month = _monthNumber(monthName);
        if (month > 0) {
          return DateTime(year, month, day, hour, minute, second);
        }
      }

      return DateTime.tryParse(dateStr);
    } catch (_) {
      return null;
    }
  }

  int _monthNumber(String name) {
    const months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };
    return months[name.toLowerCase()] ?? 0;
  }

  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _ClippingMeta {
  final String type;
  final int? page;
  final int? locationStart;
  final int? locationEnd;
  final DateTime? dateAdded;

  const _ClippingMeta({
    required this.type,
    this.page,
    this.locationStart,
    this.locationEnd,
    this.dateAdded,
  });
}
