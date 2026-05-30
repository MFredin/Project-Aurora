import 'dart:math';

class TextProcessor {
  TextProcessor._();

  static String normalize(String raw) {
    if (raw.trim().isEmpty) return raw;

    var text = raw;
    text = _normalizeLineEndings(text);
    text = _stripResidualHtml(text);
    text = _decodeEntities(text);

    final lines = text.split('\n');
    if (_isHardWrapped(lines)) {
      text = _unwrapParagraphs(lines);
    }

    text = _fixSentenceSpacing(text);
    text = _normalizeWhitespace(text);
    text = _normalizeParagraphs(text);
    text = _fixQuotes(text);

    return text.trim();
  }

  static String _normalizeLineEndings(String text) {
    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  static String _stripResidualHtml(String text) {
    text = text.replaceAll(RegExp(r'<br\s*/?\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(
        RegExp(r'</(p|div|h[1-6]|li|tr|blockquote)>', caseSensitive: false),
        '\n\n');
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    return text;
  }

  static String _decodeEntities(String text) {
    const entities = {
      '&nbsp;': ' ',
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
      '&#39;': "'",
      '&mdash;': '—',
      '&ndash;': '–',
      '&hellip;': '…',
      '&lsquo;': '‘',
      '&rsquo;': '’',
      '&ldquo;': '“',
      '&rdquo;': '”',
    };
    for (final entry in entities.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    text = text.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m[1]!)),
    );
    text = text.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
    );
    return text;
  }

  static bool _isHardWrapped(List<String> lines) {
    final meaningful =
        lines.where((l) => l.trim().length > 25).map((l) => l.trim()).toList();
    if (meaningful.length < 8) return false;

    final lengths = meaningful.map((l) => l.length).toList()..sort();
    final median = lengths[lengths.length ~/ 2];

    if (median < 40 || median > 120) return false;

    final tolerance = max(5, (median * 0.08).round());
    final nearMedian =
        lengths.where((l) => (l - median).abs() <= tolerance).length;
    return nearMedian / lengths.length > 0.35;
  }

  static String _unwrapParagraphs(List<String> lines) {
    final paragraphs = <String>[];
    final current = StringBuffer();

    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();

      if (trimmed.isEmpty) {
        if (current.isNotEmpty) {
          paragraphs.add(current.toString().trim());
          current.clear();
        }
        continue;
      }

      final looksLikeParagraphStart = i > 0 &&
          lines[i].startsWith('  ') &&
          current.isNotEmpty;

      final prevEndsSentence = current.isNotEmpty &&
          RegExp(r'[.!?:;"”’]\s*$')
              .hasMatch(current.toString()) &&
          trimmed.isNotEmpty &&
          trimmed[0] == trimmed[0].toUpperCase() &&
          trimmed[0] != trimmed[0].toLowerCase();

      if (looksLikeParagraphStart || prevEndsSentence) {
        if (current.isNotEmpty) {
          paragraphs.add(current.toString().trim());
          current.clear();
        }
      }

      if (current.isNotEmpty) {
        final currentStr = current.toString();
        if (currentStr.endsWith('-')) {
          final dehyphenated =
              currentStr.substring(0, currentStr.length - 1);
          current.clear();
          current.write(dehyphenated);
        } else {
          current.write(' ');
        }
      }
      current.write(trimmed);
    }

    if (current.isNotEmpty) {
      paragraphs.add(current.toString().trim());
    }

    return paragraphs.join('\n\n');
  }

  static final _abbreviations = RegExp(
    r'(?:Mr|Mrs|Ms|Dr|Prof|Sr|Jr|St|Gen|Gov|Sgt|Cpl|Pvt|'
    r'Inc|Ltd|Corp|Co|Vol|Rev|Sgt|etc|vs|approx|dept|est|'
    r'i\.e|e\.g|cf|al|fig|ch|no)\.$',
    caseSensitive: false,
  );

  static String _fixSentenceSpacing(String text) {
    text = text.replaceAllMapped(
      RegExp(r'([.!?])([A-ZÀ-ɏ])'),
      (m) {
        final before =
            text.substring(max(0, m.start - 10), m.start) + m[1]!;
        if (_abbreviations.hasMatch(before)) return m[0]!;
        return '${m[1]} ${m[2]}';
      },
    );

    text = text.replaceAllMapped(
      RegExp(r',([a-zA-Z])'),
      (m) => ', ${m[1]}',
    );

    text = text.replaceAllMapped(
      RegExp(r';([a-zA-Z])'),
      (m) => '; ${m[1]}',
    );

    return text;
  }

  static String _normalizeWhitespace(String text) {
    text = text.replaceAll('\t', ' ');
    text = text.replaceAll(RegExp(r'[^\S\n]+'), ' ');
    text = text.replaceAll(RegExp(r' *\n *'), '\n');
    return text;
  }

  static String _normalizeParagraphs(String text) {
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    final paragraphs = text.split('\n\n');
    return paragraphs
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .join('\n\n');
  }

  static String _fixQuotes(String text) {
    text = text.replaceAll(RegExp(r'"+'), '"');
    text = text.replaceAll(RegExp(r"'+"), "'");
    return text;
  }
}
