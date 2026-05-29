import 'package:flutter/material.dart';

class AuroraColors {
  AuroraColors._();

  // Runestone core palette — charcoal slate and weathered stone
  static const deepSpace = Color(0xFF1A1A1E);
  static const cosmos = Color(0xFF1F1E1B);
  static const surface = Color(0xFF2A2722);
  static const surfaceElevated = Color(0xFF33302A);

  // Accent colors — aged metal and Nordic elements
  static const auroraGreen = Color(0xFF7B9E6F);   // moss/sage
  static const auroraTeal = Color(0xFFC4973B);     // aged gold (primary accent)
  static const auroraBlue = Color(0xFF7BA4C7);     // frost steel
  static const auroraPurple = Color(0xFF8B6B8F);   // heather plum
  static const auroraPink = Color(0xFF9E5B6B);     // dark rose
  static const auroraWarm = Color(0xFFB85C3A);     // burnt umber

  // Text hierarchy — parchment tones
  static const textPrimary = Color(0xFFE8E0D0);
  static const textSecondary = Color(0xFF9E9688);
  static const textTertiary = Color(0xFF5E5850);

  // Tab bar
  static const tabBarBackground = Color(0xF21A1A1E);
  static const tabActive = auroraTeal;
  static const tabInactive = textTertiary;

  // Gradients — hammered metal and ember
  static const auroraGradient = LinearGradient(
    colors: [
      Color(0x99C4973B),
      Color(0x667BA4C7),
      Color(0x807B9E6F),
      Color(0x4D8B6B8F),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFC4973B), Color(0xFFA8802E)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFF7BA4C7), Color(0xFF5B7A9E)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const warmGradient = LinearGradient(
    colors: [Color(0xFFB85C3A), Color(0xFFC4973B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Book cover palettes — old bindings and manuscripts
  static const coverPalettes = <List<Color>>[
    [Color(0xFF6B3A3A), Color(0xFF8B5E3C)], // burgundy → leather
    [Color(0xFF3A5C4A), Color(0xFF5B7A5E)], // forest → sage
    [Color(0xFF5B7A9E), Color(0xFF3A4F6B)], // steel → deep blue
    [Color(0xFF8B6B8F), Color(0xFF5B3A5E)], // heather → plum
    [Color(0xFFB85C3A), Color(0xFF8B3A2E)], // ember → rust
    [Color(0xFF7B9E6F), Color(0xFF4A6B3A)], // moss → pine
    [Color(0xFFC4973B), Color(0xFF8B6B2E)], // gold → bronze
    [Color(0xFF4A5E6B), Color(0xFF7BA4C7)], // slate → frost
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
          color: AuroraColors.surface.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.white.withOpacity(0.04),
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
            borderRadius: BorderRadius.circular(10),
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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AuroraColors.surfaceElevated,
          contentTextStyle: TextStyle(color: AuroraColors.textPrimary),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
