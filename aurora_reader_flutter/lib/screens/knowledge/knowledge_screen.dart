import 'package:flutter/material.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

/// Mock data for knowledge graph
class _MockKnowledge {
  static const themes = [
    {'label': 'Power & Control', 'count': 12, 'color': 'purple'},
    {'label': 'Identity', 'count': 8, 'color': 'teal'},
    {'label': 'Ecology', 'count': 6, 'color': 'green'},
    {'label': 'Religion', 'count': 5, 'color': 'blue'},
    {'label': 'Survival', 'count': 4, 'color': 'warm'},
  ];

  static const vocabulary = [
    {'word': 'Prescience', 'definition': 'The ability to foresee events before they happen', 'book': 'Dune'},
    {'word': 'Gom Jabbar', 'definition': 'A meta-cyanide needle used in the test of humanity', 'book': 'Dune'},
    {'word': 'Ansible', 'definition': 'A device for instantaneous communication across distances', 'book': 'The Left Hand of Darkness'},
    {'word': 'Psychohistory', 'definition': 'Mathematical framework for predicting the future of large populations', 'book': 'Foundation'},
    {'word': 'Cyberspace', 'definition': 'A consensual hallucination experienced as a virtual reality', 'book': 'Neuromancer'},
    {'word': 'Simstim', 'definition': 'Simulated stimulation — recording/playback of sensory experiences', 'book': 'Neuromancer'},
  ];

  static const highlights = [
    {
      'text': 'Fear is the mind-killer. Fear is the little-death that brings total obliteration.',
      'book': 'Dune',
      'chapter': 'Chapter 1',
      'color': 'teal',
    },
    {
      'text': 'The sky above the port was the color of television, tuned to a dead channel.',
      'book': 'Neuromancer',
      'chapter': 'Chapter 1',
      'color': 'blue',
    },
    {
      'text': 'To learn which questions are unanswerable, and not to answer them: this skill is most needful.',
      'book': 'The Left Hand of Darkness',
      'chapter': 'Chapter 6',
      'color': 'purple',
    },
    {
      'text': 'Violence is the last refuge of the incompetent.',
      'book': 'Foundation',
      'chapter': 'Part II',
      'color': 'green',
    },
  ];
}

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Knowledge',
                  style: TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: AuroraColors.auroraTeal,
                labelColor: AuroraColors.auroraTeal,
                unselectedLabelColor: AuroraColors.textTertiary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Themes'),
                  Tab(text: 'Vocabulary'),
                  Tab(text: 'Highlights'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildThemesTab(),
                    _buildVocabularyTab(),
                    _buildHighlightsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Graph placeholder
        AuroraCard(
          child: Column(
            children: [
              const Icon(Icons.hub_rounded,
                  color: AuroraColors.auroraTeal, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Knowledge Graph',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Connections between themes, characters, and concepts across your books',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              // Theme nodes
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _MockKnowledge.themes.map((t) {
                  final color = _colorFromName(t['color'] as String);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                              BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t['label'] as String,
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${t['count']}',
                          style: TextStyle(
                            color: color.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Theme Distribution',
          style: TextStyle(
            color: AuroraColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ..._MockKnowledge.themes.map((t) {
          final color = _colorFromName(t['color'] as String);
          final count = t['count'] as int;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AuroraCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['label'] as String,
                          style: const TextStyle(
                            color: AuroraColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: count / 12.0,
                            minHeight: 3,
                            backgroundColor: AuroraColors.surface,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
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

  Widget _buildVocabularyTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _MockKnowledge.vocabulary.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final v = _MockKnowledge.vocabulary[index];
        return AuroraCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    v['word'] as String,
                    style: const TextStyle(
                      color: AuroraColors.auroraTeal,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AuroraColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      v['book'] as String,
                      style: const TextStyle(
                        color: AuroraColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                v['definition'] as String,
                style: const TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighlightsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _MockKnowledge.highlights.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final h = _MockKnowledge.highlights[index];
        final color = _colorFromName(h['color'] as String);
        return AuroraCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '"${h['text']}"',
                      style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.menu_book_rounded,
                      color: AuroraColors.textTertiary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${h['book']} — ${h['chapter']}',
                    style: const TextStyle(
                      color: AuroraColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _colorFromName(String name) {
    switch (name) {
      case 'purple':
        return AuroraColors.auroraPurple;
      case 'teal':
        return AuroraColors.auroraTeal;
      case 'green':
        return AuroraColors.auroraGreen;
      case 'blue':
        return AuroraColors.auroraBlue;
      case 'warm':
        return AuroraColors.auroraWarm;
      case 'pink':
        return AuroraColors.auroraPink;
      default:
        return AuroraColors.auroraTeal;
    }
  }
}
