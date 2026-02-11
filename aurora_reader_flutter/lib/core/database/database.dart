import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ─── TABLE DEFINITIONS (Port of all 13 SwiftData @Model classes) ────────────

/// Books in the user's library
class Books extends Table {
  TextColumn get id => text().clientDefault(() => '')();
  TextColumn get title => text()();
  TextColumn get author => text()();
  TextColumn get isbn => text().nullable()();
  BlobColumn get coverImageData => blob().nullable()();
  TextColumn get fileUrl => text()();
  TextColumn get format => text()(); // epub, pdf, txt, mobi, etc.
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastOpened => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Reading progress per book
class ReadingProgresses extends Table {
  TextColumn get id => text().clientDefault(() => '')();
  TextColumn get bookId => text().references(Books, #id)();
  IntColumn get currentChapter => integer().withDefault(const Constant(0))();
  IntColumn get currentPage => integer().withDefault(const Constant(0))();
  IntColumn get totalPages => integer().withDefault(const Constant(1))();
  RealColumn get progressPercentage => real().withDefault(const Constant(0.0))();
  RealColumn get scrollOffset => real().withDefault(const Constant(0.0))();
  IntColumn get totalReadingSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReadDate => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Book chapters (parsed content)
class BookChapters extends Table {
  TextColumn get id => text().clientDefault(() => '')();
  TextColumn get bookId => text().references(Books, #id)();
  TextColumn get title => text()();
  TextColumn get content => text()();
  IntColumn get chapterIndex => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// User bookmarks
class Bookmarks extends Table {
  TextColumn get id => text().clientDefault(() => '')();
  TextColumn get bookId => text().references(Books, #id)();
  TextColumn get title => text()();
  IntColumn get chapter => integer()();
  IntColumn get page => integer()();
  TextColumn get textSnippet => text().withDefault(const Constant(''))();
  TextColumn get color => text().withDefault(const Constant('blue'))();
  DateTimeColumn get dateCreated => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Text highlights and annotations
class Highlights extends Table {
  TextColumn get id => text().clientDefault(() => '')();
  TextColumn get bookId => text().references(Books, #id)();
  TextColumn get highlightedText => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get colorName => text().withDefault(const Constant('auroraTeal'))();
  IntColumn get chapterIndex => integer()();
  TextColumn get chapterTitle => text().withDefault(const Constant(''))();
  IntColumn get rangeStart => integer()();
  IntColumn get rangeLength => integer()();
  DateTimeColumn get dateCreated => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dateModified => dateTime().withDefault(currentDateAndTime)();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON array

  @override
  Set<Column> get primaryKey => {id};
}

/// Reading sessions for habit tracking
class ReadingSessions extends Table {
  TextColumn get id => text().clientDefault(() => '')();
  TextColumn get bookId => text().nullable().references(Books, #id)();
  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get pagesRead => integer().withDefault(const Constant(0))();
  IntColumn get chaptersRead => integer().withDefault(const Constant(0))();
  IntColumn get wordsRead => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Reading streak tracking
class ReadingStreaks extends Table {
  TextColumn get id => text().clientDefault(() => '')();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReadDate => dateTime().nullable()();
  IntColumn get totalDaysRead => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Achievement / badges
class Achievements extends Table {
  TextColumn get id => text().clientDefault(() => '')();
  TextColumn get achievementType => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get iconName => text()();
  DateTimeColumn get dateEarned => dateTime().nullable()();
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();
  IntColumn get progressCurrent => integer().withDefault(const Constant(0))();
  IntColumn get progressTarget => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Friend profiles for social comparison
class FriendProfiles extends Table {
  TextColumn get id => text().clientDefault(() => '')();
  TextColumn get username => text()();
  TextColumn get displayName => text()();
  TextColumn get avatarUrl => text().nullable()();
  IntColumn get booksRead => integer().withDefault(const Constant(0))();
  IntColumn get totalMinutes => integer().withDefault(const Constant(0))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get joinedDate => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Vocabulary words saved from reading
class VocabularyEntries extends Table {
  TextColumn get id => text().clientDefault(() => '')();
  TextColumn get bookId => text().nullable().references(Books, #id)();
  TextColumn get word => text()();
  TextColumn get definition => text().withDefault(const Constant(''))();
  TextColumn get context => text().withDefault(const Constant(''))();
  TextColumn get bookTitle => text().withDefault(const Constant(''))();
  TextColumn get chapterTitle => text().withDefault(const Constant(''))();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isMastered => boolean().withDefault(const Constant(false))();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReviewDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Knowledge graph nodes
class KnowledgeNodes extends Table {
  TextColumn get id => text().clientDefault(() => '')();
  TextColumn get concept => text()();
  TextColumn get definition => text()();
  TextColumn get relatedConcepts => text().withDefault(const Constant('[]'))(); // JSON
  TextColumn get sourceBookTitles => text().withDefault(const Constant('[]'))(); // JSON
  DateTimeColumn get dateCreated => dateTime().withDefault(currentDateAndTime)();
  RealColumn get importance => real().withDefault(const Constant(0.5))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Book clubs
class BookClubs extends Table {
  TextColumn get id => text().clientDefault(() => '')();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get bookTitle => text()();
  TextColumn get bookAuthor => text()();
  BlobColumn get coverImageData => blob().nullable()();
  IntColumn get memberCount => integer().withDefault(const Constant(0))();
  IntColumn get discussionCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdDate => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isJoined => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// User reading preferences
class UserPreferencesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get fontSize => real().withDefault(const Constant(18.0))();
  TextColumn get fontFamily => text().withDefault(const Constant('Georgia'))();
  RealColumn get lineSpacing => real().withDefault(const Constant(1.6))();
  RealColumn get marginSize => real().withDefault(const Constant(16.0))();
  TextColumn get theme => text().withDefault(const Constant('dark'))();
  RealColumn get brightnessOverride => real().withDefault(const Constant(-1.0))();
  BoolColumn get isScrollMode => boolean().withDefault(const Constant(true))();
  BoolColumn get keepScreenAwake => boolean().withDefault(const Constant(true))();
}

// ─── DATABASE ───────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Books,
  ReadingProgresses,
  BookChapters,
  Bookmarks,
  Highlights,
  ReadingSessions,
  ReadingStreaks,
  Achievements,
  FriendProfiles,
  VocabularyEntries,
  KnowledgeNodes,
  BookClubs,
  UserPreferencesTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ─── Book Queries ─────────────────────────────────────

  Future<List<Book>> getAllBooks() => select(books).get();
  Stream<List<Book>> watchAllBooks() => select(books).watch();
  Future<Book?> getBookById(String id) =>
      (select(books)..where((b) => b.id.equals(id))).getSingleOrNull();
  Future<int> insertBook(BooksCompanion book) => into(books).insert(book);
  Future<bool> updateBook(Book book) => update(books).replace(book);
  Future<int> deleteBook(String id) =>
      (delete(books)..where((b) => b.id.equals(id))).go();

  // ─── Progress Queries ─────────────────────────────────

  Future<ReadingProgress?> getProgressForBook(String bookId) =>
      (select(readingProgresses)..where((p) => p.bookId.equals(bookId)))
          .getSingleOrNull();
  Stream<ReadingProgress?> watchProgressForBook(String bookId) =>
      (select(readingProgresses)..where((p) => p.bookId.equals(bookId)))
          .watchSingleOrNull();

  // ─── Chapter Queries ──────────────────────────────────

  Future<List<BookChapter>> getChaptersForBook(String bookId) =>
      (select(bookChapters)
            ..where((c) => c.bookId.equals(bookId))
            ..orderBy([(c) => OrderingTerm.asc(c.chapterIndex)]))
          .get();

  // ─── Bookmark Queries ─────────────────────────────────

  Stream<List<Bookmark>> watchBookmarksForBook(String bookId) =>
      (select(bookmarks)..where((b) => b.bookId.equals(bookId))).watch();

  // ─── Highlight Queries ────────────────────────────────

  Stream<List<Highlight>> watchHighlightsForBook(String bookId) =>
      (select(highlights)..where((h) => h.bookId.equals(bookId))).watch();
  Stream<List<Highlight>> watchAllHighlights() => select(highlights).watch();

  // ─── Session Queries ──────────────────────────────────

  Stream<List<ReadingSession>> watchAllSessions() =>
      select(readingSessions).watch();

  // ─── Vocabulary Queries ───────────────────────────────

  Stream<List<VocabularyEntry>> watchAllVocabulary() =>
      select(vocabularyEntries).watch();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'aurora_reader.db'));
    return NativeDatabase.createInBackground(file);
  });
}
