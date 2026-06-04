import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/book_repository.dart';
import '../../core/data/models.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../services/export/highlight_export_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String _selectedFormat = 'markdown';
  bool _isExporting = false;

  final _formatOptions = [
    {'id': 'markdown', 'label': 'Markdown', 'desc': 'Human-readable, Obsidian-compatible'},
    {'id': 'json', 'label': 'JSON', 'desc': 'Structured data for backups'},
    {'id': 'csv', 'label': 'CSV', 'desc': 'Spreadsheet compatible'},
    {'id': 'obsidian', 'label': 'Obsidian', 'desc': 'YAML frontmatter + wikilinks'},
    {'id': 'notion', 'label': 'Notion', 'desc': 'Notion-ready JSON format'},
  ];

  Future<void> _export() async {
    final books = ref.read(bookRepositoryProvider);
    if (books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No books to export'),
          backgroundColor: AuroraColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final service = HighlightExportService(books);
      String path;

      switch (_selectedFormat) {
        case 'json':
          path = await service.exportAllJson();
          break;
        case 'csv':
          path = await service.exportAllCsv();
          break;
        case 'obsidian':
          path = await service.exportToObsidian();
          break;
        case 'notion':
          path = await service.exportNotionJson();
          break;
        case 'markdown':
        default:
          path = await service.exportAllMarkdown();
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to $path'),
            backgroundColor: AuroraColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AuroraColors.auroraWarm,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(bookRepositoryProvider);
    final totalHighlights = books.fold<int>(0, (s, b) => s + b.highlights.length);
    final totalNotes = books.fold<int>(0, (s, b) => s + b.readingNotes.length);
    final totalQuotes = books.fold<int>(0, (s, b) => s + b.savedQuotes.length);
    final totalBookmarks = books.fold<int>(0, (s, b) => s + b.bookmarks.length);
    final booksWithData = books.where((b) =>
        b.highlights.isNotEmpty ||
        b.readingNotes.isNotEmpty ||
        b.savedQuotes.isNotEmpty ||
        b.review.isNotEmpty).length;

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Export Data',
              style: TextStyle(color: AuroraColors.textPrimary)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AuroraColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Summary card
                AuroraCard(
                  child: Column(
                    children: [
                      const Icon(Icons.library_books_rounded,
                          color: AuroraColors.auroraTeal, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        '${books.length} books in library',
                        style: const TextStyle(
                          color: AuroraColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _ExportStat(label: 'Highlights', count: totalHighlights),
                          _ExportStat(label: 'Notes', count: totalNotes),
                          _ExportStat(label: 'Quotes', count: totalQuotes),
                          _ExportStat(label: 'Bookmarks', count: totalBookmarks),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$booksWithData books with exportable data',
                        style: const TextStyle(
                          color: AuroraColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Format selection
                const Text(
                  'EXPORT FORMAT',
                  style: TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ..._formatOptions.map((f) {
                  final id = f['id'] as String;
                  final isSelected = _selectedFormat == id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFormat = id),
                      child: AuroraCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AuroraColors.auroraTeal
                                      : AuroraColors.textTertiary,
                                  width: 2,
                                ),
                                color: isSelected
                                    ? AuroraColors.auroraTeal
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f['label'] as String,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AuroraColors.textPrimary
                                          : AuroraColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    f['desc'] as String,
                                    style: const TextStyle(
                                      color: AuroraColors.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Export button
                SizedBox(
                  width: double.infinity,
                  child: AuroraButton(
                    label: _isExporting ? 'Exporting...' : 'Export All Data',
                    icon: _isExporting ? null : Icons.file_download_rounded,
                    onPressed: _isExporting ? null : _export,
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportStat extends StatelessWidget {
  final String label;
  final int count;

  const _ExportStat({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: AuroraColors.textPrimary,
            fontSize: 16,
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
    );
  }
}
