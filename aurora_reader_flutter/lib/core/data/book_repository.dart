import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import '../../services/parser/book_parser_service.dart';
import '../../services/logging/error_logger.dart';

const _uuid = Uuid();
const _booksKey = 'books';
const _sessionsKey = 'sessions';
const _goalsKey = 'reading_goals';
const _streakKey = 'reading_streak';

class BookRepository extends Notifier<List<BookModel>> {
  Box get _box => Hive.box('aurora_reader');

  @override
  List<BookModel> build() {
    final raw = _box.get(_booksKey);
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw as String);
      return decoded
          .map((j) => BookModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      ErrorLogger.instance.capture(e, stackTrace: stack, source: 'BookRepository.build');
      return [];
    }
  }

  void _persist() {
    _box.put(_booksKey, jsonEncode(state.map((b) => b.toJson()).toList()));
  }

  BookModel? getBook(String id) {
    for (final book in state) {
      if (book.id == id) return book;
    }
    return null;
  }

  String addParsedBook(ParsedBookResult result) {
    final bookId = _uuid.v4();
    final chapters = result.chapters
        .map((c) => ChapterModel(
              title: c.title,
              content: c.content,
              index: c.index,
            ))
        .toList();

    if (result.rawFileData != null) {
      _box.put('raw_$bookId', base64Encode(result.rawFileData!));
    }

    final book = BookModel(
      id: bookId,
      title: result.metadata.title,
      author: result.metadata.author,
      isbn: result.metadata.isbn,
      coverImageData: result.metadata.coverImageData,
      format: result.metadata.format.name,
      fileSize: result.metadata.fileSize,
      dateAdded: DateTime.now(),
      chapters: chapters,
      bookFormatType: BookFormatType.ebook,
    );

    state = [...state, book];
    _persist();
    return bookId;
  }

  /// Add a pre-built BookModel directly (used by import services).
  void addImportedBook(BookModel book) {
    state = [...state, book];
    _persist();
  }

  Uint8List? getRawFileData(String bookId) {
    final raw = _box.get('raw_$bookId');
    if (raw == null) return null;
    try {
      return base64Decode(raw as String);
    } catch (e) {
      ErrorLogger.instance.capture(e, source: 'BookRepository.getRawFileData');
      return null;
    }
  }

  void _updateBook(String bookId, BookModel Function(BookModel) updater) {
    state = [
      for (final book in state)
        if (book.id == bookId) updater(book) else book,
    ];
    _persist();
  }

  void updateProgress(String bookId, int chapter, double scrollFraction) {
    _updateBook(bookId, (book) {
      var newStatus = book.readingStatus;
      if (book.readingStatus == ReadingStatus.wantToRead &&
          (chapter > 0 || scrollFraction > 0)) {
        newStatus = ReadingStatus.reading;
      }
      return book.copyWith(
        lastOpened: DateTime.now(),
        readingStatus: newStatus,
        startDate: book.startDate == null && (chapter > 0 || scrollFraction > 0)
            ? () => DateTime.now()
            : null,
        progress: book.progress.copyWith(
          currentChapter: chapter,
          scrollFraction: scrollFraction,
          lastReadDate: DateTime.now(),
        ),
      );
    });
  }

  void addReadingTime(String bookId, int seconds) {
    if (seconds <= 0) return;
    _updateBook(bookId, (book) => book.copyWith(
      progress: book.progress.copyWith(
        totalReadingSeconds: book.progress.totalReadingSeconds + seconds,
      ),
    ));
  }

  void addHighlight(String bookId, HighlightModel highlight) {
    _updateBook(bookId, (book) => book.copyWith(
      highlights: [...book.highlights, highlight],
    ));
  }

  void addBookmark(String bookId, BookmarkModel bookmark) {
    _updateBook(bookId, (book) => book.copyWith(
      bookmarks: [...book.bookmarks, bookmark],
    ));
  }

  void removeBookmark(String bookId, String bookmarkId) {
    _updateBook(bookId, (book) => book.copyWith(
      bookmarks: book.bookmarks.where((b) => b.id != bookmarkId).toList(),
    ));
  }

  // --- Tier 1: Reading status & metadata ---

  void setReadingStatus(String bookId, ReadingStatus status) {
    _updateBook(bookId, (book) {
      DateTime? Function()? startDate;
      DateTime? Function()? finishDate;

      if (status == ReadingStatus.reading && book.startDate == null) {
        startDate = () => DateTime.now();
      }
      if (status == ReadingStatus.read && book.finishDate == null) {
        finishDate = () => DateTime.now();
      }
      if (status == ReadingStatus.wantToRead) {
        startDate = () => null;
        finishDate = () => null;
      }

      return book.copyWith(
        readingStatus: status,
        startDate: startDate,
        finishDate: finishDate,
      );
    });

    if (status == ReadingStatus.read) {
      _incrementGoalProgress();
    }
  }

  void setRating(String bookId, double? rating) {
    _updateBook(bookId, (book) => book.copyWith(
      rating: () => rating,
    ));
  }

  void setMoods(String bookId, List<String> moods) {
    _updateBook(bookId, (book) => book.copyWith(moods: moods));
  }

  void setPace(String bookId, ReadingPace? pace) {
    _updateBook(bookId, (book) => book.copyWith(pace: () => pace));
  }

  void setBookFormatType(String bookId, BookFormatType? formatType) {
    _updateBook(bookId, (book) => book.copyWith(
      bookFormatType: () => formatType,
    ));
  }

  void setReview(String bookId, String review, {bool? isPrivate}) {
    _updateBook(bookId, (book) => book.copyWith(
      review: review,
      reviewIsPrivate: isPrivate,
    ));
  }

  void setCustomTags(String bookId, List<String> tags) {
    _updateBook(bookId, (book) => book.copyWith(customTags: tags));
  }

  void addReadingNote(String bookId, ReadingNoteModel note) {
    _updateBook(bookId, (book) => book.copyWith(
      readingNotes: [...book.readingNotes, note],
    ));
  }

  void removeReadingNote(String bookId, String noteId) {
    _updateBook(bookId, (book) => book.copyWith(
      readingNotes: book.readingNotes.where((n) => n.id != noteId).toList(),
    ));
  }

  void setDates(String bookId, {DateTime? startDate, DateTime? finishDate}) {
    _updateBook(bookId, (book) => book.copyWith(
      startDate: startDate != null ? () => startDate : null,
      finishDate: finishDate != null ? () => finishDate : null,
    ));
  }

  // --- Quotes ---

  void addQuote(String bookId, SavedQuoteModel quote) {
    _updateBook(bookId, (book) => book.copyWith(
      savedQuotes: [...book.savedQuotes, quote],
    ));
  }

  void removeQuote(String bookId, String quoteId) {
    _updateBook(bookId, (book) => book.copyWith(
      savedQuotes: book.savedQuotes.where((q) => q.id != quoteId).toList(),
    ));
  }

  // --- Series ---

  void setSeries(String bookId, {String? seriesName, int? seriesPosition}) {
    _updateBook(bookId, (book) => book.copyWith(
      seriesName: () => seriesName,
      seriesPosition: () => seriesPosition,
    ));
  }

  // --- Re-read archival ---

  void archiveCurrentRead(String bookId) {
    _updateBook(bookId, (book) {
      final entry = ReadHistoryEntry(
        readNumber: book.readHistory.length + 1,
        startDate: book.startDate,
        finishDate: book.finishDate,
        rating: book.rating,
        review: book.review,
        moods: List.from(book.moods),
      );
      return book.copyWith(
        readHistory: [...book.readHistory, entry],
        readingStatus: ReadingStatus.rereading,
        startDate: () => DateTime.now(),
        finishDate: () => null,
        rating: () => null,
        review: '',
        moods: [],
        progress: const ReadingProgressModel(),
      );
    });
  }

  // --- Highlight management ---

  void removeHighlight(String bookId, String highlightId) {
    _updateBook(bookId, (book) => book.copyWith(
      highlights: book.highlights.where((h) => h.id != highlightId).toList(),
    ));
  }

  void updateHighlightNote(String bookId, String highlightId, String note) {
    _updateBook(bookId, (book) => book.copyWith(
      highlights: book.highlights.map((h) {
        if (h.id == highlightId) {
          return HighlightModel(
            id: h.id,
            bookId: h.bookId,
            highlightedText: h.highlightedText,
            note: note,
            colorName: h.colorName,
            chapterIndex: h.chapterIndex,
            dateCreated: h.dateCreated,
          );
        }
        return h;
      }).toList(),
    ));
  }

  // --- Achievement evaluation ---

  List<AchievementType> getUnlockedAchievements() {
    final unlocked = <AchievementType>[];
    final booksRead = state.where((b) => b.readingStatus == ReadingStatus.read).length;
    final streak = getCurrentStreak();
    final totalHighlights = state.fold<int>(0, (s, b) => s + b.highlights.length);
    final totalReviews = state.where((b) => b.review.isNotEmpty).length;
    final allMoods = <String>{};
    for (final b in state) {
      allMoods.addAll(b.moods);
    }

    if (booksRead >= 1) unlocked.add(AchievementType.firstBook);
    if (booksRead >= 10) unlocked.add(AchievementType.bookworm10);
    if (booksRead >= 25) unlocked.add(AchievementType.bibliophile25);
    if (booksRead >= 100) unlocked.add(AchievementType.centurion100);
    if (allMoods.length >= 5) unlocked.add(AchievementType.genreExplorer);
    if (streak >= 7) unlocked.add(AchievementType.streakWeek);
    if (streak >= 30) unlocked.add(AchievementType.streakMonth);
    if (streak >= 14) unlocked.add(AchievementType.consistent);
    if (streak >= 5) unlocked.add(AchievementType.earlyBird);
    if (totalReviews >= 5) unlocked.add(AchievementType.reviewer);
    if (totalHighlights >= 50) unlocked.add(AchievementType.highlighter);

    // Night owl + speed reader need session data — check sessions
    final sessions = Hive.box('aurora_reader').get(_sessionsKey);
    if (sessions != null) {
      try {
        final List<dynamic> decoded = jsonDecode(sessions as String);
        for (final raw in decoded) {
          final s = raw as Map<String, dynamic>;
          final dur = s['durationSeconds'] as int? ?? 0;
          if (dur >= 7200) {
            unlocked.add(AchievementType.nightOwl);
            break;
          }
        }
      } catch (_) {}
    }

    // Speed reader: finished a book with start and finish on same day
    for (final b in state) {
      if (b.readingStatus == ReadingStatus.read &&
          b.startDate != null &&
          b.finishDate != null) {
        final diff = b.finishDate!.difference(b.startDate!).inHours;
        if (diff <= 24) {
          unlocked.add(AchievementType.speedReader);
          break;
        }
      }
    }

    return unlocked.toSet().toList();
  }

  // --- TBR reorder ---

  void reorderBooks(int oldIndex, int newIndex) {
    final books = List<BookModel>.from(state);
    final item = books.removeAt(oldIndex);
    books.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    state = books;
    _persist();
  }

  void deleteBook(String id) {
    _box.delete('raw_$id');
    state = state.where((b) => b.id != id).toList();
    _persist();
  }

  // --- Reading Goals ---

  void _incrementGoalProgress() {
    final year = DateTime.now().year;
    final goal = getGoal(year);
    if (goal != null) {
      saveGoal(goal.copyWith(booksRead: goal.booksRead + 1));
    }
  }

  ReadingGoalModel? getGoal(int year) {
    final raw = _box.get('${_goalsKey}_$year');
    if (raw == null) return null;
    try {
      return ReadingGoalModel.fromJson(
          jsonDecode(raw as String) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  void saveGoal(ReadingGoalModel goal) {
    _box.put('${_goalsKey}_${goal.year}', jsonEncode(goal.toJson()));
  }

  // --- Reading Streak ---

  int getCurrentStreak() {
    final raw = _box.get(_streakKey);
    if (raw == null) return 0;
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final lastDate = DateTime.parse(data['lastDate'] as String);
      final streak = data['streak'] as int;
      final today = DateTime.now();
      final diff = DateTime(today.year, today.month, today.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;
      if (diff > 1) return 0;
      return streak;
    } catch (e) {
      return 0;
    }
  }

  void recordReadingDay() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final raw = _box.get(_streakKey);
    int streak = 1;

    if (raw != null) {
      try {
        final data = jsonDecode(raw as String) as Map<String, dynamic>;
        final lastDate = DateTime.parse(data['lastDate'] as String);
        final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final diff = todayDate.difference(lastDay).inDays;

        if (diff == 0) return;
        if (diff == 1) {
          streak = (data['streak'] as int) + 1;
        }
      } catch (_) {}
    }

    _box.put(_streakKey, jsonEncode({
      'lastDate': todayDate.toIso8601String(),
      'streak': streak,
    }));
  }
}

final bookRepositoryProvider =
    NotifierProvider<BookRepository, List<BookModel>>(BookRepository.new);

final bookByIdProvider = Provider.family<BookModel?, String>((ref, id) {
  final books = ref.watch(bookRepositoryProvider);
  for (final book in books) {
    if (book.id == id) return book;
  }
  return null;
});

final booksByStatusProvider =
    Provider.family<List<BookModel>, ReadingStatus>((ref, status) {
  final books = ref.watch(bookRepositoryProvider);
  return books.where((b) => b.readingStatus == status).toList();
});

class ReadingSessionStore extends Notifier<List<ReadingSessionModel>> {
  Box get _box => Hive.box('aurora_reader');

  @override
  List<ReadingSessionModel> build() {
    final raw = _box.get(_sessionsKey);
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw as String);
      return decoded
          .map((j) => ReadingSessionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      ErrorLogger.instance.capture(e, stackTrace: stack, source: 'ReadingSessionStore.build');
      return [];
    }
  }

  void _persist() {
    _box.put(
        _sessionsKey, jsonEncode(state.map((s) => s.toJson()).toList()));
  }

  void addSession(ReadingSessionModel session) {
    state = [session, ...state];
    _persist();
  }
}

final readingSessionsProvider =
    NotifierProvider<ReadingSessionStore, List<ReadingSessionModel>>(
        ReadingSessionStore.new);
