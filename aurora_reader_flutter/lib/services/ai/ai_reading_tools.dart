import '../../core/data/models.dart';
import 'ai_companion_service.dart';

/// Enhanced AI reading tools built on top of the AI companion service.
class AiReadingTools {
  final AICompanionService _aiService;

  AiReadingTools(this._aiService);

  // ── Story So Far ──────────────────────────────────────────────────────────

  /// Generate a spoiler-free recap up to the user's current reading position.
  Future<String> generateStorySoFar(BookModel book) async {
    final currentChapter = book.progress.currentChapter;
    if (book.chapters.isEmpty) {
      return 'No chapters available for this book.';
    }

    final chaptersUpToCurrent = book.chapters
        .where((ch) => ch.index <= currentChapter)
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (chaptersUpToCurrent.isEmpty) {
      return 'You have not started reading yet.';
    }

    // Build a context summary from chapter content (truncate long chapters)
    final contextBuffer = StringBuffer();
    contextBuffer.writeln('Book: ${book.title} by ${book.author}');
    contextBuffer.writeln(
        'Current position: Chapter ${currentChapter + 1} of ${book.chapters.length}');
    contextBuffer.writeln('---');

    for (final chapter in chaptersUpToCurrent) {
      final content = chapter.content;
      // Truncate to first 2000 characters per chapter for prompt efficiency
      final truncated =
          content.length > 2000 ? content.substring(0, 2000) : content;
      contextBuffer.writeln('Chapter ${chapter.index + 1}: ${chapter.title}');
      contextBuffer.writeln(truncated);
      contextBuffer.writeln('---');
    }

    final prompt =
        'Based on the following chapters of "${book.title}" by ${book.author}, '
        'generate a concise, spoiler-free recap of the story so far. '
        'Only reference events from the provided chapters. '
        'Do not reveal anything that happens after Chapter ${currentChapter + 1}.\n\n'
        '${contextBuffer.toString()}';

    return _aiService.askQuestion(
      bookId: book.id,
      question: prompt,
      chapterContext: contextBuffer.toString(),
    );
  }

  // ── Character Tracker ─────────────────────────────────────────────────────

  /// Extract a list of characters and their relationships from the book
  /// up to the current reading position.
  Future<List<CharacterInfo>> extractCharacters(BookModel book) async {
    final currentChapter = book.progress.currentChapter;
    if (book.chapters.isEmpty) return [];

    final chaptersUpToCurrent = book.chapters
        .where((ch) => ch.index <= currentChapter)
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (chaptersUpToCurrent.isEmpty) return [];

    final contextBuffer = StringBuffer();
    for (final chapter in chaptersUpToCurrent) {
      final content = chapter.content;
      final truncated =
          content.length > 1500 ? content.substring(0, 1500) : content;
      contextBuffer.writeln('[Chapter ${chapter.index + 1}: ${chapter.title}]');
      contextBuffer.writeln(truncated);
      contextBuffer.writeln();
    }

    final prompt =
        'Analyze the following text from "${book.title}" by ${book.author} '
        '(Chapters 1-${currentChapter + 1}) and extract all named characters. '
        'For each character provide:\n'
        '- Name\n'
        '- Brief description (1-2 sentences)\n'
        '- Key relationships (e.g., "sister of X", "mentor to Y")\n'
        '- First appearance chapter number\n\n'
        'Format each character as:\n'
        'NAME: [name]\n'
        'DESCRIPTION: [description]\n'
        'RELATIONSHIPS: [comma-separated list]\n'
        'FIRST_CHAPTER: [number]\n'
        '---\n\n'
        '${contextBuffer.toString()}';

    final response = await _aiService.askQuestion(
      bookId: book.id,
      question: prompt,
      chapterContext: contextBuffer.toString(),
    );

    return _parseCharacters(response);
  }

  List<CharacterInfo> _parseCharacters(String response) {
    final characters = <CharacterInfo>[];
    final blocks = response.split('---');

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      String name = '';
      String description = '';
      List<String> relationships = [];
      int firstChapter = 1;

      for (final line in trimmed.split('\n')) {
        final lower = line.trim();
        if (lower.startsWith('NAME:')) {
          name = lower.substring(5).trim();
        } else if (lower.startsWith('DESCRIPTION:')) {
          description = lower.substring(12).trim();
        } else if (lower.startsWith('RELATIONSHIPS:')) {
          relationships = lower
              .substring(14)
              .trim()
              .split(',')
              .map((r) => r.trim())
              .where((r) => r.isNotEmpty)
              .toList();
        } else if (lower.startsWith('FIRST_CHAPTER:')) {
          firstChapter =
              int.tryParse(lower.substring(14).trim()) ?? 1;
        }
      }

      if (name.isNotEmpty) {
        characters.add(CharacterInfo(
          name: name,
          description: description,
          relationships: relationships,
          firstAppearanceChapter: firstChapter,
        ));
      }
    }

    return characters;
  }

  // ── Reading Comprehension Q&A ─────────────────────────────────────────────

  /// Answer a question about the book using only content up to the current
  /// reading position.
  Future<String> answerQuestion(BookModel book, String question) async {
    final currentChapter = book.progress.currentChapter;
    if (book.chapters.isEmpty) {
      return 'No chapters available to answer questions about.';
    }

    final chaptersUpToCurrent = book.chapters
        .where((ch) => ch.index <= currentChapter)
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final contextBuffer = StringBuffer();
    for (final chapter in chaptersUpToCurrent) {
      final content = chapter.content;
      final truncated =
          content.length > 1500 ? content.substring(0, 1500) : content;
      contextBuffer.writeln('[Chapter ${chapter.index + 1}: ${chapter.title}]');
      contextBuffer.writeln(truncated);
      contextBuffer.writeln();
    }

    final prompt =
        'You are a reading companion for the book "${book.title}" by ${book.author}. '
        'The reader has read up to Chapter ${currentChapter + 1}. '
        'IMPORTANT: Do not spoil any content beyond Chapter ${currentChapter + 1}. '
        'Answer the following question using only the text provided:\n\n'
        'Question: $question\n\n'
        'Context:\n${contextBuffer.toString()}';

    return _aiService.askQuestion(
      bookId: book.id,
      question: prompt,
      chapterContext: contextBuffer.toString(),
    );
  }

  // ── Content Warnings ──────────────────────────────────────────────────────

  /// Analyze book text for sensitive content and return categorized warnings.
  Future<List<ContentWarningResult>> analyzeContentWarnings(
      BookModel book) async {
    if (book.chapters.isEmpty) return [];

    final contextBuffer = StringBuffer();
    for (final chapter in book.chapters) {
      final content = chapter.content;
      // Use first 1000 chars per chapter for analysis
      final truncated =
          content.length > 1000 ? content.substring(0, 1000) : content;
      contextBuffer.writeln('[Chapter ${chapter.index + 1}]');
      contextBuffer.writeln(truncated);
      contextBuffer.writeln();
    }

    final prompt =
        'Analyze the following text from "${book.title}" by ${book.author} '
        'for sensitive content. Identify any content warnings that readers '
        'might want to know about.\n\n'
        'For each warning, provide:\n'
        'CATEGORY: [e.g., Violence, Language, Sexual Content, Mental Health, '
        'Substance Use, Death/Grief, Discrimination, etc.]\n'
        'SEVERITY: [mild, moderate, or graphic]\n'
        'DESCRIPTION: [brief explanation]\n'
        '---\n\n'
        'If no sensitive content is found, respond with "No content warnings detected."\n\n'
        '${contextBuffer.toString()}';

    final response = await _aiService.askQuestion(
      bookId: book.id,
      question: prompt,
    );

    return _parseContentWarnings(response);
  }

  List<ContentWarningResult> _parseContentWarnings(String response) {
    if (response.toLowerCase().contains('no content warnings detected')) {
      return [];
    }

    final warnings = <ContentWarningResult>[];
    final blocks = response.split('---');

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      String category = '';
      String severity = 'mild';
      String description = '';

      for (final line in trimmed.split('\n')) {
        final lower = line.trim();
        if (lower.startsWith('CATEGORY:')) {
          category = lower.substring(9).trim();
        } else if (lower.startsWith('SEVERITY:')) {
          severity = lower.substring(9).trim().toLowerCase();
          if (!['mild', 'moderate', 'graphic'].contains(severity)) {
            severity = 'mild';
          }
        } else if (lower.startsWith('DESCRIPTION:')) {
          description = lower.substring(12).trim();
        }
      }

      if (category.isNotEmpty) {
        warnings.add(ContentWarningResult(
          category: category,
          severity: severity,
          description: description,
        ));
      }
    }

    return warnings;
  }

  // ── Discussion Questions ──────────────────────────────────────────────────

  /// Generate thought-provoking discussion questions for a specific chapter.
  Future<List<String>> generateDiscussionQuestions(
      BookModel book, int chapterIndex) async {
    if (chapterIndex < 0 || chapterIndex >= book.chapters.length) {
      return [];
    }

    final chapter = book.chapters[chapterIndex];
    final content = chapter.content;
    final truncated =
        content.length > 3000 ? content.substring(0, 3000) : content;

    final prompt =
        'Generate 5 thought-provoking discussion questions for a book club '
        'about Chapter ${chapterIndex + 1} ("${chapter.title}") of '
        '"${book.title}" by ${book.author}.\n\n'
        'The questions should:\n'
        '- Encourage deeper thinking about themes and character motivations\n'
        '- Be open-ended (no yes/no answers)\n'
        '- Reference specific events or passages when possible\n'
        '- Be suitable for group discussion\n\n'
        'Chapter text:\n$truncated\n\n'
        'Format: Number each question (1-5), one per line.';

    final response = await _aiService.askQuestion(
      bookId: book.id,
      question: prompt,
      chapterContext: truncated,
    );

    return _parseDiscussionQuestions(response);
  }

  List<String> _parseDiscussionQuestions(String response) {
    final questions = <String>[];
    final lines = response.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Remove leading number and punctuation (e.g., "1.", "1)", "1:")
      final cleaned =
          trimmed.replaceFirst(RegExp(r'^\d+[.):\-]\s*'), '').trim();
      if (cleaned.isNotEmpty && cleaned.length > 10) {
        questions.add(cleaned);
      }
    }

    return questions;
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────

class CharacterInfo {
  final String name;
  final String description;
  final List<String> relationships;
  final int firstAppearanceChapter;

  const CharacterInfo({
    required this.name,
    required this.description,
    required this.relationships,
    required this.firstAppearanceChapter,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'relationships': relationships,
        'firstAppearanceChapter': firstAppearanceChapter,
      };

  factory CharacterInfo.fromJson(Map<String, dynamic> json) => CharacterInfo(
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        relationships:
            (json['relationships'] as List?)?.cast<String>() ?? [],
        firstAppearanceChapter:
            json['firstAppearanceChapter'] as int? ?? 1,
      );
}

class ContentWarningResult {
  final String category;
  final String severity; // mild, moderate, graphic
  final String description;

  const ContentWarningResult({
    required this.category,
    required this.severity,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'severity': severity,
        'description': description,
      };

  factory ContentWarningResult.fromJson(Map<String, dynamic> json) =>
      ContentWarningResult(
        category: json['category'] as String,
        severity: json['severity'] as String? ?? 'mild',
        description: json['description'] as String? ?? '',
      );

  /// Icon suggestion based on severity level.
  String get severityLabel {
    switch (severity) {
      case 'graphic':
        return 'Graphic';
      case 'moderate':
        return 'Moderate';
      case 'mild':
      default:
        return 'Mild';
    }
  }
}
