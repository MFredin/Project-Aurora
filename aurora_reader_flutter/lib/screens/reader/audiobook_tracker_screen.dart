import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/data/audiobook_models.dart';
import '../../core/data/book_repository.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

// ── Audiobook Repository ────────────────────────────────────────────────────

const _audiobookKey = 'audiobook_progress';

class AudiobookRepository
    extends Notifier<Map<String, AudiobookProgress>> {
  Box get _box => Hive.box('aurora_reader');

  @override
  Map<String, AudiobookProgress> build() {
    final result = <String, AudiobookProgress>{};
    for (final key in _box.keys) {
      final keyStr = key as String;
      if (!keyStr.startsWith('${_audiobookKey}_')) continue;
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        final progress = AudiobookProgress.fromJson(
            jsonDecode(raw as String) as Map<String, dynamic>);
        result[progress.bookId] = progress;
      } catch (_) {}
    }
    return result;
  }

  void _persist(AudiobookProgress progress) {
    _box.put(
        '${_audiobookKey}_${progress.bookId}', jsonEncode(progress.toJson()));
    state = {...state, progress.bookId: progress};
  }

  void initProgress({
    required String bookId,
    required Duration totalDuration,
  }) {
    _persist(AudiobookProgress(
      bookId: bookId,
      totalDuration: totalDuration,
      lastListened: DateTime.now(),
    ));
  }

  void updatePosition(String bookId, Duration position) {
    final p = state[bookId];
    if (p == null) return;
    _persist(p.copyWith(
      currentPosition: position,
      lastListened: DateTime.now(),
    ));
  }

  void updateChapter(String bookId, int chapter) {
    final p = state[bookId];
    if (p == null) return;
    _persist(p.copyWith(currentChapter: chapter));
  }

  void updatePlaybackSpeed(String bookId, double speed) {
    final p = state[bookId];
    if (p == null) return;
    _persist(p.copyWith(playbackSpeed: speed));
  }

  void updateTotalDuration(String bookId, Duration duration) {
    final p = state[bookId];
    if (p == null) return;
    _persist(p.copyWith(totalDuration: duration));
  }

  void addNote(String bookId, AudiobookNote note) {
    final p = state[bookId];
    if (p == null) return;
    _persist(p.copyWith(notes: [...p.notes, note]));
  }

  void removeNote(String bookId, String noteId) {
    final p = state[bookId];
    if (p == null) return;
    _persist(p.copyWith(
      notes: p.notes.where((n) => n.id != noteId).toList(),
    ));
  }
}

final audiobookRepositoryProvider =
    NotifierProvider<AudiobookRepository, Map<String, AudiobookProgress>>(
        AudiobookRepository.new);

// ── Screen ──────────────────────────────────────────────────────────────────

class AudiobookTrackerScreen extends ConsumerStatefulWidget {
  final String bookId;

  const AudiobookTrackerScreen({super.key, required this.bookId});

  @override
  ConsumerState<AudiobookTrackerScreen> createState() =>
      _AudiobookTrackerScreenState();
}

class _AudiobookTrackerScreenState
    extends ConsumerState<AudiobookTrackerScreen> {
  // Duration input controllers
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();

  // Note input
  final _noteController = TextEditingController();

  // Session timer
  Timer? _sessionTimer;
  int _sessionSeconds = 0;
  bool _sessionRunning = false;

  // Setup mode
  bool _isSetup = false;
  final _setupHoursController = TextEditingController();
  final _setupMinutesController = TextEditingController();

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _noteController.dispose();
    _setupHoursController.dispose();
    _setupMinutesController.dispose();
    super.dispose();
  }

  void _startSessionTimer() {
    setState(() => _sessionRunning = true);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _sessionSeconds++);
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    setState(() => _sessionRunning = false);
  }

  void _resetSessionTimer() {
    _stopSessionTimer();
    setState(() => _sessionSeconds = 0);
  }

  String _formatTimer(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _logPosition() {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    final position = Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
    ref
        .read(audiobookRepositoryProvider.notifier)
        .updatePosition(widget.bookId, position);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Position updated')),
    );
  }

  void _addNote() {
    final noteText = _noteController.text.trim();
    if (noteText.isEmpty) return;

    final progress =
        ref.read(audiobookRepositoryProvider)[widget.bookId];
    final timestamp = progress?.currentPosition ?? Duration.zero;

    ref.read(audiobookRepositoryProvider.notifier).addNote(
          widget.bookId,
          AudiobookNote.create(
            timestamp: timestamp,
            note: noteText,
          ),
        );

    _noteController.clear();
  }

  void _setupAudiobook() {
    final hours = int.tryParse(_setupHoursController.text) ?? 0;
    final minutes = int.tryParse(_setupMinutesController.text) ?? 0;
    if (hours == 0 && minutes == 0) return;

    ref.read(audiobookRepositoryProvider.notifier).initProgress(
          bookId: widget.bookId,
          totalDuration: Duration(hours: hours, minutes: minutes),
        );

    setState(() => _isSetup = false);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(
        audiobookRepositoryProvider.select((m) => m[widget.bookId]));
    final book = ref.watch(bookByIdProvider(widget.bookId));
    final bookTitle = book?.title ?? 'Audiobook';

    // Show setup if no progress exists
    if (progress == null) {
      return _buildSetupScreen(bookTitle);
    }

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(bookTitle,
              style: const TextStyle(color: AuroraColors.textPrimary)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AuroraColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.contentMaxWidth(context)),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Progress Overview ─────────────────────────────────
                _buildProgressCard(progress),
                const SizedBox(height: 16),

                // ── Log Position ──────────────────────────────────────
                _buildPositionInput(progress),
                const SizedBox(height: 16),

                // ── Chapter & Speed ───────────────────────────────────
                _buildChapterAndSpeed(progress),
                const SizedBox(height: 16),

                // ── Session Timer ─────────────────────────────────────
                _buildSessionTimer(),
                const SizedBox(height: 16),

                // ── Notes ─────────────────────────────────────────────
                _buildNotesSection(progress),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupScreen(String bookTitle) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(bookTitle,
              style: const TextStyle(color: AuroraColors.textPrimary)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AuroraColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.headphones_rounded,
                      color: AuroraColors.auroraTeal, size: 64),
                  const SizedBox(height: 20),
                  const Text(
                    'Track Your Audiobook',
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set the total duration of your audiobook to start tracking progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AuroraColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AuroraCard(
                    child: Column(
                      children: [
                        const Text(
                          'Total Duration',
                          style: TextStyle(
                            color: AuroraColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTimeInput(
                                _setupHoursController, 'Hours', 99),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(':',
                                  style: TextStyle(
                                    color: AuroraColors.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                            _buildTimeInput(
                                _setupMinutesController, 'Min', 59),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: AuroraButton(
                            label: 'Start Tracking',
                            icon: Icons.play_arrow_rounded,
                            onPressed: _setupAudiobook,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(AudiobookProgress progress) {
    return AuroraCard(
      child: Column(
        children: [
          // Progress bar
          Row(
            children: [
              const Icon(Icons.headphones_rounded,
                  color: AuroraColors.auroraTeal, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Listening Progress',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress.progressPercent * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AuroraColors.auroraTeal,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.progressPercent,
              minHeight: 8,
              backgroundColor: AuroraColors.surface,
              valueColor:
                  const AlwaysStoppedAnimation(AuroraColors.auroraTeal),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoLabel('Position', progress.formattedPosition),
              _buildInfoLabel('Total', progress.formattedTotal),
              _buildInfoLabel('Remaining', progress.formattedRemaining),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoLabel('Chapter', '${progress.currentChapter}'),
              _buildInfoLabel('Speed', '${progress.playbackSpeed}x'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLabel(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AuroraColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
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

  Widget _buildPositionInput(AudiobookProgress progress) {
    // Pre-fill with current position
    if (_hoursController.text.isEmpty && progress.currentPosition.inSeconds > 0) {
      _hoursController.text = '${progress.currentPosition.inHours}';
      _minutesController.text =
          '${progress.currentPosition.inMinutes.remainder(60)}';
      _secondsController.text =
          '${progress.currentPosition.inSeconds.remainder(60)}';
    }

    return AuroraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Log Current Position',
            style: TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTimeInput(_hoursController, 'H', 99),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(':',
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              _buildTimeInput(_minutesController, 'M', 59),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(':',
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              _buildTimeInput(_secondsController, 'S', 59),
              const SizedBox(width: 12),
              AuroraButton(
                label: 'Log',
                compact: true,
                onPressed: _logPosition,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput(
      TextEditingController controller, String hint, int max) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AuroraColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AuroraColors.textTertiary,
            fontSize: 16,
          ),
          filled: true,
          fillColor: AuroraColors.surface.withOpacity(0.5),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildChapterAndSpeed(AudiobookProgress progress) {
    final speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0];

    return Row(
      children: [
        // Chapter
        Expanded(
          child: AuroraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chapter',
                  style: TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded,
                          color: AuroraColors.textSecondary, size: 20),
                      onPressed: progress.currentChapter > 1
                          ? () => ref
                              .read(audiobookRepositoryProvider.notifier)
                              .updateChapter(
                                  widget.bookId, progress.currentChapter - 1)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        '${progress.currentChapter}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AuroraColors.auroraTeal,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded,
                          color: AuroraColors.textSecondary, size: 20),
                      onPressed: () => ref
                          .read(audiobookRepositoryProvider.notifier)
                          .updateChapter(
                              widget.bookId, progress.currentChapter + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Playback speed
        Expanded(
          child: AuroraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Playback Speed',
                  style: TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<double>(
                  value: speeds.contains(progress.playbackSpeed)
                      ? progress.playbackSpeed
                      : 1.0,
                  dropdownColor: AuroraColors.surfaceElevated,
                  style: const TextStyle(
                    color: AuroraColors.auroraTeal,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AuroraColors.surface.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: speeds
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s}x'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref
                          .read(audiobookRepositoryProvider.notifier)
                          .updatePlaybackSpeed(widget.bookId, v);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionTimer() {
    return AuroraCard(
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.timer_rounded,
                  color: AuroraColors.manuscriptGold, size: 20),
              SizedBox(width: 8),
              Text(
                'Listening Session Timer',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatTimer(_sessionSeconds),
            style: const TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 40,
              fontWeight: FontWeight.w300,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_sessionRunning)
                AuroraButton(
                  label: _sessionSeconds > 0 ? 'Resume' : 'Start',
                  icon: Icons.play_arrow_rounded,
                  compact: true,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A9E8F), Color(0xFF3D7A6D)],
                  ),
                  onPressed: _startSessionTimer,
                )
              else
                AuroraButton(
                  label: 'Pause',
                  icon: Icons.pause_rounded,
                  compact: true,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB87944), Color(0xFF9A6338)],
                  ),
                  onPressed: _stopSessionTimer,
                ),
              if (_sessionSeconds > 0) ...[
                const SizedBox(width: 12),
                AuroraButton(
                  label: 'Reset',
                  icon: Icons.stop_rounded,
                  compact: true,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A4A3A), Color(0xFF4A3A2A)],
                  ),
                  onPressed: _resetSessionTimer,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(AudiobookProgress progress) {
    return AuroraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.note_add_rounded,
                  color: AuroraColors.auroraGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Timestamped Notes',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Add note input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  style: const TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a note at ${progress.formattedPosition}...',
                    hintStyle: const TextStyle(
                      color: AuroraColors.textTertiary,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AuroraColors.surface.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _addNote(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_rounded,
                    color: AuroraColors.auroraGreen),
                onPressed: _addNote,
              ),
            ],
          ),

          // Notes list
          if (progress.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF252E27), height: 1),
            const SizedBox(height: 8),
            ...progress.notes.reversed.map((note) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AuroraColors.auroraGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        note.formattedTimestamp,
                        style: const TextStyle(
                          color: AuroraColors.auroraGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        note.note,
                        style: const TextStyle(
                          color: AuroraColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref
                          .read(audiobookRepositoryProvider.notifier)
                          .removeNote(widget.bookId, note.id),
                      child: const Icon(Icons.close_rounded,
                          color: AuroraColors.textTertiary, size: 16),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
