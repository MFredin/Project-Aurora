import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

/// Mock data for activity screen
class _MockStats {
  static const int currentStreak = 12;
  static const int longestStreak = 34;
  static const int booksCompletedThisYear = 18;
  static const int pagesReadToday = 47;
  static const int dailyGoalPages = 60;
  static const int totalMinutesToday = 38;
  static const int totalBooksInLibrary = 42;

  static const weeklyMinutes = [45, 62, 30, 55, 48, 72, 38];
  static const weekDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const monthlyBooks = [3, 2, 4, 1, 3, 2, 2, 3, 4, 1, 2, 3];
  static const monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  // Calendar heatmap data (last 28 days, minutes read)
  static final heatmapData = List.generate(28, (i) {
    final rng = Random(i * 7 + 3);
    if (rng.nextDouble() < 0.15) return 0;
    return (rng.nextDouble() * 90 + 10).toInt();
  });

  static const recentSessions = <Map<String, dynamic>>[
    {
      'book': 'Dune',
      'date': 'Today',
      'duration': 38,
      'pages': 47,
    },
    {
      'book': 'The Left Hand of Darkness',
      'date': 'Yesterday',
      'duration': 52,
      'pages': 34,
    },
    {
      'book': 'Dune',
      'date': '2 days ago',
      'duration': 45,
      'pages': 55,
    },
    {
      'book': 'Snow Crash',
      'date': '3 days ago',
      'duration': 30,
      'pages': 28,
    },
    {
      'book': 'Dune',
      'date': '4 days ago',
      'duration': 62,
      'pages': 72,
    },
  ];

  static const achievements = <Map<String, dynamic>>[
    {
      'icon': Icons.local_fire_department_rounded,
      'title': 'Week Warrior',
      'desc': '7-day reading streak',
      'unlocked': true,
      'color': AuroraColors.auroraWarm,
    },
    {
      'icon': Icons.auto_stories_rounded,
      'title': 'Bookworm',
      'desc': 'Read 10 books',
      'unlocked': true,
      'color': AuroraColors.auroraGreen,
    },
    {
      'icon': Icons.nights_stay_rounded,
      'title': 'Night Owl',
      'desc': 'Read past midnight 5 times',
      'unlocked': true,
      'color': AuroraColors.auroraPurple,
    },
    {
      'icon': Icons.speed_rounded,
      'title': 'Speed Reader',
      'desc': 'Read 100 pages in one day',
      'unlocked': false,
      'color': AuroraColors.auroraTeal,
    },
    {
      'icon': Icons.emoji_events_rounded,
      'title': 'Marathon',
      'desc': '30-day reading streak',
      'unlocked': false,
      'color': AuroraColors.auroraWarm,
    },
    {
      'icon': Icons.library_books_rounded,
      'title': 'Librarian',
      'desc': 'Add 50 books to library',
      'unlocked': false,
      'color': AuroraColors.auroraBlue,
    },
  ];
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _chartPeriod = 'Week';

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
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

              // Streak + Today summary cards
              SliverToBoxAdapter(child: _buildStreakSection()),

              // Daily reading goal ring
              SliverToBoxAdapter(child: _buildDailyGoal()),

              // Reading time chart
              SliverToBoxAdapter(child: _buildReadingChart()),

              // Calendar heatmap
              SliverToBoxAdapter(child: _buildHeatmap()),

              // Recent sessions
              SliverToBoxAdapter(child: _buildRecentSessions()),

              // Achievement badges
              SliverToBoxAdapter(child: _buildAchievements()),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakSection() {
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
                  const Text(
                    '${_MockStats.currentStreak}',
                    style: TextStyle(
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
                    'Longest: ${_MockStats.longestStreak} days',
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_MockStats.booksCompletedThisYear}',
                            style: TextStyle(
                              color: AuroraColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_MockStats.totalMinutesToday} min',
                            style: TextStyle(
                              color: AuroraColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
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

  Widget _buildDailyGoal() {
    const progress =
        _MockStats.pagesReadToday / _MockStats.dailyGoalPages;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: AuroraCard(
        child: Row(
          children: [
            // Progress ring
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _GoalRingPainter(
                  progress: progress.clamp(0.0, 1.0),
                  color: AuroraColors.auroraTeal,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: AuroraColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                    'Daily Reading Goal',
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_MockStats.pagesReadToday} of ${_MockStats.dailyGoalPages} pages',
                    style: const TextStyle(
                      color: AuroraColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_MockStats.dailyGoalPages - _MockStats.pagesReadToday} pages to go',
                    style: const TextStyle(
                      color: AuroraColors.auroraTeal,
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

  Widget _buildReadingChart() {
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
                  ? _buildWeeklyBarChart()
                  : _buildMonthlyLineChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 80,
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
                if (index < 0 || index >= _MockStats.weekDayLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _MockStats.weekDayLabels[index],
                    style: const TextStyle(
                      color: AuroraColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: _MockStats.weeklyMinutes[i].toDouble(),
                width: 20,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
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

  Widget _buildMonthlyLineChart() {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 5,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= _MockStats.monthLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _MockStats.monthLabels[i],
                    style: const TextStyle(
                      color: AuroraColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.04),
            strokeWidth: 1,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(12, (i) {
              return FlSpot(
                  i.toDouble(), _MockStats.monthlyBooks[i].toDouble());
            }),
            gradient: AuroraColors.secondaryGradient,
            barWidth: 2.5,
            isCurved: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: AuroraColors.auroraPurple,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                );
              },
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

  Widget _buildHeatmap() {
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
            // 4 rows x 7 cols
            Column(
              children: List.generate(4, (row) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (col) {
                    final idx = row * 7 + col;
                    final minutes = _MockStats.heatmapData[idx];
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

  Widget _buildRecentSessions() {
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
          ...(_MockStats.recentSessions).map((session) {
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
                        gradient: AuroraColors.coverGradient(
                            session['book'] as String),
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
                            session['book'] as String,
                            style: const TextStyle(
                              color: AuroraColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            session['date'] as String,
                            style: const TextStyle(
                              color: AuroraColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${session['duration']} min',
                          style: const TextStyle(
                            color: AuroraColors.auroraTeal,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${session['pages']} pages',
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
          }),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Achievements',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: _MockStats.achievements.map((a) {
              final unlocked = a['unlocked'] as bool;
              final color = a['color'] as Color;
              return AuroraCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? color.withOpacity(0.2)
                            : AuroraColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        a['icon'] as IconData,
                        color: unlocked ? color : AuroraColors.textTertiary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a['title'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unlocked
                            ? AuroraColors.textPrimary
                            : AuroraColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a['desc'] as String,
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
              );
            }).toList(),
          ),
        ],
      ),
    );
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
