import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/aurora_theme.dart';
import '../../core/theme/aurora_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      title: 'Welcome to Aurora Reader',
      subtitle:
          'Your cross-platform ebook companion with a stunning Northern Lights theme',
      gradient: AuroraColors.accentGradient,
    ),
    _OnboardingPage(
      icon: Icons.menu_book_rounded,
      title: '11 Format Support',
      subtitle:
          'Read EPUB, PDF, TXT, MOBI, FB2, CBZ, CBR, RTF, DJVU, AZW3, and DOCX files',
      gradient: AuroraColors.secondaryGradient,
    ),
    _OnboardingPage(
      icon: Icons.insights_rounded,
      title: 'Track Your Progress',
      subtitle:
          'Reading streaks, daily goals, achievements, and beautiful statistics',
      gradient: AuroraColors.warmGradient,
    ),
    _OnboardingPage(
      icon: Icons.psychology_rounded,
      title: 'AI Reading Companion',
      subtitle:
          'Ask questions about your books, get summaries, and build your knowledge graph',
      gradient: LinearGradient(
        colors: [AuroraColors.auroraPurple, AuroraColors.auroraPink],
      ),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () => context.go('/library'),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AuroraColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon with gradient
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: page.gradient,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AuroraColors.auroraTeal.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(page.icon,
                                color: Colors.white, size: 52),
                          ),
                          const SizedBox(height: 48),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AuroraColors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            page.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AuroraColors.textSecondary,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Page indicators + button
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isActive ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AuroraColors.auroraTeal
                                : AuroraColors.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: AuroraButton(
                        label: _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        icon: _currentPage == _pages.length - 1
                            ? Icons.arrow_forward_rounded
                            : null,
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            context.go('/library');
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
