import 'package:drift/drift.dart';

// Generated code requires: dart run build_runner build
// part 'database.g.dart';

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

// AppDatabase requires codegen. Run: dart run build_runner build
// The alpha uses BookRepository (lib/core/data/book_repository.dart) instead.
//
// @DriftDatabase(tables: [...])
// class AppDatabase extends _$AppDatabase { ... }
