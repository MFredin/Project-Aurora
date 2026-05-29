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

  int get wordCount => content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
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
}
