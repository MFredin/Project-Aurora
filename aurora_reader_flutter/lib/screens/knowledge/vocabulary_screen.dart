import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../services/ai/vocabulary_service.dart';

class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  String? _filterBookTitle;
  bool _showFlashcards = false;

  @override
  Widget build(BuildContext context) {
    final allWords = ref.watch(vocabularyRepositoryProvider);
    final stats = ref.watch(vocabularyStatsProvider);
    final repo = ref.read(vocabularyRepositoryProvider.notifier);
    final bookTitles = repo.bookTitles;

    // Apply book filter
    final words = _filterBookTitle != null
        ? allWords
            .where((w) => w.bookTitle == _filterBookTitle)
            .toList()
        : allWords;

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Vocabulary Builder',
              style: TextStyle(color: AuroraColors.textPrimary)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AuroraColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            if (words.where((w) => !w.mastered).isNotEmpty)
              IconButton(
                icon: Icon(
                  _showFlashcards
                      ? Icons.list_rounded
                      : Icons.style_rounded,
                  color: AuroraColors.auroraTeal,
                ),
                tooltip:
                    _showFlashcards ? 'Show list' : 'Flashcard review',
                onPressed: () =>
                    setState(() => _showFlashcards = !_showFlashcards),
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.contentMaxWidth(context)),
            child: Column(
              children: [
                // Stats bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      _StatChip(
                        label: 'Total',
                        value: '${stats.total}',
                        color: AuroraColors.auroraTeal,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Mastered',
                        value: '${stats.mastered}',
                        color: AuroraColors.auroraGreen,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'To Review',
                        value: '${stats.toReview}',
                        color: AuroraColors.manuscriptGold,
                      ),
                    ],
                  ),
                ),

                // Book filter chips
                if (bookTitles.length > 1)
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        AuroraFilterChip(
                          label: 'All Books',
                          isSelected: _filterBookTitle == null,
                          onTap: () =>
                              setState(() => _filterBookTitle = null),
                        ),
                        const SizedBox(width: 8),
                        ...bookTitles.map((title) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AuroraFilterChip(
                                label: title,
                                isSelected: _filterBookTitle == title,
                                onTap: () => setState(
                                    () => _filterBookTitle = title),
                              ),
                            )),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Content
                Expanded(
                  child: words.isEmpty
                      ? _buildEmptyState()
                      : _showFlashcards
                          ? _FlashcardView(
                              words: words
                                  .where((w) => !w.mastered)
                                  .toList(),
                            )
                          : _buildWordList(words),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.translate_rounded,
              color: AuroraColors.textTertiary.withOpacity(0.4), size: 64),
          const SizedBox(height: 16),
          const Text(
            'No vocabulary words yet',
            style: TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Look up words while reading to build your vocabulary list.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuroraColors.textTertiary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList(List<VocabularyWord> words) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final word = words[index];
        return _WordCard(word: word);
      },
    );
  }
}

// ── Stat Chip ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AuroraCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AuroraColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Word Card ───────────────────────────────────────────────────────────────

class _WordCard extends ConsumerWidget {
  final VocabularyWord word;

  const _WordCard({required this.word});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(word.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AuroraColors.auroraWarm.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded,
            color: AuroraColors.auroraWarm),
      ),
      onDismissed: (_) {
        ref.read(vocabularyRepositoryProvider.notifier).removeWord(word.id);
      },
      child: AuroraCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    word.word,
                    style: const TextStyle(
                      color: AuroraColors.auroraTeal,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (word.mastered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AuroraColors.auroraGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Mastered',
                      style: TextStyle(
                        color: AuroraColors.auroraGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AuroraColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    word.bookTitle,
                    style: const TextStyle(
                      color: AuroraColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              word.definition,
              style: const TextStyle(
                color: AuroraColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (word.context != null && word.context!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AuroraColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border(
                    left: BorderSide(
                      color: AuroraColors.manuscriptGold.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '"${word.context}"',
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Reviewed ${word.reviewCount}x',
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ref
                        .read(vocabularyRepositoryProvider.notifier)
                        .toggleMastered(word.id);
                  },
                  child: Text(
                    word.mastered ? 'Unmark mastered' : 'Mark mastered',
                    style: const TextStyle(
                      color: AuroraColors.auroraGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Flashcard View ──────────────────────────────────────────────────────────

class _FlashcardView extends ConsumerStatefulWidget {
  final List<VocabularyWord> words;

  const _FlashcardView({required this.words});

  @override
  ConsumerState<_FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends ConsumerState<_FlashcardView> {
  int _currentIndex = 0;
  bool _showBack = false;

  List<VocabularyWord> get _deck => widget.words;

  VocabularyWord? get _currentWord =>
      _deck.isNotEmpty && _currentIndex < _deck.length
          ? _deck[_currentIndex]
          : null;

  void _nextCard() {
    setState(() {
      _showBack = false;
      if (_currentIndex < _deck.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AuroraColors.auroraGreen, size: 48),
            const SizedBox(height: 12),
            const Text(
              'All words mastered!',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final word = _currentWord!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Progress
          Text(
            '${_currentIndex + 1} / ${_deck.length}',
            style: const TextStyle(
              color: AuroraColors.textTertiary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          // Flashcard
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showBack = !_showBack),
              child: AuroraCard(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showBack
                        ? _buildBack(word)
                        : _buildFront(word),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showBack ? 'Tap to see word' : 'Tap to reveal definition',
            style: const TextStyle(
              color: AuroraColors.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          if (_showBack)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AuroraButton(
                  label: 'Review Again',
                  icon: Icons.replay_rounded,
                  compact: true,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A4A3A), Color(0xFF4A3A2A)],
                  ),
                  onPressed: () {
                    ref
                        .read(vocabularyRepositoryProvider.notifier)
                        .markReviewed(word.id, gotIt: false);
                    _nextCard();
                  },
                ),
                const SizedBox(width: 12),
                AuroraButton(
                  label: 'Got It',
                  icon: Icons.check_rounded,
                  compact: true,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A9E8F), Color(0xFF3D7A6D)],
                  ),
                  onPressed: () {
                    ref
                        .read(vocabularyRepositoryProvider.notifier)
                        .markReviewed(word.id, gotIt: true);
                    _nextCard();
                  },
                ),
              ],
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFront(VocabularyWord word) {
    return Column(
      key: const ValueKey('front'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.translate_rounded,
            color: AuroraColors.auroraTeal, size: 32),
        const SizedBox(height: 16),
        Text(
          word.word,
          style: const TextStyle(
            color: AuroraColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (word.bookTitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'from ${word.bookTitle}',
            style: const TextStyle(
              color: AuroraColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBack(VocabularyWord word) {
    return Column(
      key: const ValueKey('back'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          word.word,
          style: const TextStyle(
            color: AuroraColors.auroraTeal,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          word.definition,
          style: const TextStyle(
            color: AuroraColors.textPrimary,
            fontSize: 17,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (word.context != null && word.context!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AuroraColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: AuroraColors.manuscriptGold.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
            child: Text(
              '"${word.context}"',
              style: const TextStyle(
                color: AuroraColors.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
