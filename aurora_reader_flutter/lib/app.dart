import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/aurora_theme.dart';
import 'core/router/app_router.dart';

class AuroraReaderApp extends ConsumerWidget {
  const AuroraReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Edda',
      debugShowCheckedModeBanner: false,
      theme: AuroraTheme.darkTheme,
      darkTheme: AuroraTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
