import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';
import '../../core/data/social_models.dart';
import '../../core/data/social_repository.dart';

/// Mock discover data
class _MockDiscover {
  static const trending = [
    {'title': 'Project Hail Mary', 'author': 'Andy Weir', 'rating': 4.5},
    {'title': 'The Three-Body Problem', 'author': 'Liu Cixin', 'rating': 4.3},
    {'title': 'Klara and the Sun', 'author': 'Kazuo Ishiguro', 'rating': 4.1},
    {'title': 'Piranesi', 'author': 'Susanna Clarke', 'rating': 4.4},
    {'title': 'The Midnight Library', 'author': 'Matt Haig', 'rating': 4.2},
  ];

  static const genres = [
    {'name': 'Science Fiction', 'icon': Icons.rocket_launch_rounded, 'count': 2847},
    {'name': 'Fantasy', 'icon': Icons.auto_awesome_rounded, 'count': 3201},
    {'name': 'Mystery', 'icon': Icons.search_rounded, 'count': 1892},
    {'name': 'Non-Fiction', 'icon': Icons.school_rounded, 'count': 4123},
    {'name': 'Romance', 'icon': Icons.favorite_rounded, 'count': 2156},
    {'name': 'Horror', 'icon': Icons.nights_stay_rounded, 'count': 1047},
  ];

  static const moods = [
    {'label': 'Adventurous', 'icon': Icons.explore_rounded},
    {'label': 'Dark', 'icon': Icons.nights_stay_rounded},
    {'label': 'Emotional', 'icon': Icons.water_drop_rounded},
    {'label': 'Hopeful', 'icon': Icons.wb_sunny_rounded},
    {'label': 'Funny', 'icon': Icons.sentiment_very_satisfied_rounded},
    {'label': 'Tense', 'icon': Icons.bolt_rounded},
    {'label': 'Inspiring', 'icon': Icons.lightbulb_rounded},
    {'label': 'Reflective', 'icon': Icons.self_improvement_rounded},
    {'label': 'Romantic', 'icon': Icons.favorite_border_rounded},
    {'label': 'Mysterious', 'icon': Icons.visibility_off_rounded},
    {'label': 'Lighthearted', 'icon': Icons.cloud_rounded},
    {'label': 'Melancholic', 'icon': Icons.water_rounded},
  ];

  // "Because You Liked" mock data
  static const becauseYouLiked = [
    {
      'liked': 'Project Hail Mary',
      'recommendations': [
        {'title': 'The Martian', 'author': 'Andy Weir'},
        {'title': 'Children of Time', 'author': 'Adrian Tchaikovsky'},
        {'title': 'Seveneves', 'author': 'Neal Stephenson'},
      ],
    },
    {
      'liked': 'Piranesi',
      'recommendations': [
        {'title': 'The Starless Sea', 'author': 'Erin Morgenstern'},
        {'title': 'The House in the Cerulean Sea', 'author': 'TJ Klune'},
        {'title': 'Jonathan Strange & Mr Norrell', 'author': 'Susanna Clarke'},
      ],
    },
  ];
}

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  final Set<String> _selectedMoods = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    // Simulate search results
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [
            {'title': '$query: A Novel', 'author': 'Author Name', 'year': '2024'},
            {'title': 'The Art of $query', 'author': 'Writer Name', 'year': '2023'},
            {'title': '$query Revisited', 'author': 'Another Author', 'year': '2022'},
          ];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Discover',
              style: TextStyle(color: AuroraColors.textPrimary)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AuroraColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Search bar
                Container(
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
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                  _performSearch(v);
                },
                style: const TextStyle(color: AuroraColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search books, authors, ISBN...',
                  hintStyle:
                      const TextStyle(color: AuroraColors.textTertiary),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AuroraColors.textTertiary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AuroraColors.textTertiary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Search results or browse content
            if (_isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                      color: AuroraColors.auroraTeal),
                ),
              )
            else if (_searchResults.isNotEmpty)
              _buildSearchResults()
            else ...[
              _buildMoodDiscovery(),
              const SizedBox(height: 24),
              _buildBecauseYouLiked(),
              const SizedBox(height: 24),
              _buildFriendRecommendations(),
              const SizedBox(height: 24),
              _buildTrendingSection(),
              const SizedBox(height: 24),
              _buildGenresSection(),
              const SizedBox(height: 24),
              _buildOpenLibrarySection(),
            ],
            const SizedBox(height: 100),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_searchResults.length} results',
          style: const TextStyle(
            color: AuroraColors.textTertiary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        ..._searchResults.map((r) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AuroraCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient:
                          AuroraColors.coverGradient(r['title'] as String),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white70, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['title'] as String,
                          style: const TextStyle(
                            color: AuroraColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          r['author'] as String,
                          style: const TextStyle(
                            color: AuroraColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          r['year'] as String,
                          style: const TextStyle(
                            color: AuroraColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AuroraButton(
                    label: 'Add',
                    icon: Icons.add_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- Mood-based Discovery ---

  Widget _buildMoodDiscovery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.mood_rounded,
                color: AuroraColors.auroraPurple, size: 20),
            SizedBox(width: 8),
            Text(
              'What are you in the mood for?',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _MockDiscover.moods.map((mood) {
            final label = mood['label'] as String;
            final icon = mood['icon'] as IconData;
            final isSelected = _selectedMoods.contains(label.toLowerCase());

            return _MoodChip(
              label: label,
              icon: icon,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  final key = label.toLowerCase();
                  if (_selectedMoods.contains(key)) {
                    _selectedMoods.remove(key);
                  } else {
                    _selectedMoods.add(key);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_selectedMoods.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AuroraColors.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF252E27),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Books matching: ${_selectedMoods.join(", ")}',
                  style: const TextStyle(
                    color: AuroraColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mood-filtered search results will appear here when connected to a library.',
                  style: TextStyle(
                    color: AuroraColors.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- Because You Liked ---

  Widget _buildBecauseYouLiked() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: AuroraColors.manuscriptGold, size: 20),
            SizedBox(width: 8),
            Text(
              'Because You Liked',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._MockDiscover.becauseYouLiked.map((section) {
          final likedTitle = section['liked'] as String;
          final recs =
              section['recommendations'] as List<Map<String, String>>;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: AuroraColors.auroraWarm, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Because you loved $likedTitle',
                      style: const TextStyle(
                        color: AuroraColors.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final rec = recs[index];
                      return SizedBox(
                        width: 110,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 120,
                              width: 110,
                              decoration: BoxDecoration(
                                gradient: AuroraColors.coverGradient(
                                    rec['title']!),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    rec['title']!,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                            blurRadius: 6,
                                            color: Colors.black54),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rec['author']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AuroraColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- Friend Recommendations ---

  Widget _buildFriendRecommendations() {
    final recommendations = ref.watch(socialRecommendationsProvider);

    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.people_rounded,
                color: AuroraColors.auroraGreen, size: 20),
            SizedBox(width: 8),
            Text(
              'Friend Recommendations',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recommendations.take(3).map((rec) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AuroraCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recommender avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          AuroraColors.coverGradient(rec.fromUserName),
                    ),
                    child: Center(
                      child: Text(
                        rec.fromUserName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: rec.fromUserName,
                                style: const TextStyle(
                                  color: AuroraColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const TextSpan(
                                text: ' recommends',
                                style: TextStyle(
                                  color: AuroraColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: AuroraColors.coverGradient(
                                    rec.bookTitle),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.bookTitle,
                                    style: const TextStyle(
                                      color: AuroraColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'by ${rec.bookAuthor}',
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
                        if (rec.personalNote.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '"${rec.personalNote}"',
                            style: const TextStyle(
                              color: AuroraColors.textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ],
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

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.trending_up_rounded,
                color: AuroraColors.auroraWarm, size: 20),
            SizedBox(width: 8),
            Text(
              'Trending',
              style: TextStyle(
                color: AuroraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _MockDiscover.trending.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final book = _MockDiscover.trending[index];
              return SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 170,
                      width: 130,
                      decoration: BoxDecoration(
                        gradient: AuroraColors.coverGradient(
                            book['title'] as String),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            book['title'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                    blurRadius: 8, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book['author'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AuroraColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse by Genre',
          style: TextStyle(
            color: AuroraColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: ResponsiveHelper.gridColumns(context),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: _MockDiscover.genres.map((g) {
            return AuroraCard(
              padding: const EdgeInsets.all(12),
              onTap: () {},
              child: Row(
                children: [
                  Icon(g['icon'] as IconData,
                      color: AuroraColors.auroraTeal, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          g['name'] as String,
                          style: const TextStyle(
                            color: AuroraColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${g['count']} books',
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
        ),
      ],
    );
  }

  Widget _buildOpenLibrarySection() {
    return AuroraCard(
      child: Column(
        children: [
          const Icon(Icons.public_rounded,
              color: AuroraColors.auroraBlue, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Open Library',
            style: TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Search millions of free books from the Internet Archive',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AuroraColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          AuroraButton(
            label: 'Browse Open Library',
            icon: Icons.open_in_new_rounded,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// --- Mood Chip Widget ---

class _MoodChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_MoodChip> createState() => _MoodChipState();
}

class _MoodChipState extends State<_MoodChip> {
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: widget.isSelected ? AuroraColors.accentGradient : null,
            color: widget.isSelected
                ? null
                : _hovering
                    ? AuroraColors.surfaceElevated
                    : AuroraColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: widget.isSelected
                ? null
                : Border.all(
                    color: Color.lerp(
                      const Color(0xFF252E27),
                      const Color(0xFF354038),
                      _hovering ? 1.0 : 0.0,
                    )!,
                    width: 0.5,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: widget.isSelected
                    ? const Color(0xFFF0E8D8)
                    : AuroraColors.textTertiary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? const Color(0xFFF0E8D8)
                      : AuroraColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
