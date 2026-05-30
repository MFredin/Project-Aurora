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
import '../../screens/settings/error_log_screen.dart';
import '../../screens/library/book_detail_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../providers/auth_provider.dart';
import '../layout/adaptive_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) {
    authNotifier.value++;
  });

  return GoRouter(
    initialLocation: '/library',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final user = ref.read(authServiceProvider).currentUser;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/signup';
      final isOnboarding = location == '/onboarding';

      if (!isLoggedIn && !isAuthRoute && !isOnboarding) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/library';
      }
      return null;
    },
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

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
        path: '/book/:bookId',
        builder: (context, state) =>
            BookDetailScreen(bookId: state.pathParameters['bookId']!),
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
      GoRoute(
        path: '/error-log',
        builder: (context, state) => const ErrorLogScreen(),
      ),
    ],
  );
});
