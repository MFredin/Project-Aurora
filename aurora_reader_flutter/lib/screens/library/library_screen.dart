import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../core/layout/responsive.dart';
import '../../core/data/models.dart';
import '../../core/data/book_repository.dart';
import '../../services/parser/book_parser_service.dart';

enum _SortOption { recent, title, author, progress }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _selectedFilter = 'All';
  _SortOption _sortOption = _SortOption.recent;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGridView = true;
  bool _isImporting = false;
  bool _isDragOver = false;
  String _importStatus = '';

  final _filters = ['All', 'Reading', 'Finished', 'Want to Read'];

  static const _supportedExtensions = [
    'epub', 'txt', 'pdf', 'fb2', 'mobi', 'rtf', 'docx',
  ];

  List<BookModel> _filterAndSort(List<BookModel> allBooks) {
    var books = List<BookModel>.from(allBooks);

    switch (_selectedFilter) {
      case 'Reading':
        books = books.where((b) => b.statusLabel == 'reading').toList();
        break;
      case 'Finished':
        books = books.where((b) => b.statusLabel == 'finished').toList();
        break;
      case 'Want to Read':
        books = books.where((b) => b.statusLabel == 'wantToRead').toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      books = books
          .where((b) =>
              b.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.author.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    switch (_sortOption) {
      case _SortOption.title:
        books.sort((a, b) => a.title.compareTo(b.title));
        break;
      case _SortOption.author:
        books.sort((a, b) => a.author.compareTo(b.author));
        break;
      case _SortOption.progress:
        books.sort((a, b) => b.progressPercent.compareTo(a.progressPercent));
        break;
      case _SortOption.recent:
        books.sort((a, b) {
          final aDate = a.lastOpened ?? a.dateAdded;
          final bDate = b.lastOpened ?? b.dateAdded;
          return bDate.compareTo(aDate);
        });
        break;
    }

    return books;
  }

  Future<void> _importBooks() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _supportedExtensions,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    await _processFiles(result.files);
  }

  Future<void> _processFiles(List<PlatformFile> files) async {
    final validFiles = files.where((f) {
      if (f.bytes == null) return false;
      final ext = f.name.split('.').last.toLowerCase();
      return _supportedExtensions.contains(ext);
    }).toList();

    if (validFiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No supported files found')),
        );
      }
      return;
    }

    setState(() {
      _isImporting = true;
      _importStatus = validFiles.length == 1
          ? 'Importing ${validFiles.first.name}...'
          : 'Importing ${validFiles.length} books...';
    });

    final parser = ref.read(bookParserServiceProvider);
    final repo = ref.read(bookRepositoryProvider.notifier);
    int imported = 0;
    int failed = 0;

    for (final file in validFiles) {
      if (mounted && validFiles.length > 1) {
        setState(() {
          _importStatus = 'Importing ${imported + 1} of ${validFiles.length}...';
        });
      }
      try {
        final parsed = await parser.parseBookFromBytes(
          Uint8List.fromList(file.bytes!),
          file.name,
        );
        repo.addParsedBook(parsed);
        imported++;
      } catch (_) {
        failed++;
      }
    }

    if (mounted) {
      setState(() {
        _isImporting = false;
        _importStatus = '';
      });
      final msg = failed > 0
          ? 'Added $imported ${imported == 1 ? 'book' : 'books'}, $failed failed'
          : 'Added $imported ${imported == 1 ? 'book' : 'books'}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AuroraColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showBookDetail(BookModel book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BookDetailSheet(
        book: book,
        onRead: () {
          Navigator.of(context).pop();
          context.push('/reader/${book.id}');
        },
        onDelete: () {
          Navigator.of(context).pop();
          _confirmDelete(book);
        },
      ),
    );
  }

  void _confirmDelete(BookModel book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Book',
            style: TextStyle(color: AuroraColors.textPrimary)),
        content: Text(
          'Remove "${book.title}" from your library? This cannot be undone.',
          style: const TextStyle(color: AuroraColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AuroraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(bookRepositoryProvider.notifier).deleteBook(book.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${book.title}"'),
                  backgroundColor: AuroraColors.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete',
                style: TextStyle(color: AuroraColors.auroraWarm)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allBooks = ref.watch(bookRepositoryProvider);
    final books = _filterAndSort(allBooks);

    Widget body = AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EDDA',
                                style: TextStyle(
                                  color: AuroraColors.auroraTeal.withOpacity(0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4,
                                  fontFamily: 'Georgia',
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Library',
                                style: TextStyle(
                                  color: AuroraColors.textPrimary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _IconButton(
                            icon: Icons.add_rounded,
                            onTap: _isImporting ? () {} : _importBooks,
                          ),
                          const SizedBox(width: 4),
                          _IconButton(
                            icon: _isGridView
                                ? Icons.grid_view_rounded
                                : Icons.view_list_rounded,
                            onTap: () =>
                                setState(() => _isGridView = !_isGridView),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<_SortOption>(
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: AuroraColors.textSecondary,
                              size: 22,
                            ),
                            color: AuroraColors.surfaceElevated,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (option) =>
                                setState(() => _sortOption = option),
                            itemBuilder: (context) => [
                              _buildSortItem(_SortOption.recent, 'Recent'),
                              _buildSortItem(_SortOption.title, 'Title'),
                              _buildSortItem(_SortOption.author, 'Author'),
                              _buildSortItem(_SortOption.progress, 'Progress'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Container(
                            decoration: BoxDecoration(
                              color: AuroraColors.surface.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF252E27),
                                width: 0.5,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              style: const TextStyle(
                                  color: AuroraColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Search books...',
                                hintStyle: const TextStyle(
                                    color: AuroraColors.textTertiary),
                                prefixIcon: const Icon(Icons.search_rounded,
                                    color: AuroraColors.textTertiary, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded,
                                            color: AuroraColors.textTertiary,
                                            size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                    ),
                  ),

                  // Filter chips + count
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filters.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final filter = _filters[index];
                            return AuroraFilterChip(
                              label: filter,
                              isSelected: _selectedFilter == filter,
                              onTap: () =>
                                  setState(() => _selectedFilter = filter),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(
                        '${books.length} ${books.length == 1 ? 'book' : 'books'}',
                        style: const TextStyle(
                          color: AuroraColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  // Content
                  if (books.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState())
                  else if (_isGridView)
                    _buildSliverGrid(books)
                  else
                    _buildSliverList(books),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),

              // Import overlay
              if (_isImporting)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 32),
                            decoration: BoxDecoration(
                              color: AuroraColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF252E27),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation(
                                        AuroraColors.auroraTeal),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _importStatus.isNotEmpty
                                      ? _importStatus
                                      : 'Importing...',
                                  style: const TextStyle(
                                    color: AuroraColors.textPrimary,
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                      ),
                    ),
                  ),
                ),

              // Drag-and-drop overlay
              if (_isDragOver)
                Positioned.fill(
                  child: Container(
                    color: AuroraColors.deepSpace.withOpacity(0.9),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AuroraColors.auroraTeal.withOpacity(0.6),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          color: AuroraColors.auroraTeal.withOpacity(0.05),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    AuroraColors.auroraTeal.withOpacity(0.15),
                              ),
                              child: const Icon(Icons.file_download_rounded,
                                  color: AuroraColors.auroraTeal, size: 36),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Drop books here',
                              style: TextStyle(
                                color: AuroraColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'EPUB, TXT, PDF, and more',
                              style: TextStyle(
                                color: AuroraColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    body = DropTarget(
      onDragEntered: (_) => setState(() => _isDragOver = true),
      onDragExited: (_) => setState(() => _isDragOver = false),
      onDragDone: (details) async {
        setState(() => _isDragOver = false);
        if (_isImporting) return;
        final files = <PlatformFile>[];
        for (final xFile in details.files) {
          final bytes = await xFile.readAsBytes();
          files.add(PlatformFile(
            name: xFile.name,
            size: bytes.length,
            bytes: bytes,
          ));
        }
        if (files.isNotEmpty) _processFiles(files);
      },
      child: body,
    );

    return body;
  }

  Widget _buildSliverGrid(List<BookModel> books) {
    final columns = ResponsiveHelper.gridColumns(context);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 0.55,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _BookGridCard(
            book: books[index],
            onTap: () => context.push('/reader/${books[index].id}'),
            onLongPress: () => _showBookDetail(books[index]),
          ),
          childCount: books.length,
        ),
      ),
    );
  }

  Widget _buildSliverList(List<BookModel> books) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      sliver: SliverList.separated(
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _BookListTile(
          book: books[index],
          onTap: () => context.push('/reader/${books[index].id}'),
          onLongPress: () => _showBookDetail(books[index]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 80,
              child: CustomPaint(
                painter: _RunicKnotPainter(),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Your library is empty',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              kIsWeb
                  ? 'Drag & drop ebook files here\nor tap the button below'
                  : 'Tap the button below to add books',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AuroraColors.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            AuroraButton(
              label: 'Import Books',
              icon: Icons.add_rounded,
              onPressed: _importBooks,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_SortOption> _buildSortItem(
      _SortOption option, String label) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          if (_sortOption == option)
            const Icon(Icons.check_rounded,
                color: AuroraColors.auroraTeal, size: 18)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(color: AuroraColors.textPrimary)),
        ],
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _hovering
                ? Colors.white.withOpacity(0.08)
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            color: _hovering
                ? AuroraColors.textPrimary
                : AuroraColors.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Book detail bottom sheet
class _BookDetailSheet extends StatelessWidget {
  final BookModel book;
  final VoidCallback onRead;
  final VoidCallback onDelete;

  const _BookDetailSheet({
    required this.book,
    required this.onRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = book.progressPercent;
    final estimatedPages = book.totalWords ~/ 250;
    final readMinutes = book.progress.totalReadingSeconds ~/ 60;
    final bottomPad = MediaQuery.of(context).padding.bottom + 80;

    return Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad),
          decoration: BoxDecoration(
            color: AuroraColors.cosmos,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: const Color(0xFF252E27).withOpacity(0.8),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 116,
                    decoration: BoxDecoration(
                      gradient: book.coverImageData == null
                          ? AuroraColors.coverGradient(book.title)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: book.coverImageData != null
                        ? Image.memory(book.coverImageData!,
                            fit: BoxFit.cover)
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                book.title,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AuroraColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          book.author,
                          style: const TextStyle(
                            color: AuroraColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _StatChip(
                              label: book.format.toUpperCase(),
                              icon: Icons.description_outlined,
                            ),
                            if (estimatedPages > 0)
                              _StatChip(
                                label: '$estimatedPages pages',
                                icon: Icons.menu_book_outlined,
                              ),
                            _StatChip(
                              label: '${book.chapters.length} chapters',
                              icon: Icons.list_rounded,
                            ),
                            if (readMinutes > 0)
                              _StatChip(
                                label: '${readMinutes}m read',
                                icon: Icons.schedule_rounded,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (progress > 0) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: AuroraColors.surface,
                          valueColor: const AlwaysStoppedAnimation(
                              AuroraColors.auroraTeal),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      progress >= 1.0
                          ? 'Finished'
                          : '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: progress >= 1.0
                            ? AuroraColors.auroraGreen
                            : AuroraColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AuroraButton(
                      label: progress > 0 ? 'Continue Reading' : 'Start Reading',
                      icon: Icons.auto_stories_rounded,
                      onPressed: onRead,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AuroraColors.auroraWarm.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AuroraColors.auroraWarm.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AuroraColors.auroraWarm,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AuroraColors.textTertiary, size: 14),
        const SizedBox(width: 4),
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

/// Grid card with hover effect
class _BookGridCard extends StatefulWidget {
  final BookModel book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _BookGridCard({
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_BookGridCard> createState() => _BookGridCardState();
}

class _BookGridCardState extends State<_BookGridCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final progress = widget.book.progressPercent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _hovering
              ? (Matrix4.identity()..translate(0.0, -4.0))
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: widget.book.coverImageData == null
                        ? AuroraColors.coverGradient(widget.book.title)
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _hovering
                            ? AuroraColors.auroraTeal.withOpacity(0.2)
                            : Colors.black.withOpacity(0.3),
                        blurRadius: _hovering ? 20 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      if (widget.book.coverImageData != null)
                        Positioned.fill(
                          child: Image.memory(
                            widget.book.coverImageData!,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.book.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                          blurRadius: 8,
                                          color: Colors.black54),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.book.author,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    shadows: const [
                                      Shadow(
                                          blurRadius: 8,
                                          color: Colors.black54),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Format badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.book.format.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                        ),
                      ),
                      if (widget.book.statusLabel == 'finished')
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  AuroraColors.auroraGreen.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      // Progress overlay at bottom
                      if (progress > 0 && progress < 1.0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: AuroraColors.surface.withOpacity(0.5),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: AuroraColors.accentGradient,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List tile for a single book
class _BookListTile extends StatefulWidget {
  final BookModel book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _BookListTile({
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_BookListTile> createState() => _BookListTileState();
}

class _BookListTileState extends State<_BookListTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final progress = widget.book.progressPercent;
    final estimatedPages = widget.book.totalWords ~/ 250;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovering
                ? AuroraColors.surface.withOpacity(0.7)
                : AuroraColors.surface.withOpacity(0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovering
                  ? const Color(0xFF354038)
                  : const Color(0xFF252E27),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 68,
                decoration: BoxDecoration(
                  gradient: widget.book.coverImageData == null
                      ? AuroraColors.coverGradient(widget.book.title)
                      : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.book.coverImageData != null
                    ? Image.memory(widget.book.coverImageData!,
                        fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.book.author,
                      style: const TextStyle(
                        color: AuroraColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (progress > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: AuroraColors.surface,
                          valueColor: const AlwaysStoppedAnimation(
                              AuroraColors.auroraTeal),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AuroraColors.surfaceElevated.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.book.format.toUpperCase(),
                      style: const TextStyle(
                        color: AuroraColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    estimatedPages > 0
                        ? '$estimatedPages pg'
                        : '${widget.book.chapters.length} ch',
                    style: const TextStyle(
                      color: AuroraColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunicKnotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final ember = Paint()
      ..color = AuroraColors.auroraTeal.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final lichen = Paint()
      ..color = AuroraColors.auroraGreen.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final spine = Path()
      ..moveTo(w * 0.2, h * 0.05)
      ..lineTo(w * 0.2, h * 0.95);
    canvas.drawPath(spine, ember);

    final topArm = Path()
      ..moveTo(w * 0.2, h * 0.05)
      ..cubicTo(w * 0.5, h * 0.05, w * 0.65, h * 0.0, w * 0.85, h * 0.08)
      ..cubicTo(w * 0.92, h * 0.11, w * 0.88, h * 0.20, w * 0.78, h * 0.18);
    canvas.drawPath(topArm, ember);

    final midArm = Path()
      ..moveTo(w * 0.2, h * 0.48)
      ..cubicTo(w * 0.45, h * 0.48, w * 0.55, h * 0.42, w * 0.72, h * 0.45)
      ..cubicTo(w * 0.82, h * 0.47, w * 0.80, h * 0.55, w * 0.68, h * 0.53);
    canvas.drawPath(midArm, ember);

    final botArm = Path()
      ..moveTo(w * 0.2, h * 0.95)
      ..cubicTo(w * 0.5, h * 0.95, w * 0.65, h * 1.0, w * 0.85, h * 0.92)
      ..cubicTo(w * 0.92, h * 0.89, w * 0.88, h * 0.80, w * 0.78, h * 0.82);
    canvas.drawPath(botArm, ember);

    final topLoop = Path()
      ..moveTo(w * 0.78, h * 0.18)
      ..cubicTo(w * 0.68, h * 0.16, w * 0.65, h * 0.22, w * 0.72, h * 0.25)
      ..cubicTo(w * 0.80, h * 0.28, w * 0.85, h * 0.22, w * 0.78, h * 0.18);
    canvas.drawPath(topLoop, lichen);

    final midLoop = Path()
      ..moveTo(w * 0.68, h * 0.53)
      ..cubicTo(w * 0.58, h * 0.51, w * 0.55, h * 0.57, w * 0.62, h * 0.60)
      ..cubicTo(w * 0.70, h * 0.63, w * 0.75, h * 0.57, w * 0.68, h * 0.53);
    canvas.drawPath(midLoop, lichen);

    final botLoop = Path()
      ..moveTo(w * 0.78, h * 0.82)
      ..cubicTo(w * 0.68, h * 0.84, w * 0.65, h * 0.78, w * 0.72, h * 0.75)
      ..cubicTo(w * 0.80, h * 0.72, w * 0.85, h * 0.78, w * 0.78, h * 0.82);
    canvas.drawPath(botLoop, lichen);

    final dot = Paint()..color = AuroraColors.auroraTeal.withOpacity(0.5);
    canvas.drawCircle(Offset(w * 0.2, h * 0.03), 2.5, dot);
    canvas.drawCircle(Offset(w * 0.2, h * 0.97), 2.5, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
