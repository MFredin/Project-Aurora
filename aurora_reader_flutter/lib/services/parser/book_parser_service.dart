import 'dart:convert';
import 'dart:io' if (dart.library.html) 'platform/web_stub_io.dart';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:html/parser.dart' as html_parser;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart' as xml;
import '../logging/error_logger.dart';
import 'text_processor.dart';
import 'mobi_parser.dart';

// ─── SUPPORTED FORMATS ──────────────────────────────────────────────────────

enum BookFormat {
  epub,
  pdf,
  txt,
  fb2,
  mobi,
  azw,
  azw3,
  kfx,
  cbz,
  cbr,
  rtf,
  djvu,
  docx;

  static BookFormat? fromExtension(String ext) {
    final normalized = ext.toLowerCase().replaceAll('.', '');
    return BookFormat.values.cast<BookFormat?>().firstWhere(
          (f) => f!.name == normalized,
          orElse: () => null,
        );
  }

  String get label => name.toUpperCase();
}

// ─── PARSED RESULT MODELS ───────────────────────────────────────────────────

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

class ParsedBookResult {
  final ParsedBookMetadata metadata;
  final List<ParsedChapter> chapters;
  final Uint8List? rawFileData;

  const ParsedBookResult({
    required this.metadata,
    required this.chapters,
    this.rawFileData,
  });
}

// ─── SERVICE ────────────────────────────────────────────────────────────────

class BookParserService {
  BookParserService();

  static const _uuid = Uuid();

  static final Set<String> supportedExtensions =
      BookFormat.values.map((f) => '.${f.name}').toSet();

  bool isSupportedFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return BookFormat.fromExtension(ext) != null;
  }

  // ── Public API ──────────────────────────────────────────────────────────

  Future<ParsedBookResult> parseBook(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError('Use parseBookFromBytes on web');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final format = BookFormat.fromExtension(filePath.split('.').last);
    if (format == null) {
      throw FormatException('Unsupported ebook format: $filePath');
    }

    final bytes = Uint8List.fromList(await file.readAsBytes());
    final fileName = file.uri.pathSegments.last;
    return _parseByFormat(bytes, fileName, format);
  }

  Future<ParsedBookResult> parseBookFromBytes(
      Uint8List bytes, String filename) async {
    final format = BookFormat.fromExtension(filename.split('.').last);
    if (format == null) {
      throw FormatException('Unsupported ebook format: $filename');
    }
    return _parseByFormat(bytes, filename, format);
  }

  Future<ParsedBookResult> _parseByFormat(
      Uint8List bytes, String filename, BookFormat format) {
    switch (format) {
      case BookFormat.epub:
        return _parseEpubFromBytes(bytes, filename);
      case BookFormat.pdf:
        return _parsePdf(bytes, filename);
      case BookFormat.txt:
        return _parseTxtFromBytes(bytes, filename);
      case BookFormat.fb2:
        return _parseFb2(bytes, filename);
      case BookFormat.mobi:
      case BookFormat.azw:
        return _parseMobi(bytes, filename, format);
      case BookFormat.azw3:
        return _parseAzw3(bytes, filename);
      case BookFormat.kfx:
        return _parseKfx(bytes, filename);
      case BookFormat.cbz:
      case BookFormat.cbr:
        return _parseComicArchive(bytes, filename, format);
      case BookFormat.rtf:
        return _parseRtf(bytes, filename);
      case BookFormat.djvu:
        return _parseDjvu(bytes, filename);
      case BookFormat.docx:
        return _parseDocx(bytes, filename);
    }
  }

  Future<List<ParsedChapter>> extractChapters(String filePath) async {
    final result = await parseBook(filePath);
    return result.chapters;
  }

  // ── EPUB ───────────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseEpubFromBytes(
      Uint8List bytes, String filename) async {
    final epubBook = await EpubReader.readBook(bytes);

    final title = epubBook.Title ?? _fileNameWithoutExtension(filename);
    final author = epubBook.Author ?? 'Unknown Author';

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

    Uint8List? coverImage;
    final coverRef = epubBook.CoverImage;
    if (coverRef != null) {
      try {
        coverImage = Uint8List.fromList(img.encodePng(coverRef));
      } catch (e, stack) {
        ErrorLogger.instance
            .capture(e, stackTrace: stack, source: 'BookParser.coverEncode');
      }
    }

    final chapters = <ParsedChapter>[];
    final htmlContentMap = epubBook.Content?.Html;
    if (htmlContentMap != null) {
      var index = 0;
      for (final entry in htmlContentMap.entries) {
        final htmlContent = entry.value.Content ?? '';
        final document = html_parser.parse(htmlContent);

        final heading = document.querySelector('h1, h2, h3, h4');
        final chapterTitle = heading?.text.trim() ?? 'Chapter ${index + 1}';

        final plainText = document.body?.text ?? htmlContent;
        final normalized = TextProcessor.normalize(plainText);

        if (normalized.isNotEmpty) {
          chapters.add(ParsedChapter(
            title: chapterTitle,
            content: normalized,
            index: index,
          ));
          index++;
        }
      }
    }

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

  // ── PDF ────────────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parsePdf(Uint8List bytes, String filename) async {
    final fileName = _fileNameWithoutExtension(filename);
    return ParsedBookResult(
      metadata: ParsedBookMetadata(
        title: fileName,
        author: 'Unknown Author',
        format: BookFormat.pdf,
        fileSize: bytes.length,
      ),
      chapters: [
        ParsedChapter(
          title: fileName,
          content: '',
          index: 0,
        ),
      ],
      rawFileData: bytes,
    );
  }

  // ── Plain text ─────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseTxtFromBytes(
      Uint8List bytes, String filename) async {
    final content = utf8.decode(bytes, allowMalformed: true);
    final fileName = _fileNameWithoutExtension(filename);
    final normalized = TextProcessor.normalize(content);

    final chapters = _splitTextIntoChapters(normalized);

    return ParsedBookResult(
      metadata: ParsedBookMetadata(
        title: fileName,
        author: 'Unknown Author',
        format: BookFormat.txt,
        fileSize: bytes.length,
      ),
      chapters: chapters.isNotEmpty
          ? chapters
          : [
              ParsedChapter(
                title: fileName,
                content: normalized,
                index: 0,
              ),
            ],
    );
  }

  // ── FB2 ────────────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseFb2(Uint8List bytes, String filename) async {
    final xmlString = utf8.decode(bytes, allowMalformed: true);
    final document = xml.XmlDocument.parse(xmlString);

    final titleInfo = document.findAllElements('title-info').firstOrNull;

    final bookTitle =
        titleInfo?.findElements('book-title').firstOrNull?.innerText.trim() ??
            _fileNameWithoutExtension(filename);

    var author = 'Unknown Author';
    final authorEl = titleInfo?.findElements('author').firstOrNull;
    if (authorEl != null) {
      final first =
          authorEl.findElements('first-name').firstOrNull?.innerText.trim() ??
              '';
      final last =
          authorEl.findElements('last-name').firstOrNull?.innerText.trim() ??
              '';
      final combined = '$first $last'.trim();
      if (combined.isNotEmpty) author = combined;
    }

    final lang =
        titleInfo?.findElements('lang').firstOrNull?.innerText.trim();

    final annotation =
        titleInfo?.findElements('annotation').firstOrNull?.innerText.trim();

    Uint8List? coverImage;
    final coverPage = titleInfo?.findElements('coverpage').firstOrNull;
    if (coverPage != null) {
      final imageEl = coverPage.findElements('image').firstOrNull;
      final href = imageEl?.getAttribute('l:href') ??
          imageEl?.getAttribute('xlink:href') ??
          imageEl?.getAttribute('href');
      if (href != null) {
        final id = href.replaceFirst('#', '');
        final binary = document
            .findAllElements('binary')
            .where((b) => b.getAttribute('id') == id)
            .firstOrNull;
        if (binary != null) {
          try {
            coverImage = base64Decode(
                binary.innerText.replaceAll(RegExp(r'\s'), ''));
          } catch (e) {
            ErrorLogger.instance.capture(e, source: 'BookParser.fb2Cover');
          }
        }
      }
    }

    final chapters = <ParsedChapter>[];
    final body = document.findAllElements('body').firstOrNull;
    if (body != null) {
      var index = 0;
      for (final section in body.findElements('section')) {
        final sectionTitle = section
                .findElements('title')
                .firstOrNull
                ?.innerText
                .trim() ??
            'Chapter ${index + 1}';

        final buffer = StringBuffer();
        _extractFb2Text(section, buffer);

        final content = TextProcessor.normalize(buffer.toString());
        if (content.isNotEmpty) {
          chapters.add(ParsedChapter(
            title: sectionTitle,
            content: content,
            index: index,
          ));
          index++;
        }
      }
    }

    if (chapters.isEmpty) {
      chapters.add(const ParsedChapter(
        title: 'Content',
        content: 'No readable content found in this FB2 file.',
        index: 0,
      ));
    }

    return ParsedBookResult(
      metadata: ParsedBookMetadata(
        title: bookTitle,
        author: author,
        description: annotation,
        language: lang,
        coverImageData: coverImage,
        format: BookFormat.fb2,
        fileSize: bytes.length,
      ),
      chapters: chapters,
    );
  }

  void _extractFb2Text(xml.XmlElement element, StringBuffer buffer) {
    for (final child in element.children) {
      if (child is xml.XmlElement) {
        final tag = child.name.local;
        if (tag == 'title') continue;
        if (tag == 'section') continue;
        if (tag == 'p' || tag == 'empty-line') {
          if (buffer.isNotEmpty) buffer.write('\n\n');
          _extractFb2Text(child, buffer);
        } else if (tag == 'emphasis' || tag == 'strong') {
          _extractFb2Text(child, buffer);
        } else if (tag == 'a') {
          _extractFb2Text(child, buffer);
        } else {
          _extractFb2Text(child, buffer);
        }
      } else if (child is xml.XmlText) {
        buffer.write(child.value);
      }
    }
  }

  // ── MOBI / AZW ────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseMobi(
      Uint8List bytes, String filename, BookFormat format) async {
    try {
      final result = MobiParser.parse(bytes);
      final normalized = TextProcessor.normalize(result.textContent);
      final chapters = _splitTextIntoChapters(normalized);

      return ParsedBookResult(
        metadata: ParsedBookMetadata(
          title: result.title.isNotEmpty
              ? result.title
              : _fileNameWithoutExtension(filename),
          author: result.author,
          isbn: result.isbn,
          description: result.description,
          publisher: result.publisher,
          language: result.language,
          coverImageData: result.coverImage,
          format: format,
          fileSize: bytes.length,
        ),
        chapters: chapters.isNotEmpty
            ? chapters
            : [
                ParsedChapter(
                  title: result.title.isNotEmpty
                      ? result.title
                      : _fileNameWithoutExtension(filename),
                  content: normalized,
                  index: 0,
                ),
              ],
      );
    } on MobiParseException catch (e) {
      final name = _fileNameWithoutExtension(filename);
      return ParsedBookResult(
        metadata: ParsedBookMetadata(
          title: name,
          author: 'Unknown Author',
          format: format,
          fileSize: bytes.length,
        ),
        chapters: [
          ParsedChapter(title: name, content: e.message, index: 0),
        ],
      );
    }
  }

  // ── AZW3 ───────────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseAzw3(
      Uint8List bytes, String filename) async {
    try {
      return await _parseMobi(bytes, filename, BookFormat.azw3);
    } catch (_) {
      return _stubResult(bytes.length, filename, BookFormat.azw3,
          note: 'This AZW3/KF8 file could not be parsed.\n\n'
              'Try converting it to EPUB using Calibre for the best '
              'reading experience.');
    }
  }

  // ── KFX ────────────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseKfx(
      Uint8List bytes, String filename) async {
    return _stubResult(bytes.length, filename, BookFormat.kfx,
        note: 'KFX is Amazon\'s proprietary format and cannot be '
            'parsed directly.\n\n'
            'To read this book in Edda, convert it to EPUB using Calibre.');
  }

  // ── Comic archives CBZ / CBR ───────────────────────────────────────────

  Future<ParsedBookResult> _parseComicArchive(
      Uint8List bytes, String filename, BookFormat format) async {
    return _stubResult(bytes.length, filename, format,
        note: '${format.label} comic archive support is planned for '
            'a future release.');
  }

  // ── RTF ────────────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseRtf(
      Uint8List bytes, String filename) async {
    return _stubResult(bytes.length, filename, BookFormat.rtf,
        note: 'RTF parsing is not yet implemented.');
  }

  // ── DjVu ───────────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseDjvu(
      Uint8List bytes, String filename) async {
    return _stubResult(bytes.length, filename, BookFormat.djvu,
        note: 'DjVu parsing is not yet implemented.');
  }

  // ── DOCX ───────────────────────────────────────────────────────────────

  Future<ParsedBookResult> _parseDocx(
      Uint8List bytes, String filename) async {
    return _stubResult(bytes.length, filename, BookFormat.docx,
        note: 'DOCX parsing is not yet implemented.');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  ParsedBookResult _stubResult(
    int fileSize,
    String fileName,
    BookFormat format, {
    required String note,
  }) {
    final name = _fileNameWithoutExtension(fileName);
    return ParsedBookResult(
      metadata: ParsedBookMetadata(
        title: name,
        author: 'Unknown Author',
        format: format,
        fileSize: fileSize,
      ),
      chapters: [
        ParsedChapter(title: name, content: note, index: 0),
      ],
    );
  }

  List<ParsedChapter> _splitTextIntoChapters(String text) {
    final chapterPattern =
        RegExp(r'(?:^|\n)(Chapter\s+\w+[^\n]*)', caseSensitive: false);
    final matches = chapterPattern.allMatches(text).toList();

    if (matches.isEmpty) return [];

    final chapters = <ParsedChapter>[];
    for (var i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end =
          i + 1 < matches.length ? matches[i + 1].start : text.length;
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

  String _fileNameWithoutExtension(String name) {
    final dotIndex = name.lastIndexOf('.');
    return dotIndex > 0 ? name.substring(0, dotIndex) : name;
  }
}

// ─── RIVERPOD PROVIDER ──────────────────────────────────────────────────────

final bookParserServiceProvider = Provider<BookParserService>((ref) {
  return BookParserService();
});
