import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import '../../services/parser/book_parser_service.dart';

const _uuid = Uuid();
const _booksKey = 'books';
const _sessionsKey = 'sessions';

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
    } catch (_) {
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
    );

    state = [...state, book];
    _persist();
    return bookId;
  }

  void updateProgress(String bookId, int chapter, double scrollFraction) {
    state = [
      for (final book in state)
        if (book.id == bookId)
          book.copyWith(
            lastOpened: DateTime.now(),
            progress: book.progress.copyWith(
              currentChapter: chapter,
              scrollFraction: scrollFraction,
              lastReadDate: DateTime.now(),
            ),
          )
        else
          book,
    ];
    _persist();
  }

  void addReadingTime(String bookId, int seconds) {
    if (seconds <= 0) return;
    state = [
      for (final book in state)
        if (book.id == bookId)
          book.copyWith(
            progress: book.progress.copyWith(
              totalReadingSeconds:
                  book.progress.totalReadingSeconds + seconds,
            ),
          )
        else
          book,
    ];
    _persist();
  }

  void addHighlight(String bookId, HighlightModel highlight) {
    state = [
      for (final book in state)
        if (book.id == bookId)
          book.copyWith(highlights: [...book.highlights, highlight])
        else
          book,
    ];
    _persist();
  }

  void addBookmark(String bookId, BookmarkModel bookmark) {
    state = [
      for (final book in state)
        if (book.id == bookId)
          book.copyWith(bookmarks: [...book.bookmarks, bookmark])
        else
          book,
    ];
    _persist();
  }

  void removeBookmark(String bookId, String bookmarkId) {
    state = [
      for (final book in state)
        if (book.id == bookId)
          book.copyWith(
            bookmarks:
                book.bookmarks.where((b) => b.id != bookmarkId).toList(),
          )
        else
          book,
    ];
    _persist();
  }

  void deleteBook(String id) {
    state = state.where((b) => b.id != id).toList();
    _persist();
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
    } catch (_) {
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
