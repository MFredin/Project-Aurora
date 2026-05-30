import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../core/data/models.dart';
import '../../core/data/book_repository.dart';

const _uuid = Uuid();

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  final _reviewController = TextEditingController();
  final _tagController = TextEditingController();
  bool _reviewPrivate = false;
  bool _reviewDirty = false;

  @override
  void dispose() {
    _reviewController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _syncReviewController(BookModel book) {
    if (!_reviewDirty && _reviewController.text != book.review) {
      _reviewController.text = book.review;
      _reviewPrivate = book.reviewIsPrivate;
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _setStatus(ReadingStatus status) {
    ref.read(bookRepositoryProvider.notifier).setReadingStatus(widget.bookId, status);
  }

  void _setRating(double? rating) {
    ref.read(bookRepositoryProvider.notifier).setRating(widget.bookId, rating);
  }

  void _setMoods(List<String> moods) {
    ref.read(bookRepositoryProvider.notifier).setMoods(widget.bookId, moods);
  }

  void _setPace(ReadingPace? pace) {
    ref.read(bookRepositoryProvider.notifier).setPace(widget.bookId, pace);
  }

  void _setFormatType(BookFormatType? formatType) {
    ref.read(bookRepositoryProvider.notifier).setBookFormatType(widget.bookId, formatType);
  }

  void _saveReview() {
    ref.read(bookRepositoryProvider.notifier).setReview(
      widget.bookId,
      _reviewController.text,
      isPrivate: _reviewPrivate,
    );
    setState(() => _reviewDirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review saved'),
        backgroundColor: AuroraColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;
    final book = ref.read(bookByIdProvider(widget.bookId));
    if (book == null) return;
    if (book.customTags.contains(tag)) {
      _tagController.clear();
      return;
    }
    ref.read(bookRepositoryProvider.notifier).setCustomTags(
      widget.bookId,
      [...book.customTags, tag],
    );
    _tagController.clear();
  }

  void _removeTag(String tag) {
    final book = ref.read(bookByIdProvider(widget.bookId));
    if (book == null) return;
    ref.read(bookRepositoryProvider.notifier).setCustomTags(
      widget.bookId,
      book.customTags.where((t) => t != tag).toList(),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final book = ref.read(bookByIdProvider(widget.bookId));
    if (book == null) return;
    final initial = isStart ? book.startDate : book.finishDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AuroraColors.auroraTeal,
              onPrimary: Colors.white,
              surface: AuroraColors.surfaceElevated,
              onSurface: AuroraColors.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AuroraColors.surfaceElevated,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    if (isStart) {
      ref.read(bookRepositoryProvider.notifier).setDates(
        widget.bookId,
        startDate: picked,
        finishDate: book.finishDate,
      );
    } else {
      ref.read(bookRepositoryProvider.notifier).setDates(
        widget.bookId,
        startDate: book.startDate,
        finishDate: picked,
      );
    }
  }

  void _addReadingNote(BookModel book) {
    final noteController = TextEditingController();
    final chapterController = TextEditingController(
      text: book.progress.currentChapter.toString(),
    );
    final progressValue = (book.progressPercent * 100).toStringAsFixed(0);
    final progressController = TextEditingController(text: progressValue);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Reading Note',
            style: TextStyle(color: AuroraColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteController,
                maxLines: 4,
                style: const TextStyle(color: AuroraColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Your thoughts...',
                  hintStyle: const TextStyle(color: AuroraColors.textTertiary),
                  filled: true,
                  fillColor: AuroraColors.surface.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: chapterController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AuroraColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Chapter',
                        labelStyle: const TextStyle(color: AuroraColors.textSecondary),
                        filled: true,
                        fillColor: AuroraColors.surface.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: progressController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AuroraColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Progress %',
                        labelStyle: const TextStyle(color: AuroraColors.textSecondary),
                        filled: true,
                        fillColor: AuroraColors.surface.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AuroraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final text = noteController.text.trim();
              if (text.isEmpty) return;
              final chapter = int.tryParse(chapterController.text) ?? 0;
              final pct = double.tryParse(progressController.text) ?? 0;
              ref.read(bookRepositoryProvider.notifier).addReadingNote(
                widget.bookId,
                ReadingNoteModel(
                  id: _uuid.v4(),
                  bookId: widget.bookId,
                  chapterIndex: chapter,
                  progressPercent: pct.clamp(0, 100),
                  note: text,
                  dateCreated: DateTime.now(),
                ),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Add',
                style: TextStyle(color: AuroraColors.auroraTeal)),
          ),
        ],
      ),
    );
  }

  void _deleteNote(String noteId) {
    ref.read(bookRepositoryProvider.notifier).removeReadingNote(widget.bookId, noteId);
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
              if (context.mounted) context.pop();
            },
            child: const Text('Delete',
                style: TextStyle(color: AuroraColors.auroraWarm)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(bookByIdProvider(widget.bookId));
    if (book == null) {
      return Scaffold(
        backgroundColor: AuroraColors.deepSpace,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Book not found',
                  style: TextStyle(color: AuroraColors.textPrimary, fontSize: 18)),
              const SizedBox(height: 16),
              AuroraButton(
                label: 'Go Back',
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      );
    }

    _syncReviewController(book);

    final progress = book.progressPercent;
    final estimatedPages = book.totalWords ~/ 250;
    final dateFmt = DateFormat('MMM d, yyyy');

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top bar
              _buildTopBar(book),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildCoverSection(book, estimatedPages),
                      const SizedBox(height: 24),
                      _buildSectionDivider(),
                      const SizedBox(height: 16),
                      _buildStatusSelector(book),
                      const SizedBox(height: 20),
                      _buildSectionDivider(),
                      const SizedBox(height: 16),
                      _buildRatingSection(book),
                      const SizedBox(height: 20),
                      _buildSectionDivider(),
                      const SizedBox(height: 16),
                      _buildMoodSection(book),
                      const SizedBox(height: 20),
                      _buildSectionDivider(),
                      const SizedBox(height: 16),
                      _buildPaceSection(book),
                      const SizedBox(height: 20),
                      _buildSectionDivider(),
                      const SizedBox(height: 16),
                      _buildFormatSection(book),
                      const SizedBox(height: 20),
                      _buildSectionDivider(),
                      const SizedBox(height: 16),
                      _buildCustomTagsSection(book),
                      const SizedBox(height: 20),
                      _buildSectionDivider(),
                      const SizedBox(height: 16),
                      _buildReviewSection(book),
                      const SizedBox(height: 20),
                      _buildSectionDivider(),
                      const SizedBox(height: 16),
                      _buildReadingNotesSection(book, dateFmt),
                      const SizedBox(height: 20),
                      _buildSectionDivider(),
                      const SizedBox(height: 16),
                      _buildHighlightsSection(book, dateFmt),
                      const SizedBox(height: 20),
                      _buildSectionDivider(),
                      const SizedBox(height: 16),
                      _buildDatesSection(book, dateFmt),
                      const SizedBox(height: 24),
                      // Read button
                      SizedBox(
                        width: double.infinity,
                        child: AuroraButton(
                          label: progress > 0
                              ? 'Continue Reading'
                              : 'Start Reading',
                          icon: Icons.auto_stories_rounded,
                          onPressed: () =>
                              context.push('/reader/${widget.bookId}'),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(BookModel book) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AuroraColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AuroraColors.textSecondary),
            color: AuroraColors.surfaceElevated,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'delete') _confirmDelete(book);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: AuroraColors.auroraWarm, size: 20),
                    SizedBox(width: 8),
                    Text('Delete Book',
                        style: TextStyle(color: AuroraColors.auroraWarm)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cover & Info
  // ---------------------------------------------------------------------------

  Widget _buildCoverSection(BookModel book, int estimatedPages) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover
        Container(
          width: 110,
          height: 160,
          decoration: BoxDecoration(
            gradient: book.coverImageData == null
                ? AuroraColors.coverGradient(book.title)
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: book.coverImageData != null
              ? Image.memory(book.coverImageData!, fit: BoxFit.cover)
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      book.title,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(blurRadius: 8, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 16),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book.author,
                style: const TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _InfoBadge(
                    icon: Icons.description_outlined,
                    label: book.format.toUpperCase(),
                  ),
                  if (estimatedPages > 0)
                    _InfoBadge(
                      icon: Icons.menu_book_outlined,
                      label: '$estimatedPages pages',
                    ),
                  _InfoBadge(
                    icon: Icons.list_rounded,
                    label: '${book.chapters.length} chapters',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Reading Status
  // ---------------------------------------------------------------------------

  Widget _buildStatusSelector(BookModel book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Reading Status'),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ReadingStatus.values.map((status) {
              final isActive = book.readingStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _setStatus(status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AuroraColors.auroraTeal
                          : AuroraColors.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: isActive
                          ? null
                          : Border.all(
                              color: const Color(0xFF252E27),
                              width: 0.5,
                            ),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFFF0E8D8)
                            : AuroraColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Star Rating (quarter-star precision)
  // ---------------------------------------------------------------------------

  Widget _buildRatingSection(BookModel book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Rating'),
        const SizedBox(height: 10),
        Row(
          children: [
            _QuarterStarRating(
              rating: book.rating ?? 0,
              onRatingChanged: (value) {
                if (book.rating != null && book.rating == value) {
                  _setRating(null);
                } else {
                  _setRating(value);
                }
              },
            ),
            const SizedBox(width: 12),
            if (book.rating != null)
              Text(
                book.rating!.toStringAsFixed(
                    book.rating! == book.rating!.roundToDouble() ? 1 : 2),
                style: const TextStyle(
                  color: AuroraColors.manuscriptGold,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mood Tags
  // ---------------------------------------------------------------------------

  Widget _buildMoodSection(BookModel book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Mood'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BookMood.all.map((mood) {
            final selected = book.moods.contains(mood);
            return GestureDetector(
              onTap: () {
                final updated = selected
                    ? book.moods.where((m) => m != mood).toList()
                    : [...book.moods, mood];
                _setMoods(updated);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AuroraColors.auroraTeal.withOpacity(0.15)
                      : AuroraColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? AuroraColors.auroraTeal.withOpacity(0.5)
                        : const Color(0xFF252E27),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  mood[0].toUpperCase() + mood.substring(1),
                  style: TextStyle(
                    color: selected
                        ? AuroraColors.auroraTeal
                        : AuroraColors.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Pace
  // ---------------------------------------------------------------------------

  Widget _buildPaceSection(BookModel book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Pace'),
        const SizedBox(height: 10),
        Row(
          children: ReadingPace.values.map((pace) {
            final isActive = book.pace == pace;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AuroraFilterChip(
                label: pace.label,
                isSelected: isActive,
                onTap: () => _setPace(isActive ? null : pace),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Format Type
  // ---------------------------------------------------------------------------

  Widget _buildFormatSection(BookModel book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Format'),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: BookFormatType.values.map((fmt) {
              final isActive = book.bookFormatType == fmt;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AuroraFilterChip(
                  label: fmt.label,
                  isSelected: isActive,
                  onTap: () => _setFormatType(isActive ? null : fmt),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Custom Tags
  // ---------------------------------------------------------------------------

  Widget _buildCustomTagsSection(BookModel book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Tags'),
        const SizedBox(height: 10),
        if (book.customTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.customTags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AuroraColors.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF252E27),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: const TextStyle(
                          color: AuroraColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeTag(tag),
                        child: const Icon(Icons.close_rounded,
                            color: AuroraColors.textTertiary, size: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AuroraColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF252E27),
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: _tagController,
                  style: const TextStyle(color: AuroraColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Add a tag...',
                    hintStyle: TextStyle(color: AuroraColors.textTertiary),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addTag,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AuroraColors.auroraTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AuroraColors.auroraTeal.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AuroraColors.auroraTeal, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Review
  // ---------------------------------------------------------------------------

  Widget _buildReviewSection(BookModel book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Review'),
        const SizedBox(height: 10),
        AuroraCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _reviewController,
                maxLines: 5,
                style: const TextStyle(
                    color: AuroraColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Write your review...',
                  hintStyle: TextStyle(color: AuroraColors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) {
                  if (!_reviewDirty) setState(() => _reviewDirty = true);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _reviewPrivate = !_reviewPrivate),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _reviewPrivate
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          color: AuroraColors.textTertiary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _reviewPrivate ? 'Private' : 'Public',
                          style: const TextStyle(
                            color: AuroraColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AuroraButton(
                    label: 'Save',
                    compact: true,
                    onPressed: _reviewDirty ||
                            _reviewController.text != book.review ||
                            _reviewPrivate != book.reviewIsPrivate
                        ? _saveReview
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Reading Notes
  // ---------------------------------------------------------------------------

  Widget _buildReadingNotesSection(BookModel book, DateFormat dateFmt) {
    final notes = List<ReadingNoteModel>.from(book.readingNotes)
      ..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionHeader('Reading Notes'),
            const Spacer(),
            GestureDetector(
              onTap: () => _addReadingNote(book),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AuroraColors.auroraTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AuroraColors.auroraTeal, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (notes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No reading notes yet.',
              style:
                  TextStyle(color: AuroraColors.textTertiary, fontSize: 13),
            ),
          )
        else
          ...notes.map((note) {
            final chapterLabel = note.chapterIndex < book.chapters.length
                ? book.chapters[note.chapterIndex].title
                : 'Chapter ${note.chapterIndex}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AuroraCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.note,
                      style: const TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.list_rounded,
                            color: AuroraColors.textTertiary, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            chapterLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AuroraColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${note.progressPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AuroraColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFmt.format(note.dateCreated),
                          style: const TextStyle(
                            color: AuroraColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _deleteNote(note.id),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: AuroraColors.textTertiary, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Highlights
  // ---------------------------------------------------------------------------

  Widget _buildHighlightsSection(BookModel book, DateFormat dateFmt) {
    final highlights = List<HighlightModel>.from(book.highlights)
      ..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Highlights'),
        const SizedBox(height: 10),
        if (highlights.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No highlights yet.',
              style:
                  TextStyle(color: AuroraColors.textTertiary, fontSize: 13),
            ),
          )
        else
          ...highlights.map((h) {
            final color = _highlightColorFromName(h.colorName);
            final chapterLabel = h.chapterIndex < book.chapters.length
                ? book.chapters[h.chapterIndex].title
                : 'Chapter ${h.chapterIndex}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AuroraCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.highlightedText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AuroraColors.textPrimary,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chapterLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AuroraColors.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateFmt.format(h.dateCreated),
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
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Dates
  // ---------------------------------------------------------------------------

  Widget _buildDatesSection(BookModel book, DateFormat dateFmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Dates'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DateCard(
                label: 'Started',
                date: book.startDate,
                dateFmt: dateFmt,
                onTap: () => _pickDate(isStart: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateCard(
                label: 'Finished',
                date: book.finishDate,
                dateFmt: dateFmt,
                onTap: () => _pickDate(isStart: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AuroraColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Divider(color: const Color(0xFF252E27).withOpacity(0.6));
  }

  static Color _highlightColorFromName(String name) {
    switch (name) {
      case 'auroraTeal':
        return AuroraColors.auroraTeal;
      case 'auroraGreen':
        return AuroraColors.auroraGreen;
      case 'auroraBlue':
        return AuroraColors.auroraBlue;
      case 'auroraPurple':
        return AuroraColors.auroraPurple;
      case 'auroraPink':
        return AuroraColors.auroraPink;
      case 'auroraWarm':
        return AuroraColors.auroraWarm;
      default:
        return AuroraColors.auroraTeal;
    }
  }
}

// =============================================================================
// Quarter-Star Rating Widget
// =============================================================================

class _QuarterStarRating extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;

  const _QuarterStarRating({
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTapUp: (details) {
            final box = context.findRenderObject() as RenderBox;
            // Each star is 32 wide
            final starWidth = 32.0;
            final localX = details.localPosition.dx - (index * starWidth);
            final fraction = (localX / starWidth).clamp(0.0, 1.0);

            // Snap to nearest 0.25
            final quarterStep = (fraction * 4).round() / 4;
            final value =
                (index + quarterStep).clamp(0.0, 5.0);
            onRatingChanged(value == 0 ? 0.25 : value);
          },
          child: SizedBox(
            width: 32,
            height: 32,
            child: _QuarterStar(
              fillFraction: (rating - index).clamp(0.0, 1.0),
            ),
          ),
        );
      }),
    );
  }
}

class _QuarterStar extends StatelessWidget {
  final double fillFraction;

  const _QuarterStar({required this.fillFraction});

  @override
  Widget build(BuildContext context) {
    if (fillFraction <= 0) {
      return const Icon(Icons.star_border_rounded,
          color: AuroraColors.textTertiary, size: 28);
    }
    if (fillFraction >= 1) {
      return const Icon(Icons.star_rounded,
          color: AuroraColors.manuscriptGold, size: 28);
    }

    // Partial fill: use ShaderMask to clip the star icon
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: const [
            AuroraColors.manuscriptGold,
            AuroraColors.manuscriptGold,
            Colors.transparent,
            Colors.transparent,
          ],
          stops: [
            0.0,
            fillFraction,
            fillFraction,
            1.0,
          ],
        ).createShader(bounds);
      },
      child: const Icon(Icons.star_rounded,
          color: AuroraColors.textTertiary, size: 28),
    );
  }
}

// =============================================================================
// Small utility widgets
// =============================================================================

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge({required this.icon, required this.label});

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

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  const _DateCard({
    required this.label,
    required this.date,
    required this.dateFmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AuroraCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AuroraColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: AuroraColors.textSecondary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    date != null ? dateFmt.format(date!) : 'Not set',
                    style: TextStyle(
                      color: date != null
                          ? AuroraColors.textPrimary
                          : AuroraColors.textTertiary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
