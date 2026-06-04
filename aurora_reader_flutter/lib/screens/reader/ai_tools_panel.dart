import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../providers/service_providers.dart';
import '../../services/ai/ai_reading_tools.dart';

/// A bottom sheet panel that exposes AI reading tools within the reader.
///
/// Provides: Story So Far, Character Tracker, Ask a Question,
/// Content Warnings, and Discussion Questions.
class AiToolsPanel extends ConsumerStatefulWidget {
  final BookModel book;

  const AiToolsPanel({super.key, required this.book});

  @override
  ConsumerState<AiToolsPanel> createState() => _AiToolsPanelState();

  /// Show the AI tools panel as a modal bottom sheet.
  static void show(BuildContext context, BookModel book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuroraColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _AiToolsPanelContent(
          book: book,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _AiToolsPanelState extends ConsumerState<AiToolsPanel> {
  @override
  Widget build(BuildContext context) {
    return _AiToolsPanelContent(book: widget.book);
  }
}

class _AiToolsPanelContent extends ConsumerStatefulWidget {
  final BookModel book;
  final ScrollController? scrollController;

  const _AiToolsPanelContent({
    required this.book,
    this.scrollController,
  });

  @override
  ConsumerState<_AiToolsPanelContent> createState() =>
      _AiToolsPanelContentState();
}

class _AiToolsPanelContentState extends ConsumerState<_AiToolsPanelContent> {
  // Cached results
  String? _storySoFar;
  List<CharacterInfo>? _characters;
  String? _questionAnswer;
  List<ContentWarningResult>? _contentWarnings;
  List<String>? _discussionQuestions;

  // Loading states
  bool _loadingStory = false;
  bool _loadingCharacters = false;
  bool _loadingAnswer = false;
  bool _loadingWarnings = false;
  bool _loadingDiscussion = false;

  // Q&A
  final _questionController = TextEditingController();

  AiReadingTools get _tools =>
      AiReadingTools(ref.read(aiCompanionProvider));

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadStorySoFar() async {
    if (_storySoFar != null || _loadingStory) return;
    setState(() => _loadingStory = true);
    try {
      final result = await _tools.generateStorySoFar(widget.book);
      if (mounted) setState(() => _storySoFar = result);
    } finally {
      if (mounted) setState(() => _loadingStory = false);
    }
  }

  Future<void> _loadCharacters() async {
    if (_characters != null || _loadingCharacters) return;
    setState(() => _loadingCharacters = true);
    try {
      final result = await _tools.extractCharacters(widget.book);
      if (mounted) setState(() => _characters = result);
    } finally {
      if (mounted) setState(() => _loadingCharacters = false);
    }
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _loadingAnswer) return;
    setState(() {
      _loadingAnswer = true;
      _questionAnswer = null;
    });
    try {
      final result = await _tools.answerQuestion(widget.book, question);
      if (mounted) setState(() => _questionAnswer = result);
    } finally {
      if (mounted) setState(() => _loadingAnswer = false);
    }
  }

  Future<void> _loadContentWarnings() async {
    if (_contentWarnings != null || _loadingWarnings) return;
    setState(() => _loadingWarnings = true);
    try {
      final result = await _tools.analyzeContentWarnings(widget.book);
      if (mounted) setState(() => _contentWarnings = result);
    } finally {
      if (mounted) setState(() => _loadingWarnings = false);
    }
  }

  Future<void> _loadDiscussionQuestions() async {
    if (_discussionQuestions != null || _loadingDiscussion) return;
    setState(() => _loadingDiscussion = true);
    try {
      final chapter = widget.book.progress.currentChapter;
      final result =
          await _tools.generateDiscussionQuestions(widget.book, chapter);
      if (mounted) setState(() => _discussionQuestions = result);
    } finally {
      if (mounted) setState(() => _loadingDiscussion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        // Drag handle
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

        // Title
        const Row(
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: AuroraColors.auroraTeal, size: 24),
            SizedBox(width: 8),
            Text(
              'AI Reading Tools',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Chapter ${widget.book.progress.currentChapter + 1} of ${widget.book.chapters.length}',
          style: const TextStyle(
            color: AuroraColors.textTertiary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),

        // ── Story So Far ────────────────────────────────────────────────
        _buildToolSection(
          icon: Icons.history_edu_rounded,
          title: 'Story So Far',
          subtitle: 'Spoiler-free recap up to your current position',
          isLoading: _loadingStory,
          onTap: _loadStorySoFar,
          result: _storySoFar != null
              ? _buildTextResult(_storySoFar!)
              : null,
        ),
        const SizedBox(height: 12),

        // ── Characters ──────────────────────────────────────────────────
        _buildToolSection(
          icon: Icons.people_rounded,
          title: 'Characters',
          subtitle: 'Track characters and relationships',
          isLoading: _loadingCharacters,
          onTap: _loadCharacters,
          result: _characters != null
              ? _buildCharacterResults(_characters!)
              : null,
        ),
        const SizedBox(height: 12),

        // ── Ask a Question ──────────────────────────────────────────────
        _buildQuestionSection(),
        const SizedBox(height: 12),

        // ── Content Warnings ────────────────────────────────────────────
        _buildToolSection(
          icon: Icons.warning_amber_rounded,
          title: 'Content Warnings',
          subtitle: 'Analyze for sensitive content',
          isLoading: _loadingWarnings,
          onTap: _loadContentWarnings,
          result: _contentWarnings != null
              ? _buildWarningResults(_contentWarnings!)
              : null,
        ),
        const SizedBox(height: 12),

        // ── Discussion Questions ────────────────────────────────────────
        _buildToolSection(
          icon: Icons.forum_rounded,
          title: 'Discussion Questions',
          subtitle: 'For book club discussions on the current chapter',
          isLoading: _loadingDiscussion,
          onTap: _loadDiscussionQuestions,
          result: _discussionQuestions != null
              ? _buildDiscussionResults(_discussionQuestions!)
              : null,
        ),
      ],
    );
  }

  Widget _buildToolSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLoading,
    required VoidCallback onTap,
    Widget? result,
  }) {
    return AuroraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AuroraColors.auroraTeal, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AuroraColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (result == null && !isLoading)
                AuroraButton(
                  label: 'Generate',
                  compact: true,
                  onPressed: onTap,
                ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AuroraColors.auroraTeal,
                  ),
                ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF252E27), height: 1),
            const SizedBox(height: 12),
            result,
          ],
        ],
      ),
    );
  }

  Widget _buildTextResult(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AuroraColors.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  Widget _buildCharacterResults(List<CharacterInfo> characters) {
    if (characters.isEmpty) {
      return const Text(
        'No characters identified yet. Keep reading!',
        style: TextStyle(color: AuroraColors.textTertiary, fontSize: 14),
      );
    }

    return Column(
      children: characters.map((c) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AuroraColors.auroraTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AuroraColors.auroraTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        color: AuroraColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (c.description.isNotEmpty)
                      Text(
                        c.description,
                        style: const TextStyle(
                          color: AuroraColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    if (c.relationships.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: c.relationships.map((r) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AuroraColors.auroraGreen
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                r,
                                style: const TextStyle(
                                  color: AuroraColors.auroraGreen,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    Text(
                      'First appears: Chapter ${c.firstAppearanceChapter}',
                      style: const TextStyle(
                        color: AuroraColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionSection() {
    return AuroraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.question_answer_rounded,
                  color: AuroraColors.auroraTeal, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask a Question',
                      style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Ask about the book (spoiler-safe)',
                      style: TextStyle(
                        color: AuroraColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  style: const TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What is the significance of...',
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
                  onSubmitted: (_) => _askQuestion(),
                ),
              ),
              const SizedBox(width: 8),
              _loadingAnswer
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AuroraColors.auroraTeal,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: AuroraColors.auroraTeal),
                      onPressed: _askQuestion,
                    ),
            ],
          ),
          if (_questionAnswer != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF252E27), height: 1),
            const SizedBox(height: 12),
            _buildTextResult(_questionAnswer!),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningResults(List<ContentWarningResult> warnings) {
    if (warnings.isEmpty) {
      return Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: AuroraColors.auroraGreen, size: 18),
          const SizedBox(width: 8),
          const Text(
            'No content warnings detected.',
            style: TextStyle(
              color: AuroraColors.auroraGreen,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Column(
      children: warnings.map((w) {
        final severityColor = switch (w.severity) {
          'graphic' => AuroraColors.auroraWarm,
          'moderate' => AuroraColors.manuscriptGold,
          _ => AuroraColors.textSecondary,
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  w.severityLabel,
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.category,
                      style: const TextStyle(
                        color: AuroraColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (w.description.isNotEmpty)
                      Text(
                        w.description,
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
        );
      }).toList(),
    );
  }

  Widget _buildDiscussionResults(List<String> questions) {
    if (questions.isEmpty) {
      return const Text(
        'No discussion questions generated.',
        style: TextStyle(color: AuroraColors.textTertiary, fontSize: 14),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AuroraColors.auroraGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(
                      color: AuroraColors.auroraGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    color: AuroraColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
