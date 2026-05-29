import 'package:flutter/material.dart';

class AuroraColors {
  AuroraColors._();

  // Core palette
  static const deepSpace = Color(0xFF080816);
  static const cosmos = Color(0xFF0E0E24);
  static const surface = Color(0xFF16163A);
  static const surfaceElevated = Color(0xFF1E1E48);

  // Aurora accent colors
  static const auroraGreen = Color(0xFF2EDE8F);
  static const auroraTeal = Color(0xFF26C7D1);
  static const auroraBlue = Color(0xFF4078F2);
  static const auroraPurple = Color(0xFF944CF2);
  static const auroraPink = Color(0xFFD940A6);
  static const auroraWarm = Color(0xFFF27340);

  // Text hierarchy
  static const textPrimary = Color(0xFFF0F0FA);
  static const textSecondary = Color(0xFF9E9EB8);
  static const textTertiary = Color(0xFF5C5C7A);

  // Tab bar
  static const tabBarBackground = Color(0xF20D0D24);
  static const tabActive = auroraTeal;
  static const tabInactive = textTertiary;

  // Gradients
  static const auroraGradient = LinearGradient(
    colors: [
      Color(0x99944CF2),
      Color(0x664078F2),
      Color(0x8026C7D1),
      Color(0x4D2EDE8F),
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
    [Color(0xFF6C3FC7), Color(0xFF3B6FE8)],
    [Color(0xFF2E7DDE), Color(0xFF22B8C4)],
    [Color(0xFF1DB88A), Color(0xFF26C7D1)],
    [Color(0xFFBE3DA0), Color(0xFF7B42E0)],
    [Color(0xFFE86040), Color(0xFFD940A6)],
    [Color(0xFF2EDE8F), Color(0xFF26C7D1)],
    [Color(0xFF4078F2), Color(0xCC944CF2)],
    [Color(0xCCD940A6), Color(0xFF4078F2)],
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

class AuroraTheme {
  AuroraTheme._();

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AuroraColors.deepSpace,
        fontFamily: 'sans-serif',
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
          backgroundColor: Colors.transparent,
          foregroundColor: AuroraColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: AuroraColors.tabActive,
          unselectedItemColor: AuroraColors.tabInactive,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardThemeData(
          color: AuroraColors.surface.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.06),
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
          headlineLarge: TextStyle(
              color: AuroraColors.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5),
          headlineMedium: TextStyle(
              color: AuroraColors.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5),
          headlineSmall: TextStyle(
              color: AuroraColors.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(
              color: AuroraColors.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: AuroraColors.textPrimary),
          titleSmall: TextStyle(color: AuroraColors.textSecondary),
          bodyLarge: TextStyle(color: AuroraColors.textPrimary),
          bodyMedium: TextStyle(color: AuroraColors.textSecondary),
          bodySmall: TextStyle(color: AuroraColors.textTertiary),
          labelLarge: TextStyle(
              color: AuroraColors.textPrimary, fontWeight: FontWeight.w600),
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
            if (states.contains(WidgetState.selected)) {
              return AuroraColors.auroraTeal;
            }
            return AuroraColors.textTertiary;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AuroraColors.auroraTeal.withOpacity(0.3);
            }
            return AuroraColors.surface;
          }),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AuroraColors.auroraTeal,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AuroraColors.surface.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: AuroraColors.textTertiary),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withOpacity(0.04),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AuroraColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AuroraColors.surfaceElevated,
          contentTextStyle: TextStyle(color: AuroraColors.textPrimary),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
