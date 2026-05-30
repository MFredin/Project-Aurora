import 'package:flutter/material.dart';

class AuroraColors {
  AuroraColors._();

  // Stave & Shadow — deep forest night
  static const deepSpace = Color(0xFF0D1210);
  static const cosmos = Color(0xFF141A16);
  static const surface = Color(0xFF1A211C);
  static const surfaceElevated = Color(0xFF222A24);

  // Accent colors — ember, patina, and manuscript
  static const auroraGreen = Color(0xFF5A9E8F);   // lichen teal / copper patina
  static const auroraTeal = Color(0xFFB87944);     // muted ember (primary accent)
  static const auroraBlue = Color(0xFF5A9E8F);     // lichen teal (alias)
  static const auroraPurple = Color(0xFF7A6B5A);   // driftwood
  static const auroraPink = Color(0xFF8B5E4A);     // smoked clay
  static const auroraWarm = Color(0xFFC25B3A);     // warning ember

  // Manuscript highlight
  static const manuscriptGold = Color(0xFFA89060);

  // Text hierarchy — fog and moss
  static const textPrimary = Color(0xFFD4D0C8);
  static const textSecondary = Color(0xFF8A8680);
  static const textTertiary = Color(0xFF6B7066);

  // Tab bar
  static const tabBarBackground = Color(0xF20D1210);
  static const tabActive = auroraTeal;
  static const tabInactive = textTertiary;

  // Gradients — smoldering and mossy
  static const auroraGradient = LinearGradient(
    colors: [
      Color(0x99B87944),
      Color(0x665A9E8F),
      Color(0x80A89060),
      Color(0x4D7A6B5A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFB87944), Color(0xFF9A6338)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFF5A9E8F), Color(0xFF3D7A6D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const warmGradient = LinearGradient(
    colors: [Color(0xFFC25B3A), Color(0xFFB87944)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Book cover palettes — forest floor and stave church
  static const coverPalettes = <List<Color>>[
    [Color(0xFF4A3528), Color(0xFF6B4E38)], // dark bark → warm wood
    [Color(0xFF2A4A3A), Color(0xFF3D6B52)], // deep pine → forest
    [Color(0xFF3A4F5A), Color(0xFF5A7A8B)], // fjord slate → cold steel
    [Color(0xFF5A4A3A), Color(0xFF7A6B5A)], // smoke → driftwood
    [Color(0xFF6B3A28), Color(0xFF8B5A3A)], // ember → copper
    [Color(0xFF2A3A2E), Color(0xFF4A5E48)], // shadow pine → moss
    [Color(0xFF8B6B3A), Color(0xFFA89060)], // amber → manuscript gold
    [Color(0xFF3A4A4E), Color(0xFF5A9E8F)], // deep water → lichen
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

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F2EB),
        fontFamily: 'sans-serif',
        colorScheme: const ColorScheme.light(
          primary: AuroraColors.auroraTeal,
          secondary: AuroraColors.auroraGreen,
          surface: Color(0xFFEDE9E0),
          error: AuroraColors.auroraWarm,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF2A2A2A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF2A2A2A),
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: AuroraColors.auroraTeal,
          unselectedItemColor: Color(0xFF8A8680),
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFEDE9E0).withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(0xFFD4D0C8).withOpacity(0.5),
              width: 0.5,
            ),
          ),
          elevation: 0,
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Color(0xFF2A2A2A),
          iconColor: AuroraColors.auroraTeal,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              color: Color(0xFF2A2A2A),
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5),
          headlineMedium: TextStyle(
              color: Color(0xFF2A2A2A),
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5),
          headlineSmall: TextStyle(
              color: Color(0xFF2A2A2A), fontWeight: FontWeight.w600),
          titleLarge: TextStyle(
              color: Color(0xFF2A2A2A), fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: Color(0xFF2A2A2A)),
          titleSmall: TextStyle(color: Color(0xFF5A5550)),
          bodyLarge: TextStyle(color: Color(0xFF2A2A2A)),
          bodyMedium: TextStyle(color: Color(0xFF5A5550)),
          bodySmall: TextStyle(color: Color(0xFF8A8680)),
          labelLarge: TextStyle(
              color: Color(0xFF2A2A2A), fontWeight: FontWeight.w600),
          labelMedium: TextStyle(color: Color(0xFF5A5550)),
          labelSmall: TextStyle(color: Color(0xFF8A8680)),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: AuroraColors.auroraTeal,
          thumbColor: AuroraColors.auroraTeal,
          inactiveTrackColor: Color(0xFFD4D0C8),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AuroraColors.auroraTeal;
            }
            return const Color(0xFF8A8680);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AuroraColors.auroraTeal.withOpacity(0.3);
            }
            return const Color(0xFFD4D0C8);
          }),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AuroraColors.auroraTeal,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEDE9E0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Color(0xFF8A8680)),
        ),
        dividerTheme: DividerThemeData(
          color: const Color(0xFFD4D0C8).withOpacity(0.6),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFFF5F2EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF2A2A2A),
          contentTextStyle: TextStyle(color: Color(0xFFD4D0C8)),
          behavior: SnackBarBehavior.floating,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AuroraColors.deepSpace,
        fontFamily: 'sans-serif',
        colorScheme: const ColorScheme.dark(
          primary: AuroraColors.auroraTeal,
          secondary: AuroraColors.auroraGreen,
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
              color: const Color(0xFF252E27).withOpacity(0.6),
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
          color: const Color(0xFF252E27).withOpacity(0.6),
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
