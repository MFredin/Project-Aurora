import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import '../../services/parser/book_parser_service.dart';

const _uuid = Uuid();

class BookRepository extends StateNotifier<List<BookModel>> {
  BookRepository() : super([]);

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
  }

  void addReadingTime(String bookId, int seconds) {
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
  }

  void addHighlight(String bookId, HighlightModel highlight) {
    state = [
      for (final book in state)
        if (book.id == bookId)
          book.copyWith(highlights: [...book.highlights, highlight])
        else
          book,
    ];
  }

  void addBookmark(String bookId, BookmarkModel bookmark) {
    state = [
      for (final book in state)
        if (book.id == bookId)
          book.copyWith(bookmarks: [...book.bookmarks, bookmark])
        else
          book,
    ];
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
  }

  void deleteBook(String id) {
    state = state.where((b) => b.id != id).toList();
  }
}

final bookRepositoryProvider =
    StateNotifierProvider<BookRepository, List<BookModel>>((ref) {
  return BookRepository();
});

final bookByIdProvider = Provider.family<BookModel?, String>((ref, id) {
  final books = ref.watch(bookRepositoryProvider);
  for (final book in books) {
    if (book.id == id) return book;
  }
  return null;
});

class ReadingSessionStore extends StateNotifier<List<ReadingSessionModel>> {
  ReadingSessionStore() : super([]);

  void addSession(ReadingSessionModel session) {
    state = [session, ...state];
  }
}

final readingSessionsProvider =
    StateNotifierProvider<ReadingSessionStore, List<ReadingSessionModel>>(
        (ref) {
  return ReadingSessionStore();
});
