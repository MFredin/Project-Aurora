import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/book_repository.dart';
import '../../core/data/models.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../services/ai/vocabulary_service.dart';

class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(bookRepositoryProvider);
    final vocabulary = ref.watch(vocabularyRepositoryProvider);

    // Aggregate mood distribution from real books
    final moodCounts = <String, int>{};
    for (final book in books) {
      for (final mood in book.moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }
    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Aggregate custom tags from real books
    final tagCounts = <String, int>{};
    for (final book in books) {
      for (final tag in book.customTags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Collect all highlights across books, newest first
    final allHighlights = <({BookModel book, HighlightModel highlight})>[];
    for (final book in books) {
      for (final h in book.highlights) {
        allHighlights.add((book: book, highlight: h));
      }
    }
    allHighlights.sort(
        (a, b) => b.highlight.dateCreated.compareTo(a.highlight.dateCreated));

    if (books.isEmpty) {
      return AuroraBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(child: _buildEmptyState()),
        ),
      );
    }

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: ResponsiveHelper.contentMaxWidth(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Knowledge',
                      style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AuroraColors.auroraTeal,
                    labelColor: AuroraColors.auroraTeal,
                    unselectedLabelColor: AuroraColors.textTertiary,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(text: 'Insights'),
                      Tab(text: 'Vocabulary'),
                      Tab(text: 'Highlights'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInsightsTab(sortedMoods, sortedTags, books),
                        _buildVocabularyTab(vocabulary),
                        _buildHighlightsTab(allHighlights),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AuroraColors.auroraTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hub_outlined,
                  color: AuroraColors.auroraTeal, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your knowledge archive is empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'As you read and highlight, your personal knowledge archive grows here — moods, vocabulary, and your best passages.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuroraColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            AuroraButton(
              label: 'Import Books',
              icon: Icons.add_rounded,
              onPressed: () => context.go('/library'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab(
    List<MapEntry<String, int>> moods,
    List<MapEntry<String, int>> tags,
    List<BookModel> books,
  ) {
    final hasMoods = moods.isNotEmpty;
    final hasTags = tags.isNotEmpty;
    final totalTagged = books.where((b) => b.moods.isNotEmpty).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Reading moods card
        AuroraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mood_rounded,
                      color: AuroraColors.auroraTeal, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Reading Moods',
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$totalTagged books tagged',
                    style: const TextStyle(
                      color: AuroraColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!hasMoods)
                const Text(
                  'Open a book\'s detail page and add mood tags to see your reading personality here.',
                  style: TextStyle(
                      color: AuroraColors.textSecondary,
                      fontSize: 13,
                      height: 1.4),
                )
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: moods.map((e) {
                    final color = _moodColor(e.key);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(e.key,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Text('${e.value}',
                              style: TextStyle(
                                  color: color.withOpacity(0.7), fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ...moods.take(5).map((e) {
                  final color = _moodColor(e.key);
                  final max = moods.first.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(e.key,
                              style: const TextStyle(
                                  color: AuroraColors.textSecondary,
                                  fontSize: 12)),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: e.value / max,
                              minHeight: 6,
                              backgroundColor: AuroraColors.surface,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${e.value}',
                            style: const TextStyle(
                                color: AuroraColors.textTertiary, fontSize: 11)),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Custom tags
        if (hasTags) ...[
          AuroraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.label_outline_rounded,
                        color: AuroraColors.manuscriptGold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Your Tags',
                      style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.take(20).map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AuroraColors.manuscriptGold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                AuroraColors.manuscriptGold.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.key,
                              style: const TextStyle(
                                  color: AuroraColors.manuscriptGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 4),
                          Text('${e.value}',
                              style: TextStyle(
                                  color: AuroraColors.manuscriptGold
                                      .withOpacity(0.6),
                                  fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Reading Intelligence — coming soon
        AuroraCard(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AuroraColors.auroraTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: AuroraColors.auroraTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Icon(Icons.hub_rounded,
                  color: AuroraColors.auroraTeal, size: 36),
              const SizedBox(height: 8),
              const Text(
                'Reading Intelligence',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'AI-powered theme extraction, cross-book concept linking, and a visual knowledge graph are coming in a future update.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVocabularyTab(List<VocabularyWord> words) {
    if (words.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.spellcheck_rounded,
                  color: AuroraColors.auroraTeal, size: 48),
              const SizedBox(height: 16),
              const Text(
                'No vocabulary yet',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Words you look up while reading will appear here for review and mastery.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              AuroraButton(
                label: 'Review Vocabulary',
                icon: Icons.quiz_rounded,
                compact: true,
                onPressed: () => context.push('/vocabulary'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final word = words[index];
        return AuroraCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    word.word,
                    style: const TextStyle(
                      color: AuroraColors.auroraTeal,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AuroraColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      word.bookTitle,
                      style: const TextStyle(
                          color: AuroraColors.textTertiary, fontSize: 11),
                    ),
                  ),
                  if (word.mastered) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle_rounded,
                        color: AuroraColors.auroraGreen, size: 16),
                  ],
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
                Text(
                  '"${word.context}"',
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighlightsTab(
      List<({BookModel book, HighlightModel highlight})> highlights) {
    if (highlights.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.highlight_rounded,
                  color: AuroraColors.manuscriptGold, size: 48),
              const SizedBox(height: 16),
              const Text(
                'No highlights yet',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Passages you highlight while reading will appear here — a living anthology of your best finds.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: highlights.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = highlights[index];
        final h = entry.highlight;
        final color = _highlightColor(h.colorName);
        return AuroraCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '"${h.highlightedText}"',
                      style: const TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (h.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Text(
                    h.note,
                    style: const TextStyle(
                      color: AuroraColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded,
                      color: AuroraColors.textTertiary, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      entry.book.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AuroraColors.textTertiary, fontSize: 12),
                    ),
                  ),
                  Text(
                    _formatDate(h.dateCreated),
                    style: const TextStyle(
                        color: AuroraColors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _moodColor(String mood) {
    switch (mood) {
      case BookMood.adventurous:
        return AuroraColors.auroraWarm;
      case BookMood.dark:
        return AuroraColors.auroraPurple;
      case BookMood.emotional:
        return AuroraColors.auroraPink;
      case BookMood.hopeful:
        return AuroraColors.auroraGreen;
      case BookMood.funny:
        return AuroraColors.manuscriptGold;
      case BookMood.tense:
        return AuroraColors.auroraWarm;
      case BookMood.inspiring:
        return AuroraColors.auroraTeal;
      case BookMood.reflective:
        return AuroraColors.auroraPurple;
      case BookMood.romantic:
        return AuroraColors.auroraPink;
      case BookMood.mysterious:
        return AuroraColors.auroraPurple;
      case BookMood.lighthearted:
        return AuroraColors.auroraGreen;
      case BookMood.melancholic:
        return AuroraColors.auroraBlue;
      default:
        return AuroraColors.auroraTeal;
    }
  }

  Color _highlightColor(String colorName) {
    switch (colorName) {
      case 'auroraTeal':
        return AuroraColors.auroraTeal;
      case 'auroraGreen':
        return AuroraColors.auroraGreen;
      case 'auroraPurple':
        return AuroraColors.auroraPurple;
      case 'manuscriptGold':
        return AuroraColors.manuscriptGold;
      case 'auroraWarm':
        return AuroraColors.auroraWarm;
      case 'auroraPink':
        return AuroraColors.auroraPink;
      default:
        return AuroraColors.auroraTeal;
    }
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
