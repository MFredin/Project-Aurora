import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/aurora_theme.dart';
import 'core/router/app_router.dart';
import 'providers/service_providers.dart';

class AuroraReaderApp extends ConsumerWidget {
  const AuroraReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final isDark = ref.watch(darkModeProvider);

    return MaterialApp.router(
      title: 'Edda',
      debugShowCheckedModeBanner: false,
      theme: AuroraTheme.lightTheme,
      darkTheme: AuroraTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
