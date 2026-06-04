import 'dart:convert';

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ── Audiobook Progress ──────────────────────────────────────────────────────

class AudiobookProgress {
  final String bookId;
  final Duration totalDuration;
  final Duration currentPosition;
  final int currentChapter;
  final double playbackSpeed;
  final DateTime lastListened;
  final List<AudiobookNote> notes;

  const AudiobookProgress({
    required this.bookId,
    required this.totalDuration,
    this.currentPosition = Duration.zero,
    this.currentChapter = 1,
    this.playbackSpeed = 1.0,
    required this.lastListened,
    this.notes = const [],
  });

  double get progressPercent {
    if (totalDuration.inSeconds == 0) return 0.0;
    return (currentPosition.inSeconds / totalDuration.inSeconds)
        .clamp(0.0, 1.0);
  }

  Duration get remaining => totalDuration - currentPosition;

  String get formattedPosition => _formatDuration(currentPosition);
  String get formattedTotal => _formatDuration(totalDuration);
  String get formattedRemaining => _formatDuration(remaining);

  static String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  AudiobookProgress copyWith({
    Duration? totalDuration,
    Duration? currentPosition,
    int? currentChapter,
    double? playbackSpeed,
    DateTime? lastListened,
    List<AudiobookNote>? notes,
  }) {
    return AudiobookProgress(
      bookId: bookId,
      totalDuration: totalDuration ?? this.totalDuration,
      currentPosition: currentPosition ?? this.currentPosition,
      currentChapter: currentChapter ?? this.currentChapter,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      lastListened: lastListened ?? this.lastListened,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'totalDurationSeconds': totalDuration.inSeconds,
        'currentPositionSeconds': currentPosition.inSeconds,
        'currentChapter': currentChapter,
        'playbackSpeed': playbackSpeed,
        'lastListened': lastListened.toIso8601String(),
        'notes': notes.map((n) => n.toJson()).toList(),
      };

  factory AudiobookProgress.fromJson(Map<String, dynamic> json) =>
      AudiobookProgress(
        bookId: json['bookId'] as String,
        totalDuration:
            Duration(seconds: json['totalDurationSeconds'] as int? ?? 0),
        currentPosition:
            Duration(seconds: json['currentPositionSeconds'] as int? ?? 0),
        currentChapter: json['currentChapter'] as int? ?? 1,
        playbackSpeed:
            (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
        lastListened: json['lastListened'] != null
            ? DateTime.parse(json['lastListened'] as String)
            : DateTime.now(),
        notes: (json['notes'] as List?)
                ?.map((n) =>
                    AudiobookNote.fromJson(n as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

// ── Audiobook Note ──────────────────────────────────────────────────────────

class AudiobookNote {
  final String id;
  final Duration timestamp;
  final String note;
  final DateTime dateCreated;

  const AudiobookNote({
    required this.id,
    required this.timestamp,
    required this.note,
    required this.dateCreated,
  });

  String get formattedTimestamp => AudiobookProgress._formatDuration(timestamp);

  AudiobookNote copyWith({
    Duration? timestamp,
    String? note,
  }) {
    return AudiobookNote(
      id: id,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      dateCreated: dateCreated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestampSeconds': timestamp.inSeconds,
        'note': note,
        'dateCreated': dateCreated.toIso8601String(),
      };

  factory AudiobookNote.fromJson(Map<String, dynamic> json) =>
      AudiobookNote(
        id: json['id'] as String,
        timestamp:
            Duration(seconds: json['timestampSeconds'] as int? ?? 0),
        note: json['note'] as String? ?? '',
        dateCreated: json['dateCreated'] != null
            ? DateTime.parse(json['dateCreated'] as String)
            : DateTime.now(),
      );

  factory AudiobookNote.create({
    required Duration timestamp,
    required String note,
  }) =>
      AudiobookNote(
        id: _uuid.v4(),
        timestamp: timestamp,
        note: note,
        dateCreated: DateTime.now(),
      );
}
