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
import '../../screens/settings/ai_setup_guide_screen.dart';
import '../layout/adaptive_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/library',
    routes: [
      // Onboarding (shown once)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main shell with adaptive navigation
      ShellRoute(
        builder: (context, state, child) => AdaptiveShell(child: child),
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
      GoRoute(
        path: '/ai-setup',
        builder: (context, state) => const AiSetupGuideScreen(),
      ),
    ],
  );
});

