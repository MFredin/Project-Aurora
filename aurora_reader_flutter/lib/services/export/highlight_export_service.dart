import 'dart:convert';

import 'package:intl/intl.dart';
import '../../core/data/models.dart';
import 'platform/export_native.dart'
    if (dart.library.html) 'platform/export_web.dart' as platform;

class HighlightExportService {
  final List<BookModel> books;

  HighlightExportService(this.books);

  Future<String> exportAllMarkdown() async {
    final buffer = StringBuffer();
    buffer.writeln('# Edda — Highlights & Notes Export');
    buffer.writeln('');
    buffer.writeln(
        '_Exported ${DateFormat.yMMMd().format(DateTime.now())}_');
    buffer.writeln('');

    for (final book in books) {
      if (book.highlights.isEmpty && book.readingNotes.isEmpty) continue;

      buffer.writeln('## ${book.title}');
      buffer.writeln('');
      buffer.writeln('**Author:** ${book.author}');
      if (book.rating != null) {
        buffer.writeln('**Rating:** ${book.rating}');
      }
      if (book.moods.isNotEmpty) {
        buffer.writeln('**Moods:** ${book.moods.join(", ")}');
      }
      if (book.pace != null) {
        buffer.writeln('**Pace:** ${book.pace!.label}');
      }
      if (book.review.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('### Review');
        buffer.writeln('');
        buffer.writeln(book.review);
      }
      buffer.writeln('');

      if (book.highlights.isNotEmpty) {
        buffer.writeln('### Highlights');
        buffer.writeln('');
        for (final h in book.highlights) {
          buffer.writeln('> ${h.highlightedText}');
          if (h.note.isNotEmpty) {
            buffer.writeln('');
            buffer.writeln('**Note:** ${h.note}');
          }
          buffer.writeln(
              '_Chapter ${h.chapterIndex + 1} · ${DateFormat.yMMMd().format(h.dateCreated)}_');
          buffer.writeln('');
        }
      }

      if (book.readingNotes.isNotEmpty) {
        buffer.writeln('### Reading Notes');
        buffer.writeln('');
        for (final n in book.readingNotes) {
          buffer.writeln(
              '**${(n.progressPercent * 100).toInt()}% · Chapter ${n.chapterIndex + 1}** — ${DateFormat.yMMMd().format(n.dateCreated)}');
          buffer.writeln('');
          buffer.writeln(n.note);
          buffer.writeln('');
        }
      }

      buffer.writeln('---');
      buffer.writeln('');
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return platform.writeFile(
        'edda_highlights_$timestamp', buffer.toString(), 'md');
  }

  Future<String> exportAllJson() async {
    final data = books
        .where((b) => b.highlights.isNotEmpty || b.readingNotes.isNotEmpty)
        .map((book) => {
              'title': book.title,
              'author': book.author,
              'isbn': book.isbn,
              'rating': book.rating,
              'moods': book.moods,
              'pace': book.pace?.name,
              'status': book.readingStatus.name,
              'review': book.review.isNotEmpty ? book.review : null,
              'customTags': book.customTags,
              'highlights': book.highlights
                  .map((h) => {
                        'text': h.highlightedText,
                        'note': h.note,
                        'color': h.colorName,
                        'chapter': h.chapterIndex,
                        'date': h.dateCreated.toIso8601String(),
                      })
                  .toList(),
              'readingNotes': book.readingNotes
                  .map((n) => {
                        'note': n.note,
                        'chapter': n.chapterIndex,
                        'progress': n.progressPercent,
                        'date': n.dateCreated.toIso8601String(),
                      })
                  .toList(),
            })
        .toList();

    final content = const JsonEncoder.withIndent('  ').convert(data);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return platform.writeFile(
        'edda_highlights_$timestamp', content, 'json');
  }

  Future<String> exportAllCsv() async {
    final buffer = StringBuffer();
    buffer.writeln(
        'book_title,author,highlighted_text,note,chapter,color,date');

    for (final book in books) {
      for (final h in book.highlights) {
        final text = h.highlightedText.replaceAll('"', '""');
        final note = h.note.replaceAll('"', '""');
        buffer.writeln(
            '"${book.title}","${book.author}","$text","$note",${h.chapterIndex},"${h.colorName}","${h.dateCreated.toIso8601String()}"');
      }
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return platform.writeFile(
        'edda_highlights_$timestamp', buffer.toString(), 'csv');
  }

  Future<String> exportBookMarkdown(BookModel book) async {
    final buffer = StringBuffer();
    buffer.writeln('# ${book.title}');
    buffer.writeln('');
    buffer.writeln('**Author:** ${book.author}');
    buffer.writeln('**Status:** ${book.readingStatus.label}');
    if (book.rating != null) {
      buffer.writeln('**Rating:** ${'★' * book.rating!.floor()}${book.rating! % 1 >= 0.5 ? '½' : ''}${book.rating! % 1 >= 0.25 && book.rating! % 1 < 0.5 ? '¼' : ''} (${book.rating})');
    }
    if (book.moods.isNotEmpty) {
      buffer.writeln('**Moods:** ${book.moods.join(", ")}');
    }
    if (book.pace != null) {
      buffer.writeln('**Pace:** ${book.pace!.label}');
    }
    if (book.customTags.isNotEmpty) {
      buffer.writeln('**Tags:** ${book.customTags.join(", ")}');
    }
    if (book.startDate != null) {
      buffer.writeln(
          '**Started:** ${DateFormat.yMMMd().format(book.startDate!)}');
    }
    if (book.finishDate != null) {
      buffer.writeln(
          '**Finished:** ${DateFormat.yMMMd().format(book.finishDate!)}');
    }
    buffer.writeln('');

    if (book.review.isNotEmpty) {
      buffer.writeln('## Review');
      buffer.writeln('');
      buffer.writeln(book.review);
      buffer.writeln('');
    }

    if (book.highlights.isNotEmpty) {
      buffer.writeln('## Highlights');
      buffer.writeln('');
      for (final h in book.highlights) {
        buffer.writeln('> ${h.highlightedText}');
        if (h.note.isNotEmpty) {
          buffer.writeln('');
          buffer.writeln('**Note:** ${h.note}');
        }
        buffer.writeln(
            '_Chapter ${h.chapterIndex + 1} · ${DateFormat.yMMMd().format(h.dateCreated)}_');
        buffer.writeln('');
      }
    }

    if (book.readingNotes.isNotEmpty) {
      buffer.writeln('## Reading Notes');
      buffer.writeln('');
      for (final n in book.readingNotes) {
        buffer.writeln(
            '**${(n.progressPercent * 100).toInt()}%** — ${DateFormat.yMMMd().format(n.dateCreated)}');
        buffer.writeln('');
        buffer.writeln(n.note);
        buffer.writeln('');
      }
    }

    final safeName = book.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return platform.writeFile('edda_$safeName', buffer.toString(), 'md');
  }

  Future<String> exportToObsidian() async {
    final allBuffers = <String, String>{};

    for (final book in books) {
      if (book.highlights.isEmpty &&
          book.readingNotes.isEmpty &&
          book.savedQuotes.isEmpty &&
          book.review.isEmpty) continue;

      final buffer = StringBuffer();

      // YAML frontmatter
      buffer.writeln('---');
      buffer.writeln('title: "${book.title.replaceAll('"', '\\"')}"');
      buffer.writeln('author: "${book.author.replaceAll('"', '\\"')}"');
      if (book.isbn != null) buffer.writeln('isbn: "${book.isbn}"');
      buffer.writeln('status: ${book.readingStatus.label}');
      if (book.rating != null) buffer.writeln('rating: ${book.rating}');
      if (book.pace != null) buffer.writeln('pace: ${book.pace!.label}');
      if (book.moods.isNotEmpty) {
        buffer.writeln('moods:');
        for (final m in book.moods) {
          buffer.writeln('  - $m');
        }
      }
      if (book.customTags.isNotEmpty) {
        buffer.writeln('tags:');
        for (final t in book.customTags) {
          buffer.writeln('  - $t');
        }
      }
      if (book.startDate != null) {
        buffer.writeln(
            'date_started: ${DateFormat('yyyy-MM-dd').format(book.startDate!)}');
      }
      if (book.finishDate != null) {
        buffer.writeln(
            'date_finished: ${DateFormat('yyyy-MM-dd').format(book.finishDate!)}');
      }
      if (book.seriesName != null) {
        buffer.writeln(
            'series: "${book.seriesName!.replaceAll('"', '\\"')}"');
        if (book.seriesPosition != null) {
          buffer.writeln('series_position: ${book.seriesPosition}');
        }
      }
      buffer.writeln('---');
      buffer.writeln('');

      buffer.writeln('# ${book.title}');
      buffer.writeln('');
      buffer.writeln('**Author:** [[${book.author}]]');
      if (book.seriesName != null) {
        buffer.writeln(
            '**Series:** [[${book.seriesName}]]${book.seriesPosition != null ? " #${book.seriesPosition}" : ""}');
      }
      buffer.writeln('');

      // Tags as hashtags
      if (book.moods.isNotEmpty || book.customTags.isNotEmpty) {
        final tags = [
          ...book.moods.map((m) => '#$m'),
          ...book.customTags.map((t) => '#${t.replaceAll(' ', '_')}'),
        ];
        buffer.writeln(tags.join(' '));
        buffer.writeln('');
      }

      if (book.review.isNotEmpty) {
        buffer.writeln('## Review');
        buffer.writeln('');
        buffer.writeln(book.review);
        buffer.writeln('');
      }

      if (book.highlights.isNotEmpty) {
        buffer.writeln('## Highlights');
        buffer.writeln('');
        for (final h in book.highlights) {
          buffer.writeln('> [!quote]');
          buffer.writeln('> ${h.highlightedText}');
          if (h.note.isNotEmpty) {
            buffer.writeln('> **Note:** ${h.note}');
          }
          buffer.writeln(
              '> _Ch. ${h.chapterIndex + 1} · ${DateFormat.yMMMd().format(h.dateCreated)}_');
          buffer.writeln('');
        }
      }

      if (book.savedQuotes.isNotEmpty) {
        buffer.writeln('## Saved Quotes');
        buffer.writeln('');
        for (final q in book.savedQuotes) {
          buffer.writeln('> [!quote]');
          buffer.writeln('> ${q.text}');
          if (q.note.isNotEmpty) {
            buffer.writeln('> **Note:** ${q.note}');
          }
          final ref = q.pageRef != null ? ' · p.${q.pageRef}' : '';
          buffer.writeln(
              '> _Ch. ${q.chapterIndex + 1}$ref · ${DateFormat.yMMMd().format(q.dateCreated)}_');
          buffer.writeln('');
        }
      }

      if (book.readingNotes.isNotEmpty) {
        buffer.writeln('## Reading Notes');
        buffer.writeln('');
        for (final n in book.readingNotes) {
          buffer.writeln(
              '### ${(n.progressPercent * 100).toInt()}% — ${DateFormat.yMMMd().format(n.dateCreated)}');
          buffer.writeln('');
          buffer.writeln(n.note);
          buffer.writeln('');
        }
      }

      final safeName = book.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      allBuffers['edda_$safeName'] = buffer.toString();
    }

    String lastPath = '';
    for (final entry in allBuffers.entries) {
      lastPath = await platform.writeFile(entry.key, entry.value, 'md');
    }
    return lastPath;
  }

  Future<String> exportNotionJson() async {
    final data = books
        .where((b) =>
            b.highlights.isNotEmpty ||
            b.readingNotes.isNotEmpty ||
            b.savedQuotes.isNotEmpty ||
            b.review.isNotEmpty)
        .map((book) => {
              'title': book.title,
              'author': book.author,
              'isbn': book.isbn,
              'status': book.readingStatus.label,
              'rating': book.rating,
              'moods': book.moods,
              'pace': book.pace?.label,
              'customTags': book.customTags,
              'series': book.seriesName,
              'seriesPosition': book.seriesPosition,
              'startDate': book.startDate?.toIso8601String(),
              'finishDate': book.finishDate?.toIso8601String(),
              'review': book.review.isNotEmpty ? book.review : null,
              'highlights': book.highlights
                  .map((h) => {
                        'text': h.highlightedText,
                        'note': h.note,
                        'chapter': h.chapterIndex + 1,
                        'color': h.colorName,
                        'date': h.dateCreated.toIso8601String(),
                      })
                  .toList(),
              'savedQuotes': book.savedQuotes
                  .map((q) => {
                        'text': q.text,
                        'note': q.note,
                        'chapter': q.chapterIndex + 1,
                        'page': q.pageRef,
                        'date': q.dateCreated.toIso8601String(),
                      })
                  .toList(),
              'readingNotes': book.readingNotes
                  .map((n) => {
                        'note': n.note,
                        'chapter': n.chapterIndex + 1,
                        'progress': n.progressPercent,
                        'date': n.dateCreated.toIso8601String(),
                      })
                  .toList(),
            })
        .toList();

    final content = const JsonEncoder.withIndent('  ').convert({
      'exportedFrom': 'Edda',
      'exportDate': DateTime.now().toIso8601String(),
      'books': data,
    });
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return platform.writeFile(
        'edda_notion_export_$timestamp', content, 'json');
  }
}
