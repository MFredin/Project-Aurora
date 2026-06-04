import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../core/data/social_models.dart';
import '../../core/data/social_repository.dart';

class BookClubScreen extends ConsumerStatefulWidget {
  const BookClubScreen({super.key});

  @override
  ConsumerState<BookClubScreen> createState() => _BookClubScreenState();
}

class _BookClubScreenState extends ConsumerState<BookClubScreen> {
  void _showCreateClubDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Create Book Club',
          style: TextStyle(color: AuroraColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(nameController, 'Club name'),
              const SizedBox(height: 12),
              _buildField(descController, 'Description', maxLines: 3),
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
              if (nameController.text.isNotEmpty) {
                final club = BookClubModel(
                  id: 'club_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  description: descController.text.isNotEmpty
                      ? descController.text
                      : 'A new book club',
                  creatorId: 'user_self',
                  memberIds: ['user_self'],
                  memberCount: 1,
                  createdAt: DateTime.now(),
                );
                ref
                    .read(socialRepositoryProvider.notifier)
                    .createClub(club);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create',
                style: TextStyle(color: AuroraColors.auroraTeal)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint,
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
    final clubs = ref.watch(socialClubsProvider);

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Book Clubs',
              style: TextStyle(color: AuroraColors.textPrimary)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AuroraColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // Create club button
                AuroraCard(
                  onTap: _showCreateClubDialog,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AuroraColors.auroraTeal.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: AuroraColors.auroraTeal, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create a Book Club',
                              style: TextStyle(
                                color: AuroraColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Start reading together with friends',
                              style: TextStyle(
                                color: AuroraColors.textTertiary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AuroraColors.textTertiary),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (clubs.isEmpty)
                  _buildEmptyState()
                else ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Your Clubs',
                      style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...clubs.map((club) => _ClubCard(club: club)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.groups_outlined,
              color: AuroraColors.textTertiary.withOpacity(0.5), size: 56),
          const SizedBox(height: 16),
          const Text(
            'No clubs yet',
            style: TextStyle(
              color: AuroraColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create a club or join one to start reading together.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AuroraColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubCard extends ConsumerWidget {
  final BookClubModel club;

  const _ClubCard({required this.club});

  double _scheduleProgress(BookClubSchedule schedule) {
    final now = DateTime.now();
    final total = schedule.endDate.difference(schedule.startDate).inDays;
    final elapsed = now.difference(schedule.startDate).inDays;
    if (total <= 0) return 0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AuroraCard(
        padding: const EdgeInsets.all(16),
        onTap: () => context.push('/club/${club.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Club icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: AuroraColors.coverGradient(club.name),
                  ),
                  child: const Center(
                    child: Icon(Icons.menu_book_rounded,
                        color: Colors.white70, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club.name,
                        style: const TextStyle(
                          color: AuroraColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.people_rounded,
                              color: AuroraColors.textTertiary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${club.memberCount} members',
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
                const Icon(Icons.chevron_right_rounded,
                    color: AuroraColors.textTertiary),
              ],
            ),
            if (club.currentBookTitle != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AuroraColors.deepSpace.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AuroraColors.coverGradient(
                            club.currentBookTitle!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Currently Reading',
                            style: TextStyle(
                              color: AuroraColors.textTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            club.currentBookTitle!,
                            style: const TextStyle(
                              color: AuroraColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          if (club.currentBookAuthor != null)
                            Text(
                              club.currentBookAuthor!,
                              style: const TextStyle(
                                color: AuroraColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          if (club.schedule != null) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: _scheduleProgress(club.schedule!),
                                minHeight: 3,
                                backgroundColor: AuroraColors.surface,
                                valueColor: const AlwaysStoppedAnimation(
                                    AuroraColors.auroraGreen),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
