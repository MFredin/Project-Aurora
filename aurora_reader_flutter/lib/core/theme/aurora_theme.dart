import 'package:flutter/material.dart';

/// Aurora/Northern Lights design system — 1:1 port from iOS AuroraTheme
class AuroraColors {
  AuroraColors._();

  // Core Aurora Palette
  static const deepSpace = Color(0xFF0A0A1F);
  static const cosmos = Color(0xFF12122E);
  static const surface = Color(0xFF1A1A38);
  static const surfaceElevated = Color(0xFF212142);

  // Aurora accent colors
  static const auroraGreen = Color(0xFF2EDE8F);
  static const auroraTeal = Color(0xFF26C7D1);
  static const auroraBlue = Color(0xFF4078F2);
  static const auroraPurple = Color(0xFF944CF2);
  static const auroraPink = Color(0xFFD940A6);
  static const auroraWarm = Color(0xFFF27340);

  // Text hierarchy
  static const textPrimary = Color(0xFFEDEDF8);
  static const textSecondary = Color(0xFF9E9EB8);
  static const textTertiary = Color(0xFF666685);

  // Tab bar
  static const tabBarBackground = Color(0xF20D0D24);
  static const tabActive = auroraTeal;
  static const tabInactive = textTertiary;

  // Gradients
  static const auroraGradient = LinearGradient(
    colors: [
      Color(0x99944CF2), // auroraPurple 60%
      Color(0x664078F2), // auroraBlue 40%
      Color(0x8026C7D1), // auroraTeal 50%
      Color(0x4D2EDE8F), // auroraGreen 30%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [auroraTeal, auroraGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [auroraBlue, auroraPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const warmGradient = LinearGradient(
    colors: [auroraPink, auroraWarm],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Book cover palettes
  static const coverPalettes = <List<Color>>[
    [auroraPurple, auroraBlue],
    [auroraBlue, auroraTeal],
    [auroraTeal, auroraGreen],
    [auroraPink, auroraPurple],
    [auroraWarm, auroraPink],
    [auroraGreen, auroraTeal],
    [auroraBlue, Color(0xCC944CF2)],
    [Color(0xCCD940A6), auroraBlue],
  ];

  static LinearGradient coverGradient(String title) {
    final index = title.hashCode.abs() % coverPalettes.length;
    return LinearGradient(
      colors: coverPalettes[index],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

/// Full Material ThemeData configured for Aurora
class AuroraTheme {
  AuroraTheme._();

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AuroraColors.deepSpace,
        colorScheme: const ColorScheme.dark(
          primary: AuroraColors.auroraTeal,
          secondary: AuroraColors.auroraPurple,
          surface: AuroraColors.surface,
          error: AuroraColors.auroraWarm,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AuroraColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AuroraColors.deepSpace,
          foregroundColor: AuroraColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AuroraColors.tabBarBackground,
          selectedItemColor: AuroraColors.tabActive,
          unselectedItemColor: AuroraColors.tabInactive,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardTheme(
          color: AuroraColors.surface.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 0.5,
            ),
          ),
          elevation: 0,
        ),
        listTileTheme: const ListTileThemeData(
          textColor: AuroraColors.textPrimary,
          iconColor: AuroraColors.auroraTeal,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: AuroraColors.textPrimary, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: AuroraColors.textPrimary, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: AuroraColors.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: AuroraColors.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: AuroraColors.textPrimary),
          titleSmall: TextStyle(color: AuroraColors.textSecondary),
          bodyLarge: TextStyle(color: AuroraColors.textPrimary),
          bodyMedium: TextStyle(color: AuroraColors.textSecondary),
          bodySmall: TextStyle(color: AuroraColors.textTertiary),
          labelLarge: TextStyle(color: AuroraColors.textPrimary, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(color: AuroraColors.textSecondary),
          labelSmall: TextStyle(color: AuroraColors.textTertiary),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: AuroraColors.auroraTeal,
          thumbColor: AuroraColors.auroraTeal,
          inactiveTrackColor: AuroraColors.surface,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AuroraColors.auroraTeal;
            return AuroraColors.textTertiary;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AuroraColors.auroraTeal.withOpacity(0.4);
            return AuroraColors.surface;
          }),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AuroraColors.auroraTeal,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AuroraColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: AuroraColors.textTertiary),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withOpacity(0.06),
        ),
      );
}
