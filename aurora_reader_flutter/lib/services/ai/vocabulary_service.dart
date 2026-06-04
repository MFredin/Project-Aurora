import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
const _vocabKey = 'vocabulary';

// ── Data Model ────────────────────────────────────────────────────────────────

class VocabularyWord {
  final String id;
  final String word;
  final String definition;
  final String? context; // sentence where it was looked up
  final String bookId;
  final String bookTitle;
  final DateTime dateAdded;
  final int reviewCount;
  final DateTime? lastReviewed;
  final bool mastered;

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.definition,
    this.context,
    required this.bookId,
    required this.bookTitle,
    required this.dateAdded,
    this.reviewCount = 0,
    this.lastReviewed,
    this.mastered = false,
  });

  VocabularyWord copyWith({
    String? word,
    String? definition,
    String? Function()? context,
    int? reviewCount,
    DateTime? Function()? lastReviewed,
    bool? mastered,
  }) {
    return VocabularyWord(
      id: id,
      word: word ?? this.word,
      definition: definition ?? this.definition,
      context: context != null ? context() : this.context,
      bookId: bookId,
      bookTitle: bookTitle,
      dateAdded: dateAdded,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewed:
          lastReviewed != null ? lastReviewed() : this.lastReviewed,
      mastered: mastered ?? this.mastered,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'definition': definition,
        'context': context,
        'bookId': bookId,
        'bookTitle': bookTitle,
        'dateAdded': dateAdded.toIso8601String(),
        'reviewCount': reviewCount,
        'lastReviewed': lastReviewed?.toIso8601String(),
        'mastered': mastered,
      };

  factory VocabularyWord.fromJson(Map<String, dynamic> json) =>
      VocabularyWord(
        id: json['id'] as String,
        word: json['word'] as String,
        definition: json['definition'] as String? ?? '',
        context: json['context'] as String?,
        bookId: json['bookId'] as String? ?? '',
        bookTitle: json['bookTitle'] as String? ?? '',
        dateAdded: json['dateAdded'] != null
            ? DateTime.parse(json['dateAdded'] as String)
            : DateTime.now(),
        reviewCount: json['reviewCount'] as int? ?? 0,
        lastReviewed: json['lastReviewed'] != null
            ? DateTime.parse(json['lastReviewed'] as String)
            : null,
        mastered: json['mastered'] as bool? ?? false,
      );
}

// ── Repository (Riverpod Notifier) ──────────────────────────────────────────

class VocabularyRepository extends Notifier<List<VocabularyWord>> {
  Box get _box => Hive.box('aurora_reader');

  @override
  List<VocabularyWord> build() {
    final raw = _box.get(_vocabKey);
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw as String);
      return decoded
          .map((j) => VocabularyWord.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _persist() {
    _box.put(
        _vocabKey, jsonEncode(state.map((w) => w.toJson()).toList()));
  }

  /// Add a new word to the vocabulary list.
  void addWord({
    required String word,
    required String definition,
    String? context,
    required String bookId,
    required String bookTitle,
  }) {
    // Prevent duplicates of the same word from the same book
    final exists = state.any(
        (w) => w.word.toLowerCase() == word.toLowerCase() && w.bookId == bookId);
    if (exists) return;

    final entry = VocabularyWord(
      id: _uuid.v4(),
      word: word,
      definition: definition,
      context: context,
      bookId: bookId,
      bookTitle: bookTitle,
      dateAdded: DateTime.now(),
    );
    state = [entry, ...state];
    _persist();
  }

  /// Mark a word as reviewed (increment count, update date).
  void markReviewed(String wordId, {required bool gotIt}) {
    state = [
      for (final w in state)
        if (w.id == wordId)
          w.copyWith(
            reviewCount: w.reviewCount + 1,
            lastReviewed: () => DateTime.now(),
            mastered: gotIt && w.reviewCount >= 2 ? true : w.mastered,
          )
        else
          w,
    ];
    _persist();
  }

  /// Toggle mastered status.
  void toggleMastered(String wordId) {
    state = [
      for (final w in state)
        if (w.id == wordId) w.copyWith(mastered: !w.mastered) else w,
    ];
    _persist();
  }

  /// Remove a word.
  void removeWord(String wordId) {
    state = state.where((w) => w.id != wordId).toList();
    _persist();
  }

  /// Get words filtered by book.
  List<VocabularyWord> wordsForBook(String bookId) {
    return state.where((w) => w.bookId == bookId).toList();
  }

  /// Get words that still need review (not mastered).
  List<VocabularyWord> get wordsToReview =>
      state.where((w) => !w.mastered).toList();

  /// Stats.
  int get totalWords => state.length;
  int get masteredCount => state.where((w) => w.mastered).length;
  int get toReviewCount => state.where((w) => !w.mastered).length;

  /// Distinct book titles for filtering.
  List<String> get bookTitles =>
      state.map((w) => w.bookTitle).toSet().toList()..sort();
}

// ── Providers ───────────────────────────────────────────────────────────────

final vocabularyRepositoryProvider =
    NotifierProvider<VocabularyRepository, List<VocabularyWord>>(
        VocabularyRepository.new);

final vocabularyByBookProvider =
    Provider.family<List<VocabularyWord>, String>((ref, bookId) {
  final words = ref.watch(vocabularyRepositoryProvider);
  return words.where((w) => w.bookId == bookId).toList();
});

final vocabularyStatsProvider = Provider<({int total, int mastered, int toReview})>((ref) {
  final words = ref.watch(vocabularyRepositoryProvider);
  return (
    total: words.length,
    mastered: words.where((w) => w.mastered).length,
    toReview: words.where((w) => !w.mastered).length,
  );
});
