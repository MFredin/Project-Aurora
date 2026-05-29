import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
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

  final _filters = ['All', 'Reading', 'Finished', 'Want to Read'];

  List<BookModel> _filterAndSort(List<BookModel> allBooks) {
    var books = List<BookModel>.from(allBooks);

    // Filter by status
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

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      books = books
          .where((b) =>
              b.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.author.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort
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
        // Sort by lastOpened (most recent first), then by dateAdded
        books.sort((a, b) {
          final aDate = a.lastOpened ?? a.dateAdded;
          final bDate = b.lastOpened ?? b.dateAdded;
          return bDate.compareTo(aDate);
        });
        break;
    }

    return books;
  }

  Future<void> _importBook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'txt', 'pdf', 'fb2', 'mobi', 'rtf', 'docx'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    final parser = ref.read(bookParserServiceProvider);

    setState(() => _isImporting = true);

    try {
      final parsed = await parser.parseBookFromBytes(
        Uint8List.fromList(file.bytes!),
        file.name,
      );
      ref.read(bookRepositoryProvider.notifier).addParsedBook(parsed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${parsed.metadata.title}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
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

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const Text(
                          'Library',
                          style: TextStyle(
                            color: AuroraColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Grid/List toggle
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isGridView = !_isGridView),
                          child: Icon(
                            _isGridView
                                ? Icons.grid_view_rounded
                                : Icons.view_list_rounded,
                            color: AuroraColors.textSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Sort button
                        PopupMenuButton<_SortOption>(
                          icon: const Icon(
                            Icons.sort_rounded,
                            color: AuroraColors.textSecondary,
                            size: 24,
                          ),
                          color: AuroraColors.surfaceElevated,
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

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AuroraColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 0.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style:
                            const TextStyle(color: AuroraColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Search books...',
                          hintStyle:
                              TextStyle(color: AuroraColors.textTertiary),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: AuroraColors.textTertiary),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter chips
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                  const SizedBox(height: 8),

                  // Book count
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    child: Text(
                      '${books.length} ${books.length == 1 ? 'book' : 'books'}',
                      style: const TextStyle(
                        color: AuroraColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // Book grid/list or empty state
                  Expanded(
                    child: books.isEmpty
                        ? _buildEmptyState()
                        : _isGridView
                            ? _buildGridView(books)
                            : _buildListView(books),
                  ),
                ],
              ),
              // Loading overlay while importing
              if (_isImporting)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                                AuroraColors.auroraTeal),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Importing book...',
                            style: TextStyle(
                              color: AuroraColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: AuroraColors.accentGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AuroraColors.auroraTeal.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _isImporting ? null : _importBook,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child:
                const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(List<BookModel> books) {
    final columns = ResponsiveHelper.gridColumns(context);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.58,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) => _BookGridCard(
        book: books[index],
        onTap: () => context.go('/reader/${books[index].id}'),
      ),
    );
  }

  Widget _buildListView(List<BookModel> books) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _BookListTile(
        book: books[index],
        onTap: () => context.go('/reader/${books[index].id}'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AuroraColors.auroraPurple.withOpacity(0.3),
                  AuroraColors.auroraTeal.withOpacity(0.3),
                ],
              ),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AuroraColors.textTertiary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No books yet',
            style: TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add books from your device\nor browse the Discover tab',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AuroraColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          AuroraButton(
            label: 'Add Your First Book',
            icon: Icons.add_rounded,
            onPressed: _importBook,
          ),
        ],
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

/// Grid card for a single book
class _BookGridCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;
  const _BookGridCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = book.progressPercent;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover with gradient or real image
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: book.coverImageData == null
                    ? AuroraColors.coverGradient(book.title)
                    : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Cover image or fallback gradient text
                  if (book.coverImageData != null)
                    Positioned.fill(
                      child: Image.memory(
                        book.coverImageData!,
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
                              book.title,
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
                            const SizedBox(height: 4),
                            Text(
                              book.author,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
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
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        book.format.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Status indicator
                  if (book.statusLabel == 'finished')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AuroraColors.auroraGreen.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          // Author
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AuroraColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          // Progress bar
          if (progress > 0 && progress < 1.0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: AuroraColors.surface,
                valueColor:
                    const AlwaysStoppedAnimation(AuroraColors.auroraTeal),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: AuroraColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ] else if (progress >= 1.0)
            const Text(
              'Finished',
              style: TextStyle(
                color: AuroraColors.auroraGreen,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

/// List tile for a single book
class _BookListTile extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;
  const _BookListTile({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = book.progressPercent;
    final estimatedPages = book.totalWords ~/ 250;

    return AuroraCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Mini cover
          Container(
            width: 48,
            height: 68,
            decoration: BoxDecoration(
              gradient: book.coverImageData == null
                  ? AuroraColors.coverGradient(book.title)
                  : null,
              borderRadius: BorderRadius.circular(6),
            ),
            clipBehavior: Clip.antiAlias,
            child: book.coverImageData != null
                ? Image.memory(
                    book.coverImageData!,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  style: const TextStyle(
                    color: AuroraColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                if (progress > 0) ...[
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
                  const SizedBox(height: 4),
                  Text(
                    progress >= 1.0
                        ? 'Finished'
                        : '${(progress * 100).toInt()}% complete',
                    style: TextStyle(
                      color: progress >= 1.0
                          ? AuroraColors.auroraGreen
                          : AuroraColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Format + pages
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AuroraColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  book.format.toUpperCase(),
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                estimatedPages > 0
                    ? '$estimatedPages pages'
                    : '${book.chapters.length} ch.',
                style: const TextStyle(
                  color: AuroraColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
