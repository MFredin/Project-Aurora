import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/library/library_screen.dart';
import '../../screens/activity/activity_screen.dart';
import '../../screens/knowledge/knowledge_screen.dart';
import '../../screens/cloud/cloud_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/reader/reader_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/discover/discover_screen.dart';
import '../../screens/settings/export_screen.dart';
import '../theme/aurora_theme.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/library',
    routes: [
      // Onboarding (shown once)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LibraryScreen()),
          ),
          GoRoute(
            path: '/activity',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ActivityScreen()),
          ),
          GoRoute(
            path: '/knowledge',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: KnowledgeScreen()),
          ),
          GoRoute(
            path: '/cloud',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CloudScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: '/reader/:bookId',
        builder: (context, state) =>
            ReaderScreen(bookId: state.pathParameters['bookId']!),
      ),
      GoRoute(
        path: '/discover',
        builder: (context, state) => const DiscoverScreen(),
      ),
      GoRoute(
        path: '/export',
        builder: (context, state) => const ExportScreen(),
      ),
    ],
  );
});

/// Main scaffold with 5-tab bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/activity')) return 1;
    if (location.startsWith('/knowledge')) return 2;
    if (location.startsWith('/cloud')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) {
          switch (index) {
            case 0: context.go('/library');
            case 1: context.go('/activity');
            case 2: context.go('/knowledge');
            case 3: context.go('/cloud');
            case 4: context.go('/settings');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.hub), label: 'Knowledge'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Cloud'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
