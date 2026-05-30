import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../services/logging/error_logger.dart';

class ErrorLogScreen extends StatefulWidget {
  const ErrorLogScreen({super.key});

  @override
  State<ErrorLogScreen> createState() => _ErrorLogScreenState();
}

class _ErrorLogScreenState extends State<ErrorLogScreen> {
  List<LogEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _entries = ErrorLogger.instance.getEntries().reversed.toList();
  }

  void _copyAll() {
    if (_entries.isEmpty) return;
    final buffer = StringBuffer();
    for (final entry in _entries) {
      buffer.writeln('${entry.timestamp.toIso8601String()} '
          '[${entry.level.name.toUpperCase()}] '
          '${entry.source}: ${entry.message}');
      if (entry.stackTrace != null) {
        buffer.writeln(entry.stackTrace);
      }
      buffer.writeln();
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log copied to clipboard')),
    );
  }

  void _clearLog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surfaceElevated,
        title: const Text('Clear Error Log',
            style: TextStyle(color: AuroraColors.textPrimary)),
        content: const Text('This will delete all logged errors.',
            style: TextStyle(color: AuroraColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ErrorLogger.instance.clear();
              setState(() => _entries = []);
              Navigator.of(ctx).pop();
            },
            child: Text('Clear',
                style: TextStyle(color: AuroraColors.auroraWarm)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AuroraColors.cosmos.withOpacity(0.95),
          foregroundColor: AuroraColors.textPrimary,
          title: Text('Error Log (${_entries.length})'),
          elevation: 0,
          actions: [
            if (_entries.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20),
                tooltip: 'Copy all',
                onPressed: _copyAll,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                tooltip: 'Clear log',
                onPressed: _clearLog,
              ),
            ],
          ],
        ),
        body: _entries.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: AuroraColors.auroraGreen, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'No errors recorded',
                      style: TextStyle(
                        color: AuroraColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return _buildLogCard(entry);
                },
              ),
      ),
    );
  }

  Widget _buildLogCard(LogEntry entry) {
    final isError = entry.level == LogLevel.error;
    final accentColor =
        isError ? AuroraColors.auroraWarm : AuroraColors.manuscriptGold;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AuroraCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: accentColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.source,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatTime(entry.timestamp),
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              entry.message,
              style: const TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (entry.stackTrace != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showStackTrace(entry),
                child: Text(
                  'Tap to view stack trace',
                  style: TextStyle(
                    color: AuroraColors.auroraGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStackTrace(LogEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuroraColors.surfaceElevated,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.source,
                      style: const TextStyle(
                        color: AuroraColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: AuroraColors.textSecondary,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${entry.message}\n\n${entry.stackTrace}',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SelectableText(
                  entry.stackTrace ?? '',
                  style: const TextStyle(
                    color: AuroraColors.textSecondary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
