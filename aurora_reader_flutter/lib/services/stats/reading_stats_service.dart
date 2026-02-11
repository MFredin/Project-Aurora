import '../../core/database/database.dart';

/// Computes reading statistics, streaks, and activity data from
/// the local database.
///
/// All calculations are derived from ReadingSessions and
/// ReadingProgresses data. Results are not cached and are
/// always freshly computed from the database.
class ReadingStatsService {
  final AppDatabase _db;

  ReadingStatsService(this._db);

  /// Get total reading time in minutes across all sessions.
  Future<int> getTotalReadingMinutes() async {
    final sessions = await _db.watchAllSessions().first;
    final totalSeconds =
        sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    return (totalSeconds / 60).round();
  }

  /// Get total number of books finished (progress >= 1.0).
  Future<int> getBooksFinished() async {
    final books = await _db.getAllBooks();
    int count = 0;
    for (final book in books) {
      final progress = await _db.getProgressForBook(book.id);
      if (progress != null && progress.progressPercentage >= 1.0) {
        count++;
      }
    }
    return count;
  }

  /// Get total pages read across all sessions.
  Future<int> getTotalPagesRead() async {
    final sessions = await _db.watchAllSessions().first;
    return sessions.fold<int>(0, (sum, s) => sum + s.pagesRead);
  }

  /// Get reading minutes per day for the last [days] days.
  Future<Map<DateTime, int>> getDailyReadingMinutes({int days = 30}) async {
    final sessions = await _db.watchAllSessions().first;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final result = <DateTime, int>{};

    for (final session in sessions) {
      if (session.startTime.isBefore(cutoff)) continue;
      final day = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      result[day] = (result[day] ?? 0) + (session.durationSeconds ~/ 60);
    }

    return result;
  }

  /// Get the current reading streak (consecutive days with a session).
  Future<ReadingStreakInfo> getCurrentStreak() async {
    final sessions = await _db.watchAllSessions().first;
    if (sessions.isEmpty) {
      return const ReadingStreakInfo(current: 0, longest: 0, totalDays: 0);
    }

    // Collect unique reading days
    final days = <DateTime>{};
    for (final s in sessions) {
      days.add(DateTime(s.startTime.year, s.startTime.month, s.startTime.day));
    }

    final sortedDays = days.toList()..sort();
    int currentStreak = 1;
    int longestStreak = 1;
    int tempStreak = 1;

    for (int i = sortedDays.length - 1; i > 0; i--) {
      final diff = sortedDays[i].difference(sortedDays[i - 1]).inDays;
      if (diff == 1) {
        tempStreak++;
      } else {
        if (i == sortedDays.length - 1 ||
            sortedDays.last.difference(sortedDays[i]).inDays == 0) {
          currentStreak = tempStreak;
        }
        longestStreak =
            tempStreak > longestStreak ? tempStreak : longestStreak;
        tempStreak = 1;
      }
    }
    longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

    // Check if current streak includes today or yesterday
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDay = sortedDays.last;
    final daysSinceLastRead = todayDate.difference(lastDay).inDays;
    if (daysSinceLastRead > 1) {
      currentStreak = 0;
    } else {
      currentStreak = tempStreak;
    }

    return ReadingStreakInfo(
      current: currentStreak,
      longest: longestStreak,
      totalDays: days.length,
    );
  }

  /// Get weekly summary stats.
  Future<WeeklySummary> getWeeklySummary() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final sessions = await _db.watchAllSessions().first;

    int totalMinutes = 0;
    int totalPages = 0;
    int totalWords = 0;
    int sessionCount = 0;

    for (final s in sessions) {
      if (s.startTime.isAfter(weekStart)) {
        totalMinutes += s.durationSeconds ~/ 60;
        totalPages += s.pagesRead;
        totalWords += s.wordsRead;
        sessionCount++;
      }
    }

    return WeeklySummary(
      totalMinutes: totalMinutes,
      totalPages: totalPages,
      totalWords: totalWords,
      sessionCount: sessionCount,
    );
  }
}

/// Streak info summary.
class ReadingStreakInfo {
  final int current;
  final int longest;
  final int totalDays;

  const ReadingStreakInfo({
    required this.current,
    required this.longest,
    required this.totalDays,
  });
}

/// Weekly reading summary.
class WeeklySummary {
  final int totalMinutes;
  final int totalPages;
  final int totalWords;
  final int sessionCount;

  const WeeklySummary({
    required this.totalMinutes,
    required this.totalPages,
    required this.totalWords,
    required this.sessionCount,
  });
}
