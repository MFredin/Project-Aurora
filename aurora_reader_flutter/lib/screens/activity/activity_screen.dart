import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/models.dart';
import '../../core/data/book_repository.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

const _weekDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthLabels = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  String _chartPeriod = 'Week';

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(bookRepositoryProvider);
    final sessions = ref.watch(readingSessionsProvider);
    final currentStreak = ref.read(bookRepositoryProvider.notifier).getCurrentStreak();
    final currentYear = DateTime.now().year;
    final goal = ref.read(bookRepositoryProvider.notifier).getGoal(currentYear);
    final today = DateTime.now();

    // Compute reading stats from real data
    final totalBooksRead = books.where((b) => b.readingStatus == ReadingStatus.read).length;
    final currentYearBooks = books.where((b) =>
        b.readingStatus == ReadingStatus.read &&
        b.finishDate != null &&
        b.finishDate!.year == currentYear).length;
    final totalReadingSeconds = books.fold<int>(
        0, (sum, b) => sum + b.progress.totalReadingSeconds);

    // Session-derived stats
    final todayMinutes = sessions
        .where((s) => _isSameDay(s.startTime, today))
        .fold(0, (sum, s) => sum + s.durationSeconds ~/ 60);

    final longestStreak = _computeLongestStreak(sessions);

    final weeklyMinutes = _computeWeeklyMinutes(sessions, today);
    final monthlyBooksData = _computeMonthlyBooks(books, currentYear);
    final heatmapData = _computeHeatmap(sessions, today);

    final recentSessions = sessions.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: ResponsiveHelper.contentMaxWidth(context)),
              child: CustomScrollView(
                slivers: [
              // Header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Activity',
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // --- Year in Review & Daily Review ---
              SliverToBoxAdapter(
                child: _buildYearInReviewCard(currentYear),
              ),

              // --- NEW: Reading Streak Banner ---
              SliverToBoxAdapter(
                child: _buildReadingStreakBanner(currentStreak),
              ),

              // --- NEW: Annual Reading Goal ---
              SliverToBoxAdapter(
                child: _buildAnnualGoalCard(goal, currentYear, currentYearBooks),
              ),

              // --- NEW: Reading Stats Summary ---
              SliverToBoxAdapter(
                child: _buildReadingStatsSummary(
                  totalBooksRead: totalBooksRead,
                  totalReadingSeconds: totalReadingSeconds,
                  currentYearBooks: currentYearBooks,
                ),
              ),

              // Streak + Today summary cards
              SliverToBoxAdapter(
                  child: _buildStreakSection(currentStreak, longestStreak, todayMinutes)),

              // Today's reading goal ring (real data)
              SliverToBoxAdapter(child: _buildTodayReading(todayMinutes)),

              // Reading time chart
              SliverToBoxAdapter(
                  child: _buildReadingChart(weeklyMinutes, monthlyBooksData)),

              // Calendar heatmap
              SliverToBoxAdapter(child: _buildHeatmap(heatmapData)),

              // Recent sessions
              SliverToBoxAdapter(child: _buildRecentSessions(recentSessions)),

              // Achievement badges
              SliverToBoxAdapter(child: _buildAchievements()),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Year in Review & Daily Review Cards ─────────────────────────────

  Widget _buildYearInReviewCard(int year) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: AuroraCard(
              onTap: () => context.push('/reading-wrap/$year'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AuroraColors.manuscriptGold.withOpacity(0.25),
                          AuroraColors.auroraTeal.withOpacity(0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AuroraColors.auroraTeal,
                          AuroraColors.manuscriptGold,
                        ],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$year in Review',
                          style: const TextStyle(
                            color: AuroraColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Your reading wrapped',
                          style: TextStyle(
                            color: AuroraColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AuroraColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AuroraCard(
              onTap: () => context.push('/daily-review'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AuroraColors.auroraGreen.withOpacity(0.25),
                          AuroraColors.auroraPurple.withOpacity(0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.highlight_rounded,
                      size: 22,
                      color: AuroraColors.manuscriptGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Review',
                          style: TextStyle(
                            color: AuroraColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Revisit highlights',
                          style: TextStyle(
                            color: AuroraColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AuroraColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NEW: Reading Streak Banner ──────────────────────────────────────

  Widget _buildReadingStreakBanner(int streak) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: AuroraCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Flame icon with warm gradient
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AuroraColors.auroraWarm.withOpacity(0.25),
                    AuroraColors.auroraTeal.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AuroraColors.warmGradient.createShader(bounds),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$streak',
                        style: const TextStyle(
                          color: AuroraColors.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        streak == 1 ? 'day' : 'days',
                        style: const TextStyle(
                          color: AuroraColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streak > 0
                        ? 'Current reading streak'
                        : 'Start reading to build your streak!',
                    style: const TextStyle(
                      color: AuroraColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (streak >= 7)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AuroraColors.auroraWarm.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  streak >= 30 ? 'On fire!' : 'Nice!',
                  style: const TextStyle(
                    color: AuroraColors.auroraWarm,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── NEW: Annual Reading Goal Card ───────────────────────────────────

  Widget _buildAnnualGoalCard(ReadingGoalModel? goal, int currentYear, int currentYearBooks) {
    if (goal == null) {
      return _buildSetGoalPrompt(currentYear, currentYearBooks);
    }

    final progressValue = goal.progress;
    final isAhead = goal.isAhead;
    final expectedByNow = goal.expectedByNow;
    final diff = goal.booksRead - expectedByNow;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: AuroraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AuroraColors.manuscriptGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$currentYear Reading Goal',
                  style: const TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showGoalDialog(
                    currentYear,
                    currentYearBooks,
                    existingGoal: goal,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AuroraColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF252E27),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: AuroraColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Books count
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${goal.booksRead}',
                  style: const TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ ${goal.targetBooks} books',
                  style: const TextStyle(
                    color: AuroraColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: AuroraColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAhead ? AuroraColors.auroraGreen : AuroraColors.auroraWarm,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Pace indicator
            Row(
              children: [
                Icon(
                  isAhead
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: isAhead
                      ? AuroraColors.auroraGreen
                      : AuroraColors.auroraWarm,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isAhead
                      ? 'Ahead of pace by ${diff.abs()} ${diff.abs() == 1 ? "book" : "books"}'
                      : 'Behind pace by ${diff.abs()} ${diff.abs() == 1 ? "book" : "books"}',
                  style: TextStyle(
                    color: isAhead
                        ? AuroraColors.auroraGreen
                        : AuroraColors.auroraWarm,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progressValue * 100).toInt()}%',
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
    );
  }

  Widget _buildSetGoalPrompt(int currentYear, int currentYearBooks) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: AuroraCard(
        child: Column(
          children: [
            const Icon(
              Icons.flag_rounded,
              color: AuroraColors.manuscriptGold,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Set a $currentYear Reading Goal',
              style: const TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Track your annual reading progress',
              style: TextStyle(
                color: AuroraColors.textTertiary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            AuroraButton(
              label: 'Set Goal',
              icon: Icons.add_rounded,
              compact: true,
              onPressed: () => _showGoalDialog(currentYear, currentYearBooks),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalDialog(int year, int currentYearBooks, {ReadingGoalModel? existingGoal}) {
    final controller = TextEditingController(
      text: existingGoal != null ? '${existingGoal.targetBooks}' : '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AuroraColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF252E27), width: 0.5),
          ),
          title: Text(
            existingGoal != null ? 'Edit Reading Goal' : 'Set Reading Goal',
            style: const TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How many books do you want to read in $year?',
                style: const TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                style: const TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '24',
                  hintStyle: TextStyle(
                    color: AuroraColors.textTertiary.withOpacity(0.5),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  suffixText: 'books',
                  suffixStyle: const TextStyle(
                    color: AuroraColors.textSecondary,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AuroraColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF252E27)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF252E27)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AuroraColors.auroraTeal),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AuroraColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final target = int.tryParse(controller.text);
                if (target != null && target > 0) {
                  final booksRead = existingGoal?.booksRead ?? currentYearBooks;
                  final newGoal = ReadingGoalModel(
                    year: year,
                    targetBooks: target,
                    booksRead: booksRead,
                  );
                  ref.read(bookRepositoryProvider.notifier).saveGoal(newGoal);
                  setState(() {});
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AuroraColors.auroraTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── NEW: Reading Stats Summary ──────────────────────────────────────

  Widget _buildReadingStatsSummary({
    required int totalBooksRead,
    required int totalReadingSeconds,
    required int currentYearBooks,
  }) {
    final totalHours = totalReadingSeconds ~/ 3600;
    final totalMinutes = (totalReadingSeconds % 3600) ~/ 60;
    final timeLabel = totalHours > 0
        ? '${totalHours}h ${totalMinutes}m'
        : '${totalMinutes}m';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          _buildStatTile(
            icon: Icons.check_circle_rounded,
            iconColor: AuroraColors.auroraGreen,
            value: '$totalBooksRead',
            label: 'Total Read',
          ),
          const SizedBox(width: 10),
          _buildStatTile(
            icon: Icons.schedule_rounded,
            iconColor: AuroraColors.auroraTeal,
            value: timeLabel,
            label: 'Total Time',
          ),
          const SizedBox(width: 10),
          _buildStatTile(
            icon: Icons.calendar_today_rounded,
            iconColor: AuroraColors.manuscriptGold,
            value: '$currentYearBooks',
            label: 'This Year',
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: AuroraCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
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

  // ── EXISTING: Streak + Today summary (updated to use live streak) ──

  Widget _buildStreakSection(int currentStreak, int longestStreak, int todayMinutes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: AuroraCard(
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AuroraColors.warmGradient.createShader(bounds),
                    child: const Icon(Icons.local_fire_department_rounded,
                        size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$currentStreak',
                    style: const TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Day Streak',
                    style: TextStyle(
                      color: AuroraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Longest: $longestStreak days',
                    style: const TextStyle(
                      color: AuroraColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                AuroraCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AuroraColors.auroraGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: AuroraColors.auroraGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ref.watch(bookRepositoryProvider).where((b) => b.readingStatus == ReadingStatus.read && b.finishDate != null && b.finishDate!.year == DateTime.now().year).length}',
                            style: const TextStyle(
                              color: AuroraColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Books this year',
                            style: TextStyle(
                              color: AuroraColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AuroraCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AuroraColors.auroraTeal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.timer_rounded,
                            color: AuroraColors.auroraTeal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$todayMinutes min',
                            style: const TextStyle(
                              color: AuroraColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Read today',
                            style: TextStyle(
                              color: AuroraColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTodayReading(int todayMinutes) {
    const goalMinutes = 30;
    final progress = (todayMinutes / goalMinutes).clamp(0.0, 1.0);
    final goalMet = todayMinutes >= goalMinutes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: AuroraCard(
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _GoalRingPainter(
                  progress: progress,
                  color: goalMet ? AuroraColors.auroraGreen : AuroraColors.auroraTeal,
                ),
                child: Center(
                  child: Text(
                    '${todayMinutes}m',
                    style: const TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Reading",
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$todayMinutes of $goalMinutes min',
                    style: const TextStyle(
                        color: AuroraColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todayMinutes == 0
                        ? 'Open a book to start!'
                        : goalMet
                            ? 'Daily goal reached!'
                            : '${goalMinutes - todayMinutes} min to go',
                    style: TextStyle(
                      color: goalMet
                          ? AuroraColors.auroraGreen
                          : AuroraColors.auroraTeal,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingChart(List<int> weeklyMinutes, List<int> monthlyBooksData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: AuroraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Reading Time',
                  style: TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ...['Week', 'Month'].map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: AuroraFilterChip(
                      label: p,
                      isSelected: _chartPeriod == p,
                      onTap: () => setState(() => _chartPeriod = p),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: _chartPeriod == 'Week'
                  ? _buildWeeklyBarChart(weeklyMinutes)
                  : _buildMonthlyLineChart(monthlyBooksData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart(List<int> weeklyMinutes) {
    final maxY = weeklyMinutes.isEmpty
        ? 60.0
        : (weeklyMinutes.reduce(max) * 1.2).clamp(20.0, double.infinity);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AuroraColors.surfaceElevated,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} min',
                const TextStyle(
                  color: AuroraColors.auroraTeal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _weekDayLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _weekDayLabels[index],
                    style: const TextStyle(
                        color: AuroraColors.textTertiary, fontSize: 11),
                  ),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (i < weeklyMinutes.length ? weeklyMinutes[i] : 0).toDouble(),
                width: 20,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
                gradient: const LinearGradient(
                  colors: [AuroraColors.auroraTeal, AuroraColors.auroraGreen],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthlyLineChart(List<int> monthlyBooksData) {
    final maxY = monthlyBooksData.isEmpty
        ? 5.0
        : (monthlyBooksData.reduce(max) * 1.3).clamp(2.0, double.infinity);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= _monthLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _monthLabels[i],
                    style: const TextStyle(
                        color: AuroraColors.textTertiary, fontSize: 11),
                  ),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white.withOpacity(0.04), strokeWidth: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(12, (i) {
              return FlSpot(
                  i.toDouble(),
                  (i < monthlyBooksData.length ? monthlyBooksData[i] : 0)
                      .toDouble());
            }),
            gradient: AuroraColors.secondaryGradient,
            barWidth: 2.5,
            isCurved: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: AuroraColors.auroraPurple,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AuroraColors.auroraBlue.withOpacity(0.2),
                  AuroraColors.auroraPurple.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(List<int> heatmapData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: AuroraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reading Calendar',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Last 4 weeks',
              style: TextStyle(
                color: AuroraColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: List.generate(4, (row) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (col) {
                    final idx = row * 7 + col;
                    final minutes = idx < heatmapData.length ? heatmapData[idx] : 0;
                    final intensity = (minutes / 90.0).clamp(0.0, 1.0);
                    return Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: minutes == 0
                            ? AuroraColors.surface
                            : AuroraColors.auroraGreen
                                .withOpacity(0.15 + intensity * 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: minutes > 0
                          ? Center(
                              child: Text(
                                '$minutes',
                                style: TextStyle(
                                  color: intensity > 0.5
                                      ? Colors.white
                                      : AuroraColors.textTertiary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : null,
                    );
                  }),
                );
              }),
            ),
            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Less ',
                    style: TextStyle(
                        color: AuroraColors.textTertiary, fontSize: 10)),
                ...List.generate(5, (i) {
                  return Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == 0
                          ? AuroraColors.surface
                          : AuroraColors.auroraGreen
                              .withOpacity(0.15 + (i / 4) * 0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
                const Text(' More',
                    style: TextStyle(
                        color: AuroraColors.textTertiary, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessions(List<ReadingSessionModel> sessions) {
    final recent = sessions.take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Recent Sessions',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (recent.isEmpty)
            AuroraCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          color: AuroraColors.textTertiary, size: 32),
                      const SizedBox(height: 12),
                      const Text(
                        'No reading sessions yet',
                        style: TextStyle(
                            color: AuroraColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Open a book and start reading to track your sessions here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AuroraColors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...recent.map((session) {
              final durationMinutes = session.durationSeconds ~/ 60;
              final dateLabel = _sessionDateLabel(session.startTime);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AuroraCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient:
                              AuroraColors.coverGradient(session.bookTitle),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_stories_rounded,
                            color: Colors.white70, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.bookTitle,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AuroraColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                  color: AuroraColors.textTertiary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$durationMinutes min',
                            style: const TextStyle(
                              color: AuroraColors.auroraTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${session.pagesRead} pages',
                            style: const TextStyle(
                                color: AuroraColors.textTertiary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  static const _achievementIcons = <AchievementType, IconData>{
    AchievementType.firstBook: Icons.auto_stories_rounded,
    AchievementType.bookworm10: Icons.menu_book_rounded,
    AchievementType.bibliophile25: Icons.library_books_rounded,
    AchievementType.centurion100: Icons.emoji_events_rounded,
    AchievementType.genreExplorer: Icons.explore_rounded,
    AchievementType.streakWeek: Icons.local_fire_department_rounded,
    AchievementType.streakMonth: Icons.whatshot_rounded,
    AchievementType.nightOwl: Icons.nights_stay_rounded,
    AchievementType.earlyBird: Icons.wb_sunny_rounded,
    AchievementType.speedReader: Icons.speed_rounded,
    AchievementType.reviewer: Icons.rate_review_rounded,
    AchievementType.highlighter: Icons.highlight_rounded,
    AchievementType.consistent: Icons.calendar_month_rounded,
  };

  static const _achievementColors = <AchievementType, Color>{
    AchievementType.firstBook: AuroraColors.auroraGreen,
    AchievementType.bookworm10: AuroraColors.auroraGreen,
    AchievementType.bibliophile25: AuroraColors.auroraTeal,
    AchievementType.centurion100: AuroraColors.manuscriptGold,
    AchievementType.genreExplorer: AuroraColors.auroraPurple,
    AchievementType.streakWeek: AuroraColors.auroraWarm,
    AchievementType.streakMonth: AuroraColors.auroraWarm,
    AchievementType.nightOwl: AuroraColors.auroraPurple,
    AchievementType.earlyBird: AuroraColors.manuscriptGold,
    AchievementType.speedReader: AuroraColors.auroraTeal,
    AchievementType.reviewer: AuroraColors.auroraGreen,
    AchievementType.highlighter: AuroraColors.manuscriptGold,
    AchievementType.consistent: AuroraColors.auroraGreen,
  };

  Widget _buildAchievements() {
    final unlocked = ref.read(bookRepositoryProvider.notifier).getUnlockedAchievements();
    final unlockedSet = unlocked.toSet();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Text(
                  'Achievements',
                  style: TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${unlocked.length}/${AchievementType.values.length}',
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: ResponsiveHelper.gridColumns(context).clamp(2, 4),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: AchievementType.values.map((type) {
              final isUnlocked = unlockedSet.contains(type);
              final icon = _achievementIcons[type] ?? Icons.star_rounded;
              final color = _achievementColors[type] ?? AuroraColors.auroraGreen;

              return AuroraCard(
                padding: const EdgeInsets.all(12),
                child: Opacity(
                  opacity: isUnlocked ? 1.0 : 0.4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? color.withOpacity(0.2)
                              : AuroraColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: isUnlocked ? color : AuroraColors.textTertiary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUnlocked
                              ? AuroraColors.textPrimary
                              : AuroraColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.description,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AuroraColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Session data helpers ────────────────────────────────────────────

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int _computeLongestStreak(List<ReadingSessionModel> sessions) {
    if (sessions.isEmpty) return 0;
    final days = sessions
        .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .toList()
      ..sort();
    var longest = 1, current = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static List<int> _computeWeeklyMinutes(
      List<ReadingSessionModel> sessions, DateTime today) {
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return sessions
          .where((s) => _isSameDay(s.startTime, day))
          .fold(0, (sum, s) => sum + s.durationSeconds ~/ 60);
    });
  }

  static List<int> _computeMonthlyBooks(List<BookModel> books, int year) {
    return List.generate(12, (month) {
      return books
          .where((b) =>
              b.readingStatus == ReadingStatus.read &&
              b.finishDate != null &&
              b.finishDate!.year == year &&
              b.finishDate!.month == month + 1)
          .length;
    });
  }

  static List<int> _computeHeatmap(
      List<ReadingSessionModel> sessions, DateTime today) {
    return List.generate(28, (i) {
      final day = today.subtract(Duration(days: 27 - i));
      return sessions
          .where((s) => _isSameDay(s.startTime, day))
          .fold(0, (sum, s) => sum + s.durationSeconds ~/ 60);
    });
  }

  static String _sessionDateLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }
}

/// Custom painter for the daily goal progress ring
class _GoalRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GoalRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    // Background ring
    final bgPaint = Paint()
      ..color = AuroraColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [AuroraColors.auroraTeal, AuroraColors.auroraGreen],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoalRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
