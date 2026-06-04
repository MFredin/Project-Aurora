import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/book_repository.dart';
import '../../core/data/models.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

class ReadingWrapScreen extends ConsumerWidget {
  final int year;

  const ReadingWrapScreen({super.key, required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(bookRepositoryProvider);
    final sessions = ref.watch(readingSessionsProvider);
    final currentStreak =
        ref.read(bookRepositoryProvider.notifier).getCurrentStreak();

    // Compute stats
    final stats = _computeStats(books, sessions, currentStreak, year);

    return Scaffold(
      backgroundColor: AuroraColors.deepSpace,
      body: Stack(
        children: [
          // Background gradient
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
                        icon: const Icon(Icons.close_rounded,
                            color: AuroraColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      Text(
                        'Edda',
                        style: TextStyle(
                          color: AuroraColors.manuscriptGold.withOpacity(0.7),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.share_rounded,
                            color: AuroraColors.textSecondary),
                        onPressed: () => _showShareSummary(context, stats),
                      ),
                    ],
                  ),
                ),

                // Scrollable cards
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    children: [
                      // Title card
                      _buildTitleCard(),
                      const SizedBox(height: 16),

                      // Books finished
                      _buildStatCard(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A3A2E), Color(0xFF0D1210)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        icon: Icons.auto_stories_rounded,
                        iconColor: AuroraColors.auroraGreen,
                        value: '${stats.booksFinished}',
                        label: 'Books Finished',
                        subtitle: stats.booksFinished == 1
                            ? 'story completed this year'
                            : 'stories completed this year',
                      ),
                      const SizedBox(height: 16),

                      // Total reading time
                      _buildStatCard(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A1E14), Color(0xFF0D1210)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        icon: Icons.schedule_rounded,
                        iconColor: AuroraColors.auroraTeal,
                        value: _formatMinutes(stats.totalMinutes),
                        label: 'Total Reading Time',
                        subtitle: 'spent immersed in stories',
                      ),
                      const SizedBox(height: 16),

                      // Top moods
                      _buildMoodsCard(stats.topMoods),
                      const SizedBox(height: 16),

                      // Longest streak
                      _buildStatCard(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A1410), Color(0xFF0D1210)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AuroraColors.auroraWarm,
                        value: '${stats.longestStreak}',
                        label: 'Day Streak',
                        subtitle: 'your current reading streak',
                      ),
                      const SizedBox(height: 16),

                      // Fastest book
                      if (stats.fastestBook != null)
                        _buildBookStatCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A2A34), Color(0xFF0D1210)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          icon: Icons.speed_rounded,
                          iconColor: AuroraColors.auroraTeal,
                          label: 'Fastest Read',
                          bookTitle: stats.fastestBook!,
                          detail: '${stats.fastestBookDays} days',
                        ),
                      if (stats.fastestBook != null)
                        const SizedBox(height: 16),

                      // Most highlighted
                      if (stats.mostHighlightedBook != null)
                        _buildBookStatCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2A2418), Color(0xFF0D1210)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          icon: Icons.highlight_rounded,
                          iconColor: AuroraColors.manuscriptGold,
                          label: 'Most Highlighted',
                          bookTitle: stats.mostHighlightedBook!,
                          detail:
                              '${stats.mostHighlightedCount} highlights',
                        ),
                      if (stats.mostHighlightedBook != null)
                        const SizedBox(height: 16),

                      // Average rating
                      if (stats.averageRating > 0)
                        _buildStatCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF24201A), Color(0xFF0D1210)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          icon: Icons.star_rounded,
                          iconColor: AuroraColors.manuscriptGold,
                          value: stats.averageRating.toStringAsFixed(1),
                          label: 'Average Rating',
                          subtitle: 'across all rated books',
                        ),
                      if (stats.averageRating > 0)
                        const SizedBox(height: 16),

                      // Share button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: AuroraButton(
                          label: 'Share My Year in Review',
                          icon: Icons.share_rounded,
                          onPressed: () =>
                              _showShareSummary(context, stats),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A2A20),
            Color(0xFF14201A),
            AuroraColors.deepSpace,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AuroraColors.auroraGreen.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            '$year',
            style: TextStyle(
              color: AuroraColors.manuscriptGold.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                AuroraColors.auroraTeal,
                AuroraColors.manuscriptGold,
                AuroraColors.auroraGreen,
              ],
            ).createShader(bounds),
            child: const Text(
              'Year in Review',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your reading journey, wrapped',
            style: TextStyle(
              color: AuroraColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required LinearGradient gradient,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AuroraColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookStatCard({
    required LinearGradient gradient,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String bookTitle,
    required String detail,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            bookTitle,
            style: const TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(
              color: AuroraColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodsCard(List<String> moods) {
    final moodColors = [
      AuroraColors.auroraGreen,
      AuroraColors.auroraTeal,
      AuroraColors.manuscriptGold,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1A24), Color(0xFF0D1210)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AuroraColors.auroraPurple.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AuroraColors.auroraPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.mood_rounded,
                color: AuroraColors.auroraPurple, size: 24),
          ),
          const SizedBox(height: 20),
          const Text(
            'Top Moods',
            style: TextStyle(
              color: AuroraColors.auroraPurple,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (moods.isEmpty)
            const Text(
              'No mood data yet',
              style: TextStyle(
                color: AuroraColors.textTertiary,
                fontSize: 14,
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: moods.asMap().entries.map((entry) {
                final color =
                    moodColors[entry.key % moodColors.length];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 8),
          const Text(
            'your most-read vibes',
            style: TextStyle(
              color: AuroraColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  _WrapStats _computeStats(
    List<BookModel> books,
    List<ReadingSessionModel> sessions,
    int currentStreak,
    int year,
  ) {
    // Books finished this year
    final finishedThisYear = books.where((b) =>
        b.readingStatus == ReadingStatus.read &&
        b.finishDate != null &&
        b.finishDate!.year == year);
    final booksFinished = finishedThisYear.length;

    // Total reading minutes this year (from sessions)
    final yearSessions = sessions.where((s) => s.startTime.year == year);
    int totalMinutes =
        yearSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
    // Also include book-level reading seconds for books read this year
    if (totalMinutes == 0) {
      totalMinutes = finishedThisYear.fold<int>(
              0, (sum, b) => sum + b.progress.totalReadingSeconds) ~/
          60;
    }

    // Top 3 moods across books read this year
    final moodCounts = <String, int>{};
    for (final b in finishedThisYear) {
      for (final mood in b.moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }
    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMoods =
        sortedMoods.take(3).map((e) => e.key).toList();

    // Book with most highlights
    String? mostHighlightedBook;
    int mostHighlightedCount = 0;
    for (final b in books) {
      if (b.highlights.length > mostHighlightedCount) {
        mostHighlightedCount = b.highlights.length;
        mostHighlightedBook = b.title;
      }
    }
    if (mostHighlightedCount == 0) mostHighlightedBook = null;

    // Fastest book (smallest diff between startDate and finishDate)
    String? fastestBook;
    int fastestBookDays = 999999;
    for (final b in finishedThisYear) {
      if (b.startDate != null && b.finishDate != null) {
        final days =
            b.finishDate!.difference(b.startDate!).inDays;
        if (days < fastestBookDays) {
          fastestBookDays = max(days, 1);
          fastestBook = b.title;
        }
      }
    }
    if (fastestBook == null) fastestBookDays = 0;

    // Average rating
    final ratedBooks =
        finishedThisYear.where((b) => b.rating != null && b.rating! > 0);
    final averageRating = ratedBooks.isEmpty
        ? 0.0
        : ratedBooks.fold<double>(0, (sum, b) => sum + b.rating!) /
            ratedBooks.length;

    return _WrapStats(
      booksFinished: booksFinished,
      totalMinutes: totalMinutes,
      topMoods: topMoods,
      longestStreak: currentStreak,
      fastestBook: fastestBook,
      fastestBookDays: fastestBookDays,
      mostHighlightedBook: mostHighlightedBook,
      mostHighlightedCount: mostHighlightedCount,
      averageRating: averageRating,
    );
  }

  void _showShareSummary(BuildContext context, _WrapStats stats) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuroraColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AuroraColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A2A20),
                      Color(0xFF14201A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AuroraColors.auroraGreen.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Edda  |  $year',
                      style: TextStyle(
                        color:
                            AuroraColors.manuscriptGold.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _shareStat(
                            '${stats.booksFinished}', 'Books'),
                        _shareStat(
                            _formatMinutes(stats.totalMinutes), 'Time'),
                        _shareStat(
                            '${stats.longestStreak}', 'Streak'),
                      ],
                    ),
                    if (stats.averageRating > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Avg Rating: ${stats.averageRating.toStringAsFixed(1)} / 5',
                        style: const TextStyle(
                          color: AuroraColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Screenshot to share with friends!',
                style: TextStyle(
                  color: AuroraColors.textTertiary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _shareStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AuroraColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AuroraColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _WrapStats {
  final int booksFinished;
  final int totalMinutes;
  final List<String> topMoods;
  final int longestStreak;
  final String? fastestBook;
  final int fastestBookDays;
  final String? mostHighlightedBook;
  final int mostHighlightedCount;
  final double averageRating;

  const _WrapStats({
    required this.booksFinished,
    required this.totalMinutes,
    required this.topMoods,
    required this.longestStreak,
    this.fastestBook,
    required this.fastestBookDays,
    this.mostHighlightedBook,
    required this.mostHighlightedCount,
    required this.averageRating,
  });
}
