import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../core/data/social_models.dart';
import '../../core/data/social_repository.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _showRecommendDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Recommend a Book',
          style: TextStyle(color: AuroraColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(titleController, 'Book title'),
              const SizedBox(height: 12),
              _buildDialogField(authorController, 'Author'),
              const SizedBox(height: 12),
              _buildDialogField(noteController, 'Personal note (optional)',
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AuroraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  authorController.text.isNotEmpty) {
                ref.read(socialRepositoryProvider.notifier).addRecommendation(
                      BookRecommendation(
                        id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
                        fromUserId: 'user_self',
                        fromUserName: 'You',
                        bookTitle: titleController.text,
                        bookAuthor: authorController.text,
                        personalNote: noteController.text,
                        createdAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recommendation shared!')),
                );
              }
            },
            child: const Text('Share',
                style: TextStyle(color: AuroraColors.auroraTeal)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AuroraColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AuroraColors.textTertiary),
        filled: true,
        fillColor: AuroraColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(socialFeedProvider);

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Social',
              style: TextStyle(color: AuroraColors.textPrimary)),
          actions: [
            IconButton(
              icon: const Icon(Icons.group_rounded,
                  color: AuroraColors.textSecondary),
              tooltip: 'Book Clubs',
              onPressed: () => context.push('/clubs'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AuroraColors.auroraTeal,
          onPressed: _showRecommendDialog,
          child:
              const Icon(Icons.auto_stories_rounded, color: Color(0xFFF0E8D8)),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: feed.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: AuroraColors.auroraTeal,
                    backgroundColor: AuroraColors.surface,
                    onRefresh: _onRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: feed.length,
                      itemBuilder: (context, index) =>
                          _FeedItemCard(item: feed[index]),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                color: AuroraColors.textTertiary.withOpacity(0.5), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Follow readers to see their activity',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuroraColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When people you follow rate, review, or finish books, it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuroraColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedItemCard extends StatefulWidget {
  final ActivityFeedItem item;

  const _FeedItemCard({required this.item});

  @override
  State<_FeedItemCard> createState() => _FeedItemCardState();
}

class _FeedItemCardState extends State<_FeedItemCard> {
  bool _expanded = false;

  IconData _activityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.finishedBook:
        return Icons.check_circle_rounded;
      case ActivityType.startedBook:
        return Icons.auto_stories_rounded;
      case ActivityType.ratedBook:
        return Icons.star_rounded;
      case ActivityType.reviewedBook:
        return Icons.rate_review_rounded;
      case ActivityType.addedToShelf:
        return Icons.bookmark_add_rounded;
      case ActivityType.highlight:
        return Icons.format_quote_rounded;
    }
  }

  Color _activityColor(ActivityType type) {
    switch (type) {
      case ActivityType.finishedBook:
        return AuroraColors.auroraGreen;
      case ActivityType.startedBook:
        return AuroraColors.auroraTeal;
      case ActivityType.ratedBook:
        return AuroraColors.manuscriptGold;
      case ActivityType.reviewedBook:
        return AuroraColors.auroraPurple;
      case ActivityType.addedToShelf:
        return AuroraColors.auroraTeal;
      case ActivityType.highlight:
        return AuroraColors.manuscriptGold;
    }
  }

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AuroraCard(
        padding: const EdgeInsets.all(14),
        onTap: item.detail != null
            ? () => setState(() => _expanded = !_expanded)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AuroraColors.coverGradient(item.userName),
                  ),
                  child: Center(
                    child: Text(
                      item.userName.isNotEmpty
                          ? item.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: item.userName,
                              style: const TextStyle(
                                color: AuroraColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: ' ${item.type.label} ',
                              style: const TextStyle(
                                color: AuroraColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            _activityIcon(item.type),
                            color: _activityColor(item.type),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.bookTitle,
                              style: const TextStyle(
                                color: AuroraColors.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.bookAuthor != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Text(
                            'by ${item.bookAuthor}',
                            style: const TextStyle(
                              color: AuroraColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (item.type == ActivityType.ratedBook &&
                          item.detail != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 20, top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AuroraColors.manuscriptGold, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                item.detail!,
                                style: const TextStyle(
                                  color: AuroraColors.manuscriptGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Timestamp
                Text(
                  _timeAgo(item.timestamp),
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            // Expandable detail
            if (_expanded && item.detail != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AuroraColors.deepSpace.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.detail!,
                  style: TextStyle(
                    color: AuroraColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                    fontStyle: item.type == ActivityType.highlight
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ],
            if (item.detail != null && !_expanded)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Tap to read more',
                  style: TextStyle(
                    color: AuroraColors.textTertiary.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
