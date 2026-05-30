import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

enum LogLevel { warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String source;
  final String message;
  final String? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'source': source,
        'message': message,
        'stackTrace': stackTrace,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        level: LogLevel.values.firstWhere(
          (l) => l.name == json['level'],
          orElse: () => LogLevel.error,
        ),
        source: json['source'] as String,
        message: json['message'] as String,
        stackTrace: json['stackTrace'] as String?,
      );
}

class ErrorLogger {
  static const _logKey = 'error_log';
  static const _maxEntries = 200;

  static ErrorLogger? _instance;

  ErrorLogger._();

  static ErrorLogger get instance {
    _instance ??= ErrorLogger._();
    return _instance!;
  }

  Box get _box => Hive.box('aurora_reader');

  List<LogEntry> getEntries() {
    final raw = _box.get(_logKey) as String?;
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _persist(List<LogEntry> entries) {
    final trimmed =
        entries.length > _maxEntries ? entries.sublist(entries.length - _maxEntries) : entries;
    _box.put(_logKey, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  void capture(
    Object error, {
    StackTrace? stackTrace,
    required String source,
    LogLevel level = LogLevel.error,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      source: source,
      message: error.toString(),
      stackTrace: stackTrace?.toString(),
    );

    final entries = getEntries()..add(entry);
    _persist(entries);

    if (kDebugMode) {
      debugPrint('[${level.name.toUpperCase()}] $source: $error');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
  }

  void warning(String message, {required String source}) {
    capture(message, source: source, level: LogLevel.warning);
  }

  Future<void> clear() async {
    await _box.delete(_logKey);
  }

  int get entryCount => getEntries().length;
}
