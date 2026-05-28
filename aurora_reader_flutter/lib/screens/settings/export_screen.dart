import 'package:flutter/material.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _selectedContent = <String>{'library', 'highlights', 'bookmarks'};
  String _selectedFormat = 'json';
  bool _isExporting = false;

  final _contentOptions = [
    {'id': 'library', 'label': 'Library', 'icon': Icons.library_books_rounded, 'count': '42 books'},
    {'id': 'highlights', 'label': 'Highlights', 'icon': Icons.highlight_rounded, 'count': '128 highlights'},
    {'id': 'bookmarks', 'label': 'Bookmarks', 'icon': Icons.bookmark_rounded, 'count': '47 bookmarks'},
    {'id': 'stats', 'label': 'Reading Stats', 'icon': Icons.insights_rounded, 'count': '6 months'},
    {'id': 'vocabulary', 'label': 'Vocabulary', 'icon': Icons.translate_rounded, 'count': '23 words'},
    {'id': 'notes', 'label': 'Notes', 'icon': Icons.note_rounded, 'count': '15 notes'},
  ];

  final _formatOptions = [
    {'id': 'json', 'label': 'JSON', 'desc': 'Structured data, ideal for backups'},
    {'id': 'csv', 'label': 'CSV', 'desc': 'Spreadsheet compatible'},
    {'id': 'markdown', 'label': 'Markdown', 'desc': 'Human-readable format'},
  ];

  @override
  Widget build(BuildContext context) {
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
            // Content selection
            const Text(
              'SELECT CONTENT',
              style: TextStyle(
                color: AuroraColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ..._contentOptions.map((opt) {
              final id = opt['id'] as String;
              final isSelected = _selectedContent.contains(id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: AuroraCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedContent.remove(id);
                      } else {
                        _selectedContent.add(id);
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        opt['icon'] as IconData,
                        color: isSelected
                            ? AuroraColors.auroraTeal
                            : AuroraColors.textTertiary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['label'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? AuroraColors.textPrimary
                                    : AuroraColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              opt['count'] as String,
                              style: const TextStyle(
                                color: AuroraColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: isSelected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedContent.add(id);
                            } else {
                              _selectedContent.remove(id);
                            }
                          });
                        },
                        activeColor: AuroraColors.auroraTeal,
                      ),
                    ],
                  ),
                ),
              );
            }),
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
            Row(
              children: _formatOptions.map((f) {
                final id = f['id'] as String;
                final isSelected = _selectedFormat == id;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: f != _formatOptions.last ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFormat = id),
                      child: AuroraCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              f['label'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? AuroraColors.auroraTeal
                                    : AuroraColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              f['desc'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AuroraColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: 20,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AuroraColors.auroraTeal,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Export summary
            AuroraCard(
              child: Column(
                children: [
                  const Icon(Icons.file_download_rounded,
                      color: AuroraColors.auroraTeal, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedContent.length} categories selected',
                    style: const TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Format: ${_selectedFormat.toUpperCase()}',
                    style: const TextStyle(
                      color: AuroraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Export button
            SizedBox(
              width: double.infinity,
              child: AuroraButton(
                label: _isExporting ? 'Exporting...' : 'Export',
                icon: _isExporting ? null : Icons.share_rounded,
                onPressed: _selectedContent.isEmpty || _isExporting
                    ? null
                    : () {
                        setState(() => _isExporting = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() => _isExporting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Export complete!'),
                                backgroundColor:
                                    AuroraColors.surfaceElevated,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        });
                      },
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
