import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../core/data/social_models.dart';
import '../../core/data/social_repository.dart';

class ClubDetailScreen extends ConsumerStatefulWidget {
  final String clubId;

  const ClubDetailScreen({super.key, required this.clubId});

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final club = ref.watch(clubByIdProvider(widget.clubId));

    if (club == null) {
      return AuroraBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AuroraColors.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          body: const Center(
            child: Text('Club not found',
                style: TextStyle(color: AuroraColors.textSecondary)),
          ),
        ),
      );
    }

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(club.name,
              style: const TextStyle(color: AuroraColors.textPrimary)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AuroraColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AuroraColors.auroraTeal,
            labelColor: AuroraColors.auroraTeal,
            unselectedLabelColor: AuroraColors.textTertiary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Discussions'),
              Tab(text: 'Vote'),
              Tab(text: 'Members'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(club: club),
                _DiscussionsTab(clubId: widget.clubId),
                _VoteTab(clubId: widget.clubId),
                _MembersTab(club: club),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Overview Tab ---

class _OverviewTab extends StatelessWidget {
  final BookClubModel club;

  const _OverviewTab({required this.club});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description
        AuroraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                club.description,
                style: const TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Current book
        if (club.currentBookTitle != null) ...[
          AuroraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Currently Reading',
                  style: TextStyle(
                    color: AuroraColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AuroraColors.coverGradient(
                            club.currentBookTitle!),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.menu_book_rounded,
                            color: Colors.white70, size: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            club.currentBookTitle!,
                            style: const TextStyle(
                              color: AuroraColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (club.currentBookAuthor != null)
                            Text(
                              'by ${club.currentBookAuthor}',
                              style: const TextStyle(
                                color: AuroraColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          if (club.schedule != null) ...[
                            const SizedBox(height: 8),
                            _buildScheduleProgress(club.schedule!),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Reading schedule milestones
        if (club.schedule != null) ...[
          AuroraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AuroraColors.auroraGreen, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Reading Schedule',
                      style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${club.schedule!.chaptersPerWeek} chapters per week',
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ...club.schedule!.milestones
                    .map((m) => _buildMilestoneRow(m)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildScheduleProgress(BookClubSchedule schedule) {
    final now = DateTime.now();
    final total = schedule.endDate.difference(schedule.startDate).inDays;
    final elapsed = now.difference(schedule.startDate).inDays;
    final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;

    // Find next milestone
    String nextMilestoneText = '';
    for (final m in schedule.milestones) {
      if (m.dueDate.isAfter(now)) {
        final daysLeft = m.dueDate.difference(now).inDays;
        nextMilestoneText =
            'Week ${m.weekNumber}: Ch. ${m.startChapter}-${m.endChapter} due in ${daysLeft}d';
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AuroraColors.surface,
            valueColor:
                const AlwaysStoppedAnimation(AuroraColors.auroraGreen),
          ),
        ),
        if (nextMilestoneText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            nextMilestoneText,
            style: const TextStyle(
              color: AuroraColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMilestoneRow(BookClubMilestone milestone) {
    final now = DateTime.now();
    final isPast = milestone.dueDate.isBefore(now);
    final isCurrent = !isPast &&
        (milestone.dueDate.difference(now).inDays < 7);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPast
                  ? AuroraColors.auroraGreen.withOpacity(0.2)
                  : isCurrent
                      ? AuroraColors.auroraTeal.withOpacity(0.2)
                      : AuroraColors.surface,
              border: isCurrent
                  ? Border.all(color: AuroraColors.auroraTeal, width: 1.5)
                  : null,
            ),
            child: Center(
              child: isPast
                  ? const Icon(Icons.check_rounded,
                      color: AuroraColors.auroraGreen, size: 14)
                  : Text(
                      '${milestone.weekNumber}',
                      style: TextStyle(
                        color: isCurrent
                            ? AuroraColors.auroraTeal
                            : AuroraColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chapters ${milestone.startChapter} - ${milestone.endChapter}',
              style: TextStyle(
                color: isPast
                    ? AuroraColors.textTertiary
                    : AuroraColors.textPrimary,
                fontSize: 13,
                decoration:
                    isPast ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ),
          Text(
            _formatDate(milestone.dueDate),
            style: TextStyle(
              color: isCurrent
                  ? AuroraColors.auroraTeal
                  : AuroraColors.textTertiary,
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// --- Discussions Tab ---

class _DiscussionsTab extends ConsumerStatefulWidget {
  final String clubId;

  const _DiscussionsTab({required this.clubId});

  @override
  ConsumerState<_DiscussionsTab> createState() => _DiscussionsTabState();
}

class _DiscussionsTabState extends ConsumerState<_DiscussionsTab> {
  // Simulated user's current chapter progress
  final int _userCurrentChapter = 7;

  void _showNewThreadDialog() {
    final titleController = TextEditingController();
    int chapterGate = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AuroraColors.surfaceElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'New Discussion',
            style: TextStyle(color: AuroraColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AuroraColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Discussion title',
                    hintStyle:
                        const TextStyle(color: AuroraColors.textTertiary),
                    filled: true,
                    fillColor: AuroraColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        color: AuroraColors.textTertiary, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Spoiler gate: Chapter',
                      style: TextStyle(
                        color: AuroraColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AuroraColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButton<int>(
                        value: chapterGate,
                        dropdownColor: AuroraColors.surfaceElevated,
                        underline: const SizedBox(),
                        style: const TextStyle(
                            color: AuroraColors.textPrimary, fontSize: 13),
                        items: List.generate(
                          25,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text('${i + 1}'),
                          ),
                        ),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => chapterGate = v);
                          }
                        },
                      ),
                    ),
                  ],
                ),
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
                if (titleController.text.isNotEmpty) {
                  ref.read(socialRepositoryProvider.notifier).addThread(
                        DiscussionThreadModel(
                          id: 'thread_${DateTime.now().millisecondsSinceEpoch}',
                          clubId: widget.clubId,
                          title: titleController.text,
                          chapterGate: chapterGate,
                          authorId: 'user_self',
                          authorName: 'You',
                          createdAt: DateTime.now(),
                        ),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Post',
                  style: TextStyle(color: AuroraColors.auroraTeal)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final threads = ref.watch(clubThreadsProvider(widget.clubId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${threads.length} discussions',
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
              AuroraButton(
                label: 'New Thread',
                icon: Icons.add_rounded,
                compact: true,
                onPressed: _showNewThreadDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: threads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.forum_outlined,
                          color: AuroraColors.textTertiary.withOpacity(0.5),
                          size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'No discussions yet',
                        style: TextStyle(
                            color: AuroraColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Start a conversation about the book!',
                        style: TextStyle(
                            color: AuroraColors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: threads.length,
                  itemBuilder: (context, index) {
                    final thread = threads[index];
                    final isSpoiler =
                        thread.chapterGate > _userCurrentChapter;

                    return _ThreadCard(
                      thread: thread,
                      isSpoiler: isSpoiler,
                      userChapter: _userCurrentChapter,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ThreadCard extends StatefulWidget {
  final DiscussionThreadModel thread;
  final bool isSpoiler;
  final int userChapter;

  const _ThreadCard({
    required this.thread,
    required this.isSpoiler,
    required this.userChapter,
  });

  @override
  State<_ThreadCard> createState() => _ThreadCardState();
}

class _ThreadCardState extends State<_ThreadCard> {
  bool _expanded = false;
  bool _spoilerAcknowledged = false;

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AuroraCard(
        padding: const EdgeInsets.all(14),
        onTap: () {
          if (widget.isSpoiler && !_spoilerAcknowledged) {
            _showSpoilerWarning();
          } else {
            setState(() => _expanded = !_expanded);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isSpoiler && !_spoilerAcknowledged)
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AuroraColors.auroraWarm, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Spoilers: Chapter ${thread.chapterGate}+',
                              style: const TextStyle(
                                color: AuroraColors.auroraWarm,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      if (widget.isSpoiler && !_spoilerAcknowledged)
                        const SizedBox(height: 4),
                      Text(
                        widget.isSpoiler && !_spoilerAcknowledged
                            ? 'Hidden discussion (tap to reveal)'
                            : thread.title,
                        style: TextStyle(
                          color: widget.isSpoiler && !_spoilerAcknowledged
                              ? AuroraColors.textTertiary
                              : AuroraColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontStyle: widget.isSpoiler && !_spoilerAcknowledged
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            thread.authorName,
                            style: const TextStyle(
                              color: AuroraColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(thread.createdAt),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AuroraColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: AuroraColors.textTertiary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${thread.replyCount}',
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
            // Expanded replies
            if (_expanded && thread.replies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xFF252E27).withOpacity(0.6),
              ),
              const SizedBox(height: 8),
              ...thread.replies.map((reply) => Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient:
                                AuroraColors.coverGradient(reply.authorName),
                          ),
                          child: Center(
                            child: Text(
                              reply.authorName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    reply.authorName,
                                    style: const TextStyle(
                                      color: AuroraColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _timeAgo(reply.createdAt),
                                    style: const TextStyle(
                                      color: AuroraColors.textTertiary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reply.content,
                                style: const TextStyle(
                                  color: AuroraColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _showSpoilerWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AuroraColors.auroraWarm, size: 22),
            SizedBox(width: 8),
            Text(
              'Spoiler Warning',
              style: TextStyle(color: AuroraColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          'This discussion contains spoilers for Chapter ${widget.thread.chapterGate} and beyond. '
          'You are currently on Chapter ${widget.userChapter}.\n\n'
          'Do you want to continue?',
          style: const TextStyle(
            color: AuroraColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Go back',
                style: TextStyle(color: AuroraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _spoilerAcknowledged = true;
                _expanded = true;
              });
            },
            child: const Text('Show anyway',
                style: TextStyle(color: AuroraColors.auroraWarm)),
          ),
        ],
      ),
    );
  }
}

// --- Vote Tab ---

class _VoteTab extends ConsumerWidget {
  final String clubId;

  const _VoteTab({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final votes = ref.watch(clubVotesProvider(clubId));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Icon(Icons.how_to_vote_rounded,
                  color: AuroraColors.auroraGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Vote for the Next Book',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Ranked by community votes. Tap to cast your vote.',
            style: TextStyle(
              color: AuroraColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: votes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.how_to_vote_outlined,
                          color: AuroraColors.textTertiary.withOpacity(0.5),
                          size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'No candidates yet',
                        style: TextStyle(
                            color: AuroraColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: votes.length,
                  itemBuilder: (context, index) {
                    final vote = votes[index];
                    final hasVoted = vote.voterIds.contains('user_self');
                    final maxVotes = votes.isNotEmpty
                        ? votes
                            .map((v) => v.voteCount)
                            .reduce((a, b) => a > b ? a : b)
                        : 1;
                    final barWidth =
                        maxVotes > 0 ? vote.voteCount / maxVotes : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AuroraCard(
                        padding: const EdgeInsets.all(14),
                        onTap: () {
                          if (hasVoted) {
                            ref
                                .read(socialRepositoryProvider.notifier)
                                .removeVote(vote.id, 'user_self');
                          } else {
                            ref
                                .read(socialRepositoryProvider.notifier)
                                .castVote(vote.id, 'user_self');
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Rank number
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == 0
                                        ? AuroraColors.manuscriptGold
                                            .withOpacity(0.2)
                                        : AuroraColors.surface,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: index == 0
                                            ? AuroraColors.manuscriptGold
                                            : AuroraColors.textTertiary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vote.bookTitle,
                                        style: const TextStyle(
                                          color: AuroraColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        vote.bookAuthor,
                                        style: const TextStyle(
                                          color: AuroraColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Vote button
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: hasVoted
                                        ? AuroraColors.auroraGreen
                                            .withOpacity(0.2)
                                        : AuroraColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: hasVoted
                                          ? AuroraColors.auroraGreen
                                          : const Color(0xFF252E27),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        hasVoted
                                            ? Icons.thumb_up_rounded
                                            : Icons.thumb_up_outlined,
                                        color: hasVoted
                                            ? AuroraColors.auroraGreen
                                            : AuroraColors.textTertiary,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${vote.voteCount}',
                                        style: TextStyle(
                                          color: hasVoted
                                              ? AuroraColors.auroraGreen
                                              : AuroraColors.textTertiary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: barWidth,
                                minHeight: 3,
                                backgroundColor:
                                    AuroraColors.surface.withOpacity(0.5),
                                valueColor: AlwaysStoppedAnimation(
                                  index == 0
                                      ? AuroraColors.manuscriptGold
                                      : AuroraColors.auroraGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// --- Members Tab ---

class _MembersTab extends StatelessWidget {
  final BookClubModel club;

  const _MembersTab({required this.club});

  @override
  Widget build(BuildContext context) {
    // Demo member data
    final members = <Map<String, dynamic>>[
      {
        'name': 'You',
        'role': 'Member',
        'progress': 0.35,
        'chapter': 7,
      },
      if (club.memberIds.contains('user_alice'))
        {
          'name': 'Alice Thornberry',
          'role': club.creatorId == 'user_alice' ? 'Creator' : 'Member',
          'progress': 0.55,
          'chapter': 12,
        },
      if (club.memberIds.contains('user_bob'))
        {
          'name': 'Bob Navarro',
          'role': 'Member',
          'progress': 0.40,
          'chapter': 9,
        },
      if (club.memberIds.contains('user_clara'))
        {
          'name': 'Clara Whitfield',
          'role': club.creatorId == 'user_clara' ? 'Creator' : 'Member',
          'progress': 0.80,
          'chapter': 18,
        },
      if (club.memberIds.contains('user_dex'))
        {
          'name': 'Dex Morales',
          'role': 'Member',
          'progress': 0.20,
          'chapter': 4,
        },
      if (club.memberIds.contains('user_emma'))
        {
          'name': 'Emma Sato',
          'role': 'Member',
          'progress': 0.65,
          'chapter': 14,
        },
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AuroraCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AuroraColors.coverGradient(
                        member['name'] as String),
                  ),
                  child: Center(
                    child: Text(
                      (member['name'] as String)[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member['name'] as String,
                            style: const TextStyle(
                              color: AuroraColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (member['role'] == 'Creator') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AuroraColors.manuscriptGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Creator',
                                style: TextStyle(
                                  color: AuroraColors.manuscriptGold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: member['progress'] as double,
                                minHeight: 4,
                                backgroundColor: AuroraColors.surface,
                                valueColor: const AlwaysStoppedAnimation(
                                    AuroraColors.auroraGreen),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ch. ${member['chapter']}',
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
              ],
            ),
          ),
        );
      },
    );
  }
}
