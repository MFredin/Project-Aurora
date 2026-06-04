import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/book_repository.dart';
import '../../core/data/models.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

class _ReviewHighlight {
  final String text;
  final String bookTitle;
  final String author;
  final String chapterTitle;
  final DateTime date;

  const _ReviewHighlight({
    required this.text,
    required this.bookTitle,
    required this.author,
    required this.chapterTitle,
    required this.date,
  });
}

class DailyReviewScreen extends ConsumerStatefulWidget {
  const DailyReviewScreen({super.key});

  @override
  ConsumerState<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends ConsumerState<DailyReviewScreen> {
  int _currentIndex = 0;
  late List<_ReviewHighlight> _highlights;
  bool _initialized = false;

  static const _cardGradients = [
    LinearGradient(
      colors: [Color(0xFF1A3A2E), Color(0xFF0D1210)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF2A1E14), Color(0xFF0D1210)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF24201A), Color(0xFF0D1210)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF1E1A24), Color(0xFF0D1210)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF1A2A34), Color(0xFF0D1210)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static const _accentColors = [
    AuroraColors.auroraGreen,
    AuroraColors.auroraTeal,
    AuroraColors.manuscriptGold,
    AuroraColors.auroraPurple,
    AuroraColors.auroraWarm,
  ];

  void _initHighlights(List<BookModel> books) {
    if (_initialized) return;
    _initialized = true;

    final allHighlights = <_ReviewHighlight>[];
    for (final book in books) {
      for (final h in book.highlights) {
        final chapterTitle = h.chapterIndex < book.chapters.length
            ? book.chapters[h.chapterIndex].title
            : 'Chapter ${h.chapterIndex + 1}';
        allHighlights.add(_ReviewHighlight(
          text: h.highlightedText,
          bookTitle: book.title,
          author: book.author,
          chapterTitle: chapterTitle,
          date: h.dateCreated,
        ));
      }
    }

    allHighlights.shuffle(Random());
    _highlights = allHighlights;
  }

  void _next() {
    if (_currentIndex < _highlights.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(bookRepositoryProvider);
    _initHighlights(books);

    return Scaffold(
      backgroundColor: AuroraColors.deepSpace,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF111815),
                  AuroraColors.deepSpace,
                  Color(0xFF0A0E0C),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AuroraColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      const Text(
                        'Daily Review',
                        style: TextStyle(
                          color: AuroraColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // balance
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _highlights.isEmpty
                      ? _buildEmptyState()
                      : _buildHighlightView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AuroraColors.manuscriptGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.highlight_rounded,
                color: AuroraColors.manuscriptGold,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Highlights Yet',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Highlight passages while reading to\nrevisit them here each day.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuroraColors.textTertiary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightView() {
    final highlight = _highlights[_currentIndex];
    final gradientIndex = _currentIndex % _cardGradients.length;
    final accentColor = _accentColors[_currentIndex % _accentColors.length];

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) {
            _next();
          } else if (details.primaryVelocity! > 100) {
            _previous();
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text(
                    '${_currentIndex + 1} of ${_highlights.length}',
                    style: const TextStyle(
                      color: AuroraColors.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / _highlights.length,
                        backgroundColor: AuroraColors.surface,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(accentColor),
                        minHeight: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Highlight card
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_currentIndex),
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: _cardGradients[gradientIndex],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor.withOpacity(0.15),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quote icon
                      Icon(
                        Icons.format_quote_rounded,
                        color: accentColor.withOpacity(0.4),
                        size: 40,
                      ),
                      const SizedBox(height: 16),

                      // Highlighted text
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            highlight.text,
                            style: const TextStyle(
                              color: AuroraColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      Container(
                        width: 40,
                        height: 2,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Book info
                      Text(
                        highlight.bookTitle,
                        style: const TextStyle(
                          color: AuroraColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${highlight.author}',
                        style: const TextStyle(
                          color: AuroraColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.bookmark_rounded,
                            color: accentColor.withOpacity(0.5),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              highlight.chapterTitle,
                              style: const TextStyle(
                                color: AuroraColors.textTertiary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDate(highlight.date),
                            style: const TextStyle(
                              color: AuroraColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: _currentIndex > 0
                      ? AuroraButton(
                          label: 'Previous',
                          icon: Icons.arrow_back_rounded,
                          compact: true,
                          gradient: const LinearGradient(
                            colors: [
                              AuroraColors.surface,
                              AuroraColors.surfaceElevated,
                            ],
                          ),
                          onPressed: _previous,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _currentIndex < _highlights.length - 1
                      ? AuroraButton(
                          label: 'Next',
                          icon: Icons.arrow_forward_rounded,
                          compact: true,
                          onPressed: _next,
                        )
                      : AuroraButton(
                          label: 'Done',
                          icon: Icons.check_rounded,
                          compact: true,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
