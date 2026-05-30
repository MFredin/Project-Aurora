import 'dart:convert';
import 'dart:typed_data';

enum ReadingStatus {
  wantToRead,
  reading,
  read,
  dnf,
  rereading;

  String get label {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'Want to Read';
      case ReadingStatus.reading:
        return 'Reading';
      case ReadingStatus.read:
        return 'Read';
      case ReadingStatus.dnf:
        return 'DNF';
      case ReadingStatus.rereading:
        return 'Re-reading';
    }
  }

  String get icon {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'bookmark_border';
      case ReadingStatus.reading:
        return 'auto_stories';
      case ReadingStatus.read:
        return 'check_circle';
      case ReadingStatus.dnf:
        return 'cancel';
      case ReadingStatus.rereading:
        return 'replay';
    }
  }
}

enum BookFormatType {
  ebook,
  physical,
  audiobook,
  arc;

  String get label {
    switch (this) {
      case BookFormatType.ebook:
        return 'Ebook';
      case BookFormatType.physical:
        return 'Physical';
      case BookFormatType.audiobook:
        return 'Audiobook';
      case BookFormatType.arc:
        return 'ARC';
    }
  }
}

enum ReadingPace {
  slow,
  medium,
  fast;

  String get label {
    switch (this) {
      case ReadingPace.slow:
        return 'Slow';
      case ReadingPace.medium:
        return 'Medium';
      case ReadingPace.fast:
        return 'Fast';
    }
  }
}

class BookMood {
  static const adventurous = 'adventurous';
  static const dark = 'dark';
  static const emotional = 'emotional';
  static const hopeful = 'hopeful';
  static const funny = 'funny';
  static const tense = 'tense';
  static const inspiring = 'inspiring';
  static const reflective = 'reflective';
  static const romantic = 'romantic';
  static const mysterious = 'mysterious';
  static const lighthearted = 'lighthearted';
  static const melancholic = 'melancholic';

  static const all = [
    adventurous, dark, emotional, hopeful, funny, tense,
    inspiring, reflective, romantic, mysterious, lighthearted, melancholic,
  ];

  BookMood._();
}

class BookModel {
  final String id;
  final String title;
  final String author;
  final String? isbn;
  final Uint8List? coverImageData;
  final String format;
  final int fileSize;
  final DateTime dateAdded;
  final DateTime? lastOpened;
  final List<ChapterModel> chapters;
  final ReadingProgressModel progress;
  final List<HighlightModel> highlights;
  final List<BookmarkModel> bookmarks;
  final List<ReadingNoteModel> readingNotes;

  // Tier 1: Journal & metadata
  final ReadingStatus readingStatus;
  final double? rating; // 0-5 in 0.25 increments
  final List<String> moods;
  final ReadingPace? pace;
  final BookFormatType? bookFormatType;
  final String review;
  final bool reviewIsPrivate;
  final List<String> customTags;
  final DateTime? startDate;
  final DateTime? finishDate;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    this.coverImageData,
    required this.format,
    required this.fileSize,
    required this.dateAdded,
    this.lastOpened,
    required this.chapters,
    this.progress = const ReadingProgressModel(),
    this.highlights = const [],
    this.bookmarks = const [],
    this.readingNotes = const [],
    this.readingStatus = ReadingStatus.wantToRead,
    this.rating,
    this.moods = const [],
    this.pace,
    this.bookFormatType,
    this.review = '',
    this.reviewIsPrivate = false,
    this.customTags = const [],
    this.startDate,
    this.finishDate,
  });

  BookModel copyWith({
    String? title,
    String? author,
    DateTime? lastOpened,
    List<ChapterModel>? chapters,
    ReadingProgressModel? progress,
    List<HighlightModel>? highlights,
    List<BookmarkModel>? bookmarks,
    List<ReadingNoteModel>? readingNotes,
    ReadingStatus? readingStatus,
    double? Function()? rating,
    List<String>? moods,
    ReadingPace? Function()? pace,
    BookFormatType? Function()? bookFormatType,
    String? review,
    bool? reviewIsPrivate,
    List<String>? customTags,
    DateTime? Function()? startDate,
    DateTime? Function()? finishDate,
  }) {
    return BookModel(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn,
      coverImageData: coverImageData,
      format: format,
      fileSize: fileSize,
      dateAdded: dateAdded,
      lastOpened: lastOpened ?? this.lastOpened,
      chapters: chapters ?? this.chapters,
      progress: progress ?? this.progress,
      highlights: highlights ?? this.highlights,
      bookmarks: bookmarks ?? this.bookmarks,
      readingNotes: readingNotes ?? this.readingNotes,
      readingStatus: readingStatus ?? this.readingStatus,
      rating: rating != null ? rating() : this.rating,
      moods: moods ?? this.moods,
      pace: pace != null ? pace() : this.pace,
      bookFormatType:
          bookFormatType != null ? bookFormatType() : this.bookFormatType,
      review: review ?? this.review,
      reviewIsPrivate: reviewIsPrivate ?? this.reviewIsPrivate,
      customTags: customTags ?? this.customTags,
      startDate: startDate != null ? startDate() : this.startDate,
      finishDate: finishDate != null ? finishDate() : this.finishDate,
    );
  }

  double get progressPercent {
    if (chapters.isEmpty) return 0;
    return (progress.currentChapter + progress.scrollFraction) / chapters.length;
  }

  int get totalWords =>
      chapters.fold(0, (sum, ch) => sum + ch.wordCount);

  String get statusLabel => readingStatus.label;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'isbn': isbn,
        'coverImageData':
            coverImageData != null ? base64Encode(coverImageData!) : null,
        'format': format,
        'fileSize': fileSize,
        'dateAdded': dateAdded.toIso8601String(),
        'lastOpened': lastOpened?.toIso8601String(),
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'progress': progress.toJson(),
        'highlights': highlights.map((h) => h.toJson()).toList(),
        'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
        'readingNotes': readingNotes.map((n) => n.toJson()).toList(),
        'readingStatus': readingStatus.name,
        'rating': rating,
        'moods': moods,
        'pace': pace?.name,
        'bookFormatType': bookFormatType?.name,
        'review': review,
        'reviewIsPrivate': reviewIsPrivate,
        'customTags': customTags,
        'startDate': startDate?.toIso8601String(),
        'finishDate': finishDate?.toIso8601String(),
      };

  factory BookModel.fromJson(Map<String, dynamic> json) {
    // Backwards-compatible status inference
    ReadingStatus status;
    if (json['readingStatus'] != null) {
      status = ReadingStatus.values.firstWhere(
        (s) => s.name == json['readingStatus'],
        orElse: () => ReadingStatus.wantToRead,
      );
    } else {
      // Legacy: infer from progress
      final progress = json['progress'] != null
          ? ReadingProgressModel.fromJson(
              json['progress'] as Map<String, dynamic>)
          : const ReadingProgressModel();
      final chapters = (json['chapters'] as List?) ?? [];
      if (chapters.isNotEmpty) {
        final pct = (progress.currentChapter + progress.scrollFraction) /
            chapters.length;
        if (pct >= 1.0) {
          status = ReadingStatus.read;
        } else if (pct > 0) {
          status = ReadingStatus.reading;
        } else {
          status = ReadingStatus.wantToRead;
        }
      } else {
        status = ReadingStatus.wantToRead;
      }
    }

    return BookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      isbn: json['isbn'] as String?,
      coverImageData: json['coverImageData'] != null
          ? base64Decode(json['coverImageData'] as String)
          : null,
      format: json['format'] as String,
      fileSize: json['fileSize'] as int,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      lastOpened: json['lastOpened'] != null
          ? DateTime.parse(json['lastOpened'] as String)
          : null,
      chapters: (json['chapters'] as List)
          .map((c) => ChapterModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      progress: json['progress'] != null
          ? ReadingProgressModel.fromJson(
              json['progress'] as Map<String, dynamic>)
          : const ReadingProgressModel(),
      highlights: (json['highlights'] as List?)
              ?.map(
                  (h) => HighlightModel.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
      bookmarks: (json['bookmarks'] as List?)
              ?.map(
                  (b) => BookmarkModel.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      readingNotes: (json['readingNotes'] as List?)
              ?.map((n) =>
                  ReadingNoteModel.fromJson(n as Map<String, dynamic>))
              .toList() ??
          [],
      readingStatus: status,
      rating: (json['rating'] as num?)?.toDouble(),
      moods: (json['moods'] as List?)?.cast<String>() ?? [],
      pace: json['pace'] != null
          ? ReadingPace.values.firstWhere(
              (p) => p.name == json['pace'],
              orElse: () => ReadingPace.medium,
            )
          : null,
      bookFormatType: json['bookFormatType'] != null
          ? BookFormatType.values.firstWhere(
              (f) => f.name == json['bookFormatType'],
              orElse: () => BookFormatType.ebook,
            )
          : null,
      review: json['review'] as String? ?? '',
      reviewIsPrivate: json['reviewIsPrivate'] as bool? ?? false,
      customTags: (json['customTags'] as List?)?.cast<String>() ?? [],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      finishDate: json['finishDate'] != null
          ? DateTime.parse(json['finishDate'] as String)
          : null,
    );
  }
}

class ChapterModel {
  final String title;
  final String content;
  final int index;

  const ChapterModel({
    required this.title,
    required this.content,
    required this.index,
  });

  int get wordCount =>
      content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'index': index,
      };

  factory ChapterModel.fromJson(Map<String, dynamic> json) => ChapterModel(
        title: json['title'] as String,
        content: json['content'] as String,
        index: json['index'] as int,
      );
}

class ReadingProgressModel {
  final int currentChapter;
  final double scrollFraction;
  final int totalReadingSeconds;
  final DateTime? lastReadDate;

  const ReadingProgressModel({
    this.currentChapter = 0,
    this.scrollFraction = 0.0,
    this.totalReadingSeconds = 0,
    this.lastReadDate,
  });

  ReadingProgressModel copyWith({
    int? currentChapter,
    double? scrollFraction,
    int? totalReadingSeconds,
    DateTime? lastReadDate,
  }) {
    return ReadingProgressModel(
      currentChapter: currentChapter ?? this.currentChapter,
      scrollFraction: scrollFraction ?? this.scrollFraction,
      totalReadingSeconds: totalReadingSeconds ?? this.totalReadingSeconds,
      lastReadDate: lastReadDate ?? this.lastReadDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentChapter': currentChapter,
        'scrollFraction': scrollFraction,
        'totalReadingSeconds': totalReadingSeconds,
        'lastReadDate': lastReadDate?.toIso8601String(),
      };

  factory ReadingProgressModel.fromJson(Map<String, dynamic> json) =>
      ReadingProgressModel(
        currentChapter: json['currentChapter'] as int? ?? 0,
        scrollFraction: (json['scrollFraction'] as num?)?.toDouble() ?? 0.0,
        totalReadingSeconds: json['totalReadingSeconds'] as int? ?? 0,
        lastReadDate: json['lastReadDate'] != null
            ? DateTime.parse(json['lastReadDate'] as String)
            : null,
      );
}

class HighlightModel {
  final String id;
  final String bookId;
  final String highlightedText;
  final String note;
  final String colorName;
  final int chapterIndex;
  final DateTime dateCreated;

  const HighlightModel({
    required this.id,
    required this.bookId,
    required this.highlightedText,
    this.note = '',
    this.colorName = 'auroraTeal',
    required this.chapterIndex,
    required this.dateCreated,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'highlightedText': highlightedText,
        'note': note,
        'colorName': colorName,
        'chapterIndex': chapterIndex,
        'dateCreated': dateCreated.toIso8601String(),
      };

  factory HighlightModel.fromJson(Map<String, dynamic> json) =>
      HighlightModel(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        highlightedText: json['highlightedText'] as String,
        note: json['note'] as String? ?? '',
        colorName: json['colorName'] as String? ?? 'auroraTeal',
        chapterIndex: json['chapterIndex'] as int,
        dateCreated: DateTime.parse(json['dateCreated'] as String),
      );
}

class BookmarkModel {
  final String id;
  final String bookId;
  final String title;
  final int chapter;
  final String textSnippet;
  final DateTime dateCreated;

  const BookmarkModel({
    required this.id,
    required this.bookId,
    required this.title,
    required this.chapter,
    this.textSnippet = '',
    required this.dateCreated,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'title': title,
        'chapter': chapter,
        'textSnippet': textSnippet,
        'dateCreated': dateCreated.toIso8601String(),
      };

  factory BookmarkModel.fromJson(Map<String, dynamic> json) => BookmarkModel(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        title: json['title'] as String,
        chapter: json['chapter'] as int,
        textSnippet: json['textSnippet'] as String? ?? '',
        dateCreated: DateTime.parse(json['dateCreated'] as String),
      );
}

class ReadingNoteModel {
  final String id;
  final String bookId;
  final int chapterIndex;
  final double progressPercent;
  final String note;
  final DateTime dateCreated;

  const ReadingNoteModel({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.progressPercent,
    required this.note,
    required this.dateCreated,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'chapterIndex': chapterIndex,
        'progressPercent': progressPercent,
        'note': note,
        'dateCreated': dateCreated.toIso8601String(),
      };

  factory ReadingNoteModel.fromJson(Map<String, dynamic> json) =>
      ReadingNoteModel(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        chapterIndex: json['chapterIndex'] as int? ?? 0,
        progressPercent:
            (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
        note: json['note'] as String,
        dateCreated: DateTime.parse(json['dateCreated'] as String),
      );
}

class ReadingSessionModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final DateTime startTime;
  final int durationSeconds;
  final int pagesRead;

  const ReadingSessionModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.startTime,
    required this.durationSeconds,
    required this.pagesRead,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'bookTitle': bookTitle,
        'startTime': startTime.toIso8601String(),
        'durationSeconds': durationSeconds,
        'pagesRead': pagesRead,
      };

  factory ReadingSessionModel.fromJson(Map<String, dynamic> json) =>
      ReadingSessionModel(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        bookTitle: json['bookTitle'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        durationSeconds: json['durationSeconds'] as int,
        pagesRead: json['pagesRead'] as int,
      );
}

class ReadingGoalModel {
  final int year;
  final int targetBooks;
  final int booksRead;

  const ReadingGoalModel({
    required this.year,
    required this.targetBooks,
    this.booksRead = 0,
  });

  double get progress =>
      targetBooks > 0 ? (booksRead / targetBooks).clamp(0.0, 1.0) : 0.0;

  bool get isAhead {
    final now = DateTime.now();
    if (now.year != year) return booksRead >= targetBooks;
    final dayOfYear =
        now.difference(DateTime(year, 1, 1)).inDays + 1;
    final expected = (targetBooks * dayOfYear / 365).ceil();
    return booksRead >= expected;
  }

  int get expectedByNow {
    final now = DateTime.now();
    if (now.year != year) return targetBooks;
    final dayOfYear =
        now.difference(DateTime(year, 1, 1)).inDays + 1;
    return (targetBooks * dayOfYear / 365).ceil();
  }

  ReadingGoalModel copyWith({int? targetBooks, int? booksRead}) {
    return ReadingGoalModel(
      year: year,
      targetBooks: targetBooks ?? this.targetBooks,
      booksRead: booksRead ?? this.booksRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'year': year,
        'targetBooks': targetBooks,
        'booksRead': booksRead,
      };

  factory ReadingGoalModel.fromJson(Map<String, dynamic> json) =>
      ReadingGoalModel(
        year: json['year'] as int,
        targetBooks: json['targetBooks'] as int,
        booksRead: json['booksRead'] as int? ?? 0,
      );
}
