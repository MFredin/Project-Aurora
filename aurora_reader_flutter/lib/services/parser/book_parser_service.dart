import 'dart:io';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/database/database.dart';

// ─── SUPPORTED FORMATS ──────────────────────────────────────────────────────

/// All ebook formats Aurora Reader can handle.
enum BookFormat {
  epub,
  pdf,
  txt,
  fb2,
  mobi,
  cbz,
  cbr,
  rtf,
  djvu,
  azw3,
  docx;

  /// Resolve format from a file extension string (e.g. ".epub").
  static BookFormat? fromExtension(String ext) {
    final normalized = ext.toLowerCase().replaceAll('.', '');
    return BookFormat.values.cast<BookFormat?>().firstWhere(
          (f) => f!.name == normalized,
          orElse: () => null,
        );
  }

  /// Friendly display label.
  String get label => name.toUpperCase();
}

// ─── PARSED RESULT MODELS ───────────────────────────────────────────────────

/// Metadata extracted from a parsed book file.
class ParsedBookMetadata {
  final String title;
  final String author;
  final String? isbn;
  final String? description;
  final String? publisher;
  final String? language;
  final Uint8List? coverImageData;
  final BookFormat format;
  final int fileSize;

  const ParsedBookMetadata({
    required this.title,
    required this.author,
    this.isbn,
    this.description,
    this.publisher,
    this.language,
    this.coverImageData,
    required this.format,
    required this.fileSize,
  });
}

/// A single chapter extracted from a book file.
class ParsedChapter {
  final String title;
  final String content;
  final int index;

  const ParsedChapter({
    required this.title,
    required this.content,
    required this.index,
  });
}

/// Complete result from parsing a book file.
class ParsedBookResult {
  final ParsedBookMetadata metadata;
  final List<ParsedChapter> chapters;

  const ParsedBookResult({
    required this.metadata,
    required this.chapters,
  });
}

// ─── SERVICE ────────────────────────────────────────────────────────────────

/// Parses ebook files into structured metadata and chapters.
///
/// Provides full EPUB parsing via the `epubx` package and stub
/// implementations for all other supported formats (PDF, TXT, FB2, MOBI,
/// CBZ, CBR, RTF, DJVU, AZW3, DOCX). The stubs extract what they can
/// (file name, size) and return placeholder chapter content so the app
/// remains functional while full parsers are developed.
class BookParserService {
  BookParserService();

  static const _uuid = Uuid();

  /// Set of file extensions this service can attempt to parse.
  static final Set<String> supportedExtensions =
      BookFormat.values.map((f) => '.${f.name}').toSet();

  /// Returns `true` when the file at [path] has a supported extension.
  bool isSupportedFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return BookFormat.fromExtension(ext) != null;
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Parse a book file at [filePath] and return structured data.
  ///
  /// Throws [FormatException] for unsupported file types and
  /// [FileSystemException] when the file cannot be read.
  Future<ParsedBookResult> parseBook(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final format = BookFormat.fromExtension(
      filePath.split('.').last,
    );
    if (format == null) {
      throw FormatException('Unsupported ebook format: $filePath');
    }

    switch (format) {
      case BookFormat.epub:
        return _parseEpub(file);
      case BookFormat.pdf:
        return _parsePdf(file);
      case BookFormat.txt:
        return _parseTxt(file);
      case BookFormat.fb2:
        return _parseFb2(file);
      case BookFormat.mobi:
        return _parseMobi(file);
      case BookFormat.cbz:
      case BookFormat.cbr:
        return _parseComicArchive(file, format);
      case BookFormat.rtf:
        return _parseRtf(file);
      case BookFormat.djvu:
        return _parseDjvu(file);
      case BookFormat.azw3:
        return _parseAzw3(file);
      case BookFormat.docx:
        return _parseDocx(file);
    }
  }

  /// Extract only the chapter list from [filePath] without full metadata.
  Future<List<ParsedChapter>> extractChapters(String filePath) async {
    final result = await parseBook(filePath);
    return result.chapters;
  }

  /// Persist a [ParsedBookResult] into the database, creating both the
  /// [Book] row and its associated [BookChapter] rows.
  Future<String> saveToDatabase(
    AppDatabase db,
    ParsedBookResult result,
    String filePath,
  ) async {
    final bookId = _uuid.v4();

    await db.insertBook(BooksCompanion.insert(
      id: Value(bookId),
      title: result.metadata.title,
      author: result.metadata.author,
      isbn: Value(result.metadata.isbn),
      coverImageData: Value(result.metadata.coverImageData),
      fileUrl: filePath,
      format: result.metadata.format.name,
      fileSize: Value(result.metadata.fileSize),
    ));

    for (final chapter in result.chapters) {
      await db.into(db.bookChapters).insert(BookChaptersCompanion.insert(
            id: Value(_uuid.v4()),
            bookId: bookId,
            title: chapter.title,
            content: chapter.content,
            chapterIndex: chapter.index,
          ));
    }

    return bookId;
  }

  // ── EPUB (full implementation) ──────────────────────────────────────────

  Future<ParsedBookResult> _parseEpub(File file) async {
    final bytes = await file.readAsBytes();
    final epubBook = await EpubReader.readBook(bytes);

    // Extract metadata
    final title = epubBook.Title ?? _fileNameWithoutExtension(file);
    final author = epubBook.Author ?? 'Unknown Author';

    // Attempt to pull ISBN from Dublin Core identifiers
    String? isbn;
    final identifiers = epubBook.Schema?.Package?.Metadata?.Identifiers;
    if (identifiers != null) {
      for (final id in identifiers) {
        final scheme = id.Scheme?.toLowerCase() ?? '';
        if (scheme.contains('isbn')) {
          isbn = id.Identifier;
          break;
        }
      }
    }

    final description = epubBook.Schema?.Package?.Metadata?.Description;
    final publisher =
        epubBook.Schema?.Package?.Metadata?.Publishers?.firstOrNull;
    final language =
        epubBook.Schema?.Package?.Metadata?.Languages?.firstOrNull;

    // Extract cover image
    Uint8List? coverImage;
    final coverRef = epubBook.CoverImage;
    if (coverRef != null) {
      coverImage = Uint8List.fromList(coverRef.Content!);
    }

    // Extract chapters from the reading order
    final chapters = <ParsedChapter>[];
    final htmlContentMap = epubBook.Content?.Html;
    if (htmlContentMap != null) {
      var index = 0;
      for (final entry in htmlContentMap.entries) {
        final htmlContent = entry.value.Content ?? '';
        final document = html_parser.parse(htmlContent);

        // Derive a chapter title from the first heading, or fall back to
        // the file name within the EPUB archive.
        final heading = document.querySelector('h1, h2, h3, h4');
        final chapterTitle =
            heading?.text.trim() ?? 'Chapter ${index + 1}';

        // Strip HTML tags to get plain reading text.
        final plainText = document.body?.text ?? htmlContent;

        if (plainText.trim().isNotEmpty) {
          chapters.add(ParsedChapter(
            title: chapterTitle,
            content: plainText.trim(),
            index: index,
          ));
          index++;
        }
      }
    }

    // Guarantee at least one chapter so the reader view has content.
    if (chapters.isEmpty) {
      chapters.add(const ParsedChapter(
        title: 'Content',
        content: 'No readable content found in this EPUB file.',
        index: 0,
      ));
    }

    return ParsedBookResult(
      metadata: ParsedBookMetadata(
        title: title,
        author: author,
        isbn: isbn,
        description: description,
        publisher: publisher,
        language: language,
        coverImageData: coverImage,
        format: BookFormat.epub,
        fileSize: bytes.length,
      ),
      chapters: chapters,
    );
  }

  // ── PDF (metadata extraction) ───────────────────────────────────────────

  Future<ParsedBookResult> _parsePdf(File file) async {
    final fileSize = await file.length();
    final fileName = _fileNameWithoutExtension(file);

    // PDF metadata extraction would require a native PDF library.
    // For now we extract what we can from the file itself and provide
    // a single stub chapter. The reader screen uses `pdfrx` directly
    // for rendering so full text extraction is not required here.
    return ParsedBookResult(
      metadata: ParsedBookMetadata(
        title: fileName,
        author: 'Unknown Author',
        format: BookFormat.pdf,
        fileSize: fileSize,
      ),
      chapters: [
        ParsedChapter(
          title: fileName,
          content: '[PDF content rendered natively by pdfrx]',
          index: 0,
        ),
      ],
    );
  }

  // ── Plain text ──────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseTxt(File file) async {
    final content = await file.readAsString();
    final fileSize = await file.length();
    final fileName = _fileNameWithoutExtension(file);

    // Split into chapters by common delimiters (double newline sections,
    // or "Chapter X" headings). Fall back to a single chapter.
    final chapters = _splitTextIntoChapters(content);

    return ParsedBookResult(
      metadata: ParsedBookMetadata(
        title: fileName,
        author: 'Unknown Author',
        format: BookFormat.txt,
        fileSize: fileSize,
      ),
      chapters: chapters.isNotEmpty
          ? chapters
          : [
              ParsedChapter(
                title: fileName,
                content: content,
                index: 0,
              ),
            ],
    );
  }

  // ── FB2 (stub) ──────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseFb2(File file) async {
    return _stubResult(file, BookFormat.fb2,
        note: 'FB2 parsing will use XML extraction in a future release.');
  }

  // ── MOBI (stub) ─────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseMobi(File file) async {
    return _stubResult(file, BookFormat.mobi,
        note: 'MOBI/KF7 parsing is not yet implemented.');
  }

  // ── Comic archives CBZ / CBR (stub) ─────────────────────────────────────

  Future<ParsedBookResult> _parseComicArchive(
      File file, BookFormat format) async {
    return _stubResult(file, format,
        note:
            '${format.label} comic archive support is planned for a future release.');
  }

  // ── RTF (stub) ──────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseRtf(File file) async {
    return _stubResult(file, BookFormat.rtf,
        note: 'RTF parsing is not yet implemented.');
  }

  // ── DjVu (stub) ─────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseDjvu(File file) async {
    return _stubResult(file, BookFormat.djvu,
        note: 'DjVu parsing is not yet implemented.');
  }

  // ── AZW3 (stub) ─────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseAzw3(File file) async {
    return _stubResult(file, BookFormat.azw3,
        note: 'AZW3/KF8 parsing is not yet implemented.');
  }

  // ── DOCX (stub) ─────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseDocx(File file) async {
    return _stubResult(file, BookFormat.docx,
        note: 'DOCX parsing is not yet implemented.');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Generate a minimal stub result for formats not yet fully implemented.
  Future<ParsedBookResult> _stubResult(
    File file,
    BookFormat format, {
    required String note,
  }) async {
    final fileSize = await file.length();
    final fileName = _fileNameWithoutExtension(file);

    return ParsedBookResult(
      metadata: ParsedBookMetadata(
        title: fileName,
        author: 'Unknown Author',
        format: format,
        fileSize: fileSize,
      ),
      chapters: [
        ParsedChapter(
          title: fileName,
          content: note,
          index: 0,
        ),
      ],
    );
  }

  /// Split plain text content into chapters using common heading patterns.
  List<ParsedChapter> _splitTextIntoChapters(String text) {
    final chapterPattern =
        RegExp(r'(?:^|\n)(Chapter\s+\w+[^\n]*)', caseSensitive: false);
    final matches = chapterPattern.allMatches(text).toList();

    if (matches.isEmpty) return [];

    final chapters = <ParsedChapter>[];
    for (var i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      final title = matches[i].group(1)?.trim() ?? 'Chapter ${i + 1}';
      final content = text.substring(start, end).trim();

      chapters.add(ParsedChapter(
        title: title,
        content: content,
        index: i,
      ));
    }

    return chapters;
  }

  String _fileNameWithoutExtension(File file) {
    final name = file.uri.pathSegments.last;
    final dotIndex = name.lastIndexOf('.');
    return dotIndex > 0 ? name.substring(0, dotIndex) : name;
  }
}

// ─── RIVERPOD PROVIDER ──────────────────────────────────────────────────────

final bookParserServiceProvider = Provider<BookParserService>((ref) {
  return BookParserService();
});
