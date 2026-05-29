import 'dart:convert';
import 'dart:typed_data';

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
  });

  BookModel copyWith({
    String? title,
    String? author,
    DateTime? lastOpened,
    List<ChapterModel>? chapters,
    ReadingProgressModel? progress,
    List<HighlightModel>? highlights,
    List<BookmarkModel>? bookmarks,
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
    );
  }

  double get progressPercent {
    if (chapters.isEmpty) return 0;
    return (progress.currentChapter + progress.scrollFraction) / chapters.length;
  }

  int get totalWords =>
      chapters.fold(0, (sum, ch) => sum + ch.wordCount);

  String get statusLabel {
    if (progressPercent >= 1.0) return 'finished';
    if (progressPercent > 0) return 'reading';
    return 'wantToRead';
  }

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
      };

  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
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
      );
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
