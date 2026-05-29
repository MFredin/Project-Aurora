import 'package:flutter/material.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

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
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

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

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trending',
          style: TextStyle(
            color: AuroraColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
