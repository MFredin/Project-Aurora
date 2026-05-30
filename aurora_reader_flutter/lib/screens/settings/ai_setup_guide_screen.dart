import 'package:flutter/material.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../services/ai/llm_provider.dart';

class AiSetupGuideScreen extends StatelessWidget {
  const AiSetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AuroraColors.cosmos.withOpacity(0.95),
          foregroundColor: AuroraColors.textPrimary,
          title: const Text('AI Companion Setup'),
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Connect an AI provider to unlock intelligent reading features — '
                    'ask questions about your books, get chapter summaries, '
                    'explore themes, and build a knowledge graph from your reading.',
                    style: TextStyle(
                      color: AuroraColors.textSecondary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AuroraCard(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AuroraColors.auroraGreen, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Edda sends book context and your questions directly to the provider you choose. '
                            'Your API key is stored only on this device.',
                            style: TextStyle(
                              color: AuroraColors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildProviderSection(
                    provider: LlmProviderType.anthropic,
                    icon: Icons.auto_awesome_rounded,
                    color: AuroraColors.auroraTeal,
                    steps: const [
                      'Go to console.anthropic.com and create an account',
                      'Navigate to API Keys in your dashboard',
                      'Click "Create Key" and give it a name (e.g. "Edda")',
                      'Copy the key — it starts with sk-ant-...',
                      'Paste it into Settings → AI Companion → API Key',
                    ],
                    notes: 'Claude Sonnet 4.6 offers the best balance of quality and speed '
                        'for reading companion tasks. Opus 4.8 is more capable but slower and costlier.',
                  ),

                  _buildProviderSection(
                    provider: LlmProviderType.openai,
                    icon: Icons.circle_outlined,
                    color: const Color(0xFF10A37F),
                    steps: const [
                      'Go to platform.openai.com and sign in or create an account',
                      'Navigate to API Keys in the sidebar',
                      'Click "Create new secret key" and name it',
                      'Copy the key — it starts with sk-...',
                      'Paste it into Settings → AI Companion → API Key',
                    ],
                    notes: 'GPT-5.5 is the current flagship. For faster responses at lower cost, '
                        'o4-mini works well for straightforward questions.',
                  ),

                  _buildProviderSection(
                    provider: LlmProviderType.gemini,
                    icon: Icons.diamond_outlined,
                    color: const Color(0xFF4285F4),
                    steps: const [
                      'Go to aistudio.google.com and sign in with your Google account',
                      'Click "Get API key" in the top navigation',
                      'Create a key for a new or existing Google Cloud project',
                      'Copy the key — it starts with AIza...',
                      'Paste it into Settings → AI Companion → API Key',
                    ],
                    notes: 'Gemini 3.5 Flash is fast and generous with free-tier usage. '
                        'Gemini 3.1 Pro offers stronger reasoning for deeper analysis.',
                  ),

                  const SizedBox(height: 28),

                  _buildSectionHeader('HOW IT WORKS'),
                  const SizedBox(height: 8),
                  AuroraCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeatureRow(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Ask Questions',
                          description: 'Edda sends the current chapter text along with your question '
                              'so the AI can give contextual, accurate answers.',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureRow(
                          icon: Icons.summarize_rounded,
                          title: 'Chapter Summaries',
                          description: 'Generates concise summaries of chapters you\'ve read, '
                              'helping you recall key points when picking a book back up.',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureRow(
                          icon: Icons.palette_rounded,
                          title: 'Theme Analysis',
                          description: 'Identifies recurring themes, motifs, and literary devices '
                              'across chapters and books in your library.',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureRow(
                          icon: Icons.account_tree_rounded,
                          title: 'Knowledge Graph',
                          description: 'Extracts key concepts, characters, and ideas from your reading '
                              'and maps the connections between them.',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureRow(
                          icon: Icons.translate_rounded,
                          title: 'Word Explanations',
                          description: 'Tap any word while reading for a contextual definition — '
                              'the AI considers the surrounding text for accurate meaning.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildSectionHeader('USAGE & COSTS'),
                  const SizedBox(height: 8),
                  AuroraCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Each AI feature sends a small amount of text to your chosen provider. '
                          'Typical usage while reading costs less than a few cents per session. '
                          'All three providers offer free tiers or trial credits for new accounts.',
                          style: TextStyle(
                            color: AuroraColors.textSecondary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Edda never sends your full library — only the relevant chapter or '
                          'passage needed to answer your question.',
                          style: TextStyle(
                            color: AuroraColors.textSecondary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AuroraColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildProviderSection({
    required LlmProviderType provider,
    required IconData icon,
    required Color color,
    required List<String> steps,
    required String notes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(provider.displayName.toUpperCase()),
        const SizedBox(height: 8),
        AuroraCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      provider.displayName,
                      style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...steps.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.15),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$index',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(
                            color: AuroraColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Text(
                  notes,
                  style: TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  static Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AuroraColors.auroraTeal, size: 20),
        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AuroraColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
