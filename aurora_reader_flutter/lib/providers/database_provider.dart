import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';

/// Singleton database instance shared across the app.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Stream of all books in the library.
final allBooksProvider = StreamProvider<List<Book>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllBooks();
});

/// Single book by ID.
final bookByIdProvider =
    FutureProvider.family<Book?, String>((ref, bookId) async {
  final db = ref.watch(databaseProvider);
  return db.getBookById(bookId);
});

/// Reading progress for a specific book.
final bookProgressProvider =
    FutureProvider.family<ReadingProgress?, String>((ref, bookId) async {
  final db = ref.watch(databaseProvider);
  return db.getProgressForBook(bookId);
});

/// Chapters for a specific book.
final bookChaptersProvider =
    FutureProvider.family<List<BookChapter>, String>((ref, bookId) async {
  final db = ref.watch(databaseProvider);
  return db.getChaptersForBook(bookId);
});

/// Bookmarks for a specific book (stream).
final bookmarksProvider =
    StreamProvider.family<List<Bookmark>, String>((ref, bookId) {
  final db = ref.watch(databaseProvider);
  return db.watchBookmarksForBook(bookId);
});

/// Highlights for a specific book (stream).
final highlightsProvider =
    StreamProvider.family<List<Highlight>, String>((ref, bookId) {
  final db = ref.watch(databaseProvider);
  return db.watchHighlightsForBook(bookId);
});

/// All reading sessions (stream).
final allSessionsProvider = StreamProvider<List<ReadingSession>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSessions();
});

/// All vocabulary entries (stream).
final allVocabularyProvider = StreamProvider<List<VocabularyEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllVocabulary();
});
