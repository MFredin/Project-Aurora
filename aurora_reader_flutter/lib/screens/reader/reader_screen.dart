import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';
import '../../core/data/book_repository.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;

  const ReaderScreen({super.key, required this.bookId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  int _currentChapter = 0;
  double _fontSize = 18.0;
  double _brightness = 1.0;
  bool _isScrollMode = true;
  bool _showToolbar = true;
  bool _showSettings = false;
  final ScrollController _scrollController = ScrollController();
  double _readingProgress = 0.0;
  bool _restoredProgress = false;

  // Reading time tracking
  final Stopwatch _stopwatch = Stopwatch();

  // Selection / highlight state
  String? _selectedText;
  Color _highlightColor = AuroraColors.auroraTeal;

  final _highlightColors = <Color>[
    AuroraColors.auroraTeal,
    AuroraColors.auroraGreen,
    AuroraColors.auroraBlue,
    AuroraColors.auroraPurple,
    AuroraColors.auroraPink,
    AuroraColors.auroraWarm,
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateProgress);
    _stopwatch.start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    // Save reading time
    ref.read(bookRepositoryProvider.notifier).addReadingTime(
          widget.bookId,
          _stopwatch.elapsed.inSeconds,
        );
    // Save current progress
    _saveProgress();
    _scrollController.removeListener(_updateProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _saveProgress() {
    ref.read(bookRepositoryProvider.notifier).updateProgress(
          widget.bookId,
          _currentChapter,
          _readingProgress,
        );
  }

  void _updateProgress() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      setState(() {
        _readingProgress = _scrollController.offset / maxScroll;
      });
    }
  }

  void _nextChapter(BookModel book) {
    if (_currentChapter < book.chapters.length - 1) {
      _saveProgress();
      setState(() {
        _currentChapter++;
        _readingProgress = 0;
      });
      _scrollController.jumpTo(0);
    }
  }

  void _previousChapter() {
    if (_currentChapter > 0) {
      _saveProgress();
      setState(() {
        _currentChapter--;
        _readingProgress = 0;
      });
      _scrollController.jumpTo(0);
    }
  }

  KeyEventResult _handleKeyEvent(
      FocusNode node, KeyEvent event, BookModel book) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.pageUp) {
      _previousChapter();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.pageDown) {
      _nextChapter(book);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(bookByIdProvider(widget.bookId));

    // Handle null book (invalid bookId)
    if (book == null) {
      return Scaffold(
        backgroundColor: AuroraColors.deepSpace,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AuroraColors.textTertiary,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Book not found',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The requested book could not be loaded.',
                style: TextStyle(
                  color: AuroraColors.textTertiary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuroraColors.auroraTeal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Restore reading position once
    if (!_restoredProgress) {
      _currentChapter =
          book.progress.currentChapter.clamp(0, book.chapters.length - 1);
      _restoredProgress = true;
    }

    final currentContent = book.chapters[_currentChapter].content;
    final currentTitle = book.chapters[_currentChapter].title;
    final isMobile = ResponsiveHelper.isMobile(context);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(node, event, book),
      child: Scaffold(
        backgroundColor: AuroraColors.deepSpace.withOpacity(_brightness),
        body: SafeArea(
          child: Stack(
            children: [
              // Reading content area
              GestureDetector(
                onTap: () => setState(() => _showToolbar = !_showToolbar),
                child: Column(
                  children: [
                    // Top progress bar
                    _buildProgressBar(book),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isMobile ? double.infinity : 720,
                            ),
                            child: SelectableText(
                              currentContent,
                              style: TextStyle(
                                color: AuroraColors.textPrimary
                                    .withOpacity(0.9 * _brightness),
                                fontSize: _fontSize,
                                height: 1.75,
                                fontFamily: 'Georgia',
                              ),
                              onSelectionChanged: (selection, cause) {
                                if (selection.baseOffset !=
                                    selection.extentOffset) {
                                  final text = currentContent.substring(
                                    selection.baseOffset,
                                    selection.extentOffset,
                                  );
                                  setState(() => _selectedText = text);
                                } else {
                                  setState(() => _selectedText = null);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation tap zones (left/right thirds)
              if (!_isScrollMode) ...[
                // Left tap zone - previous page
                Positioned(
                  left: 0,
                  top: 60,
                  bottom: 80,
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: GestureDetector(
                    onTap: _previousChapter,
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Right tap zone - next page
                Positioned(
                  right: 0,
                  top: 60,
                  bottom: 80,
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: GestureDetector(
                    onTap: () => _nextChapter(book),
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],

              // Top app bar
              if (_showToolbar) _buildTopBar(book, currentTitle),

              // Bottom toolbar
              if (_showToolbar) _buildBottomToolbar(book),

              // Settings panel
              if (_showSettings) _buildSettingsPanel(),

              // Highlight toolbar (appears when text is selected)
              if (_selectedText != null && _selectedText!.isNotEmpty)
                _buildHighlightToolbar(book),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BookModel book) {
    final totalProgress =
        (_currentChapter + _readingProgress) / book.chapters.length;
    return Container(
      height: 3,
      width: double.infinity,
      color: AuroraColors.surface,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: totalProgress.clamp(0.0, 1.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AuroraColors.accentGradient,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BookModel book, String currentTitle) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AuroraColors.deepSpace,
              AuroraColors.deepSpace.withOpacity(0.0),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AuroraColors.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${book.title} • Chapter ${_currentChapter + 1} of ${book.chapters.length}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AuroraColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border_rounded,
                  color: AuroraColors.auroraTeal),
              onPressed: () {
                final content = book.chapters[_currentChapter].content;
                ref.read(bookRepositoryProvider.notifier).addBookmark(
                      widget.bookId,
                      BookmarkModel(
                        id: UniqueKey().toString(),
                        bookId: widget.bookId,
                        title: 'Chapter ${_currentChapter + 1}',
                        chapter: _currentChapter,
                        textSnippet: content.length > 100
                            ? content.substring(0, 100)
                            : content,
                        dateCreated: DateTime.now(),
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark added')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted_rounded,
                  color: AuroraColors.textSecondary),
              onPressed: () => _showChapterList(book),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar(BookModel book) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AuroraColors.deepSpace,
              AuroraColors.deepSpace.withOpacity(0.0),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous chapter
            _ToolbarButton(
              icon: Icons.chevron_left_rounded,
              label: 'Prev',
              onTap: _currentChapter > 0 ? _previousChapter : null,
            ),
            // Font size
            _ToolbarButton(
              icon: Icons.text_fields_rounded,
              label: 'Font',
              onTap: () => setState(() => _showSettings = !_showSettings),
            ),
            // Brightness
            _ToolbarButton(
              icon: Icons.brightness_6_rounded,
              label: 'Light',
              onTap: () {
                setState(() {
                  _brightness = _brightness == 1.0 ? 0.7 : 1.0;
                });
              },
            ),
            // Scroll/Page mode
            _ToolbarButton(
              icon: _isScrollMode
                  ? Icons.swap_horiz_rounded
                  : Icons.swap_vert_rounded,
              label: _isScrollMode ? 'Scroll' : 'Page',
              onTap: () => setState(() => _isScrollMode = !_isScrollMode),
            ),
            // Next chapter
            _ToolbarButton(
              icon: Icons.chevron_right_rounded,
              label: 'Next',
              onTap: _currentChapter < book.chapters.length - 1
                  ? () => _nextChapter(book)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Positioned(
      bottom: 70,
      left: 0,
      right: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AuroraCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Font size
                  Row(
                    children: [
                      const Icon(Icons.text_fields_rounded,
                          color: AuroraColors.auroraTeal, size: 20),
                      const SizedBox(width: 12),
                      const Text('Font Size',
                          style: TextStyle(color: AuroraColors.textPrimary)),
                      const Spacer(),
                      Text(
                        '${_fontSize.toInt()}',
                        style: const TextStyle(
                          color: AuroraColors.auroraTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 12,
                    max: 32,
                    divisions: 20,
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                  const SizedBox(height: 12),

                  // Brightness
                  Row(
                    children: [
                      const Icon(Icons.brightness_6_rounded,
                          color: AuroraColors.auroraTeal, size: 20),
                      const SizedBox(width: 12),
                      const Text('Brightness',
                          style: TextStyle(color: AuroraColors.textPrimary)),
                      const Spacer(),
                      Text(
                        '${(_brightness * 100).toInt()}%',
                        style: const TextStyle(
                          color: AuroraColors.auroraTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _brightness,
                    min: 0.3,
                    max: 1.0,
                    divisions: 14,
                    onChanged: (v) => setState(() => _brightness = v),
                  ),
                  const SizedBox(height: 8),

                  // Theme presets
                  const Text('Reading Theme',
                      style: TextStyle(
                          color: AuroraColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ThemePreset(
                          label: 'Dark',
                          bg: AuroraColors.deepSpace,
                          fg: AuroraColors.textPrimary,
                          isSelected: true),
                      _ThemePreset(
                          label: 'Sepia',
                          bg: const Color(0xFF3B2F1E),
                          fg: const Color(0xFFE8D5B5),
                          isSelected: false),
                      _ThemePreset(
                          label: 'Light',
                          bg: const Color(0xFFF5F5F0),
                          fg: const Color(0xFF2A2A2A),
                          isSelected: false),
                      _ThemePreset(
                          label: 'Green',
                          bg: const Color(0xFF0D2818),
                          fg: const Color(0xFFA8E6C3),
                          isSelected: false),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightToolbar(BookModel book) {
    return Positioned(
      bottom: 70,
      left: 24,
      right: 24,
      child: AuroraCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Color options
            ..._highlightColors.map((color) {
              final isSelected = _highlightColor == color;
              return GestureDetector(
                onTap: () => setState(() => _highlightColor = color),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                ),
              );
            }),
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 28,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(width: 8),
            // Highlight action
            IconButton(
              icon: const Icon(Icons.highlight_rounded,
                  color: AuroraColors.auroraTeal),
              onPressed: () {
                if (_selectedText != null) {
                  ref.read(bookRepositoryProvider.notifier).addHighlight(
                        widget.bookId,
                        HighlightModel(
                          id: UniqueKey().toString(),
                          bookId: widget.bookId,
                          highlightedText: _selectedText!,
                          chapterIndex: _currentChapter,
                          dateCreated: DateTime.now(),
                        ),
                      );
                }
                setState(() => _selectedText = null);
              },
              tooltip: 'Highlight',
            ),
            // Note action
            IconButton(
              icon: const Icon(Icons.note_add_rounded,
                  color: AuroraColors.auroraBlue),
              onPressed: () {
                // Add note to highlight
                setState(() => _selectedText = null);
              },
              tooltip: 'Add Note',
            ),
            // Copy action
            IconButton(
              icon: const Icon(Icons.copy_rounded,
                  color: AuroraColors.textSecondary),
              onPressed: () {
                if (_selectedText != null) {
                  Clipboard.setData(ClipboardData(text: _selectedText!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
                setState(() => _selectedText = null);
              },
              tooltip: 'Copy',
            ),
          ],
        ),
      ),
    );
  }

  void _showChapterList(BookModel book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuroraColors.surfaceElevated,
      constraints: BoxConstraints(
        maxWidth: ResponsiveHelper.isMobile(context)
            ? double.infinity
            : 500,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AuroraColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chapters',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(book.chapters.length, (index) {
                final isActive = index == _currentChapter;
                return ListTile(
                  leading: Icon(
                    isActive
                        ? Icons.play_circle_fill_rounded
                        : Icons.circle_outlined,
                    color: isActive
                        ? AuroraColors.auroraTeal
                        : AuroraColors.textTertiary,
                    size: 20,
                  ),
                  title: Text(
                    book.chapters[index].title,
                    style: TextStyle(
                      color: isActive
                          ? AuroraColors.auroraTeal
                          : AuroraColors.textPrimary,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    _saveProgress();
                    setState(() {
                      _currentChapter = index;
                      _readingProgress = 0;
                    });
                    _scrollController.jumpTo(0);
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ToolbarButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: enabled
                  ? AuroraColors.textPrimary
                  : AuroraColors.textTertiary,
              size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: enabled
                  ? AuroraColors.textSecondary
                  : AuroraColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreset extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final bool isSelected;

  const _ThemePreset({
    required this.label,
    required this.bg,
    required this.fg,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AuroraColors.auroraTeal : Colors.white12,
              width: isSelected ? 2 : 0.5,
            ),
          ),
          child: Center(
            child: Text('Aa', style: TextStyle(color: fg, fontSize: 18)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color:
                isSelected ? AuroraColors.auroraTeal : AuroraColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
