import 'package:flutter/material.dart';

/// BNYAD — logo palette: teal → lime → gold (matches bnyadnewest).
class AppTheme {
  // ─── Logo gradient stops ──────────────────────────────
  static const Color brandTeal = Color(0xFF48C69F);
  static const Color brandTealDark = Color(0xFF26A69A);
  static const Color brandLime = Color(0xFFCDDC39);
  static const Color brandGold = Color(0xFFF7D060);
  static const Color brandGoldDeep = Color(0xFFFFB300);
  static const Color brandOrange = Color(0xFFFF8C42);
  static const Color brandOrangeDeep = Color(0xFFFF6B00);
  static const Color brandOrangeLight = Color(0xFFFFB074);

  // Primary / accent aliases used across the app
  static const Color brandGreen = brandTeal;
  static const Color brandGreenLight = Color(0xFF6ED4B3);
  static const Color brandGreenDark = brandTealDark;
  static const Color brandGreenGlow = Color(0xFF5BC9A8);
  static const Color brandOrangeDark = brandOrangeDeep;
  static const Color brandOrangeGlow = brandGold;

  static const List<Color> brandWordmarkGradient = [
    brandTeal,
    brandLime,
    brandOrange,
    brandGold,
  ];

  static const List<Color> brandGradient = [
    brandTeal,
    brandGreenLight,
    brandOrange,
    brandOrangeDeep,
  ];

  /// Primary CTA — teal-green with warm orange shadow.
  static const Color primaryAction = Color(0xFF3DBF8A);
  static const Color primaryActionDeep = brandOrangeDeep;

  /// Backward-compatible aliases.
  static const Color indigo = brandTeal;
  static const Color indigoLight = brandGreenLight;
  static const Color indigoDark = brandTealDark;

  static const Color neonOrange = brandOrange;
  static const Color neonOrangeLight = brandOrangeLight;
  static const Color neonOrangeDark = brandOrangeDeep;
  static const Color neonOrangeGlow = brandGold;
  static const Color neonAmber = brandGold;

  static const Color amber = brandGold;
  static const Color amberDeep = brandOrangeDeep;
  static const Color rose = Color(0xFFFF4757);
  static const Color roseSoft = Color(0xFFFF6B81);
  static const Color emerald = brandTeal;
  static const Color emeraldDeep = brandTealDark;
  static const Color cyan = brandLime;
  static const Color violet = brandGold;
  static const Color champagne = brandGold;
  static const Color champagneMuted = Color(0xFFD4A574);

  // ─── Light surfaces (warm cream) ────────────────────
  static const Color lightScaffold = Color(0xFFFFFAF7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceTint = Color(0xFFF0FAF6);
  static const Color lightSurfaceTint2 = Color(0xFFFFF0E0);
  static const Color lightNavShelf = Color(0xFFFFFAF7);

  // ─── Dark surfaces (deep forest — logo dark bg) ─────
  static const Color navy950 = Color(0xFF001A14);
  static const Color navy900 = Color(0xFF00221C);
  static const Color navy850 = Color(0xFF0A211B);
  static const Color navy800 = Color(0xFF0F2B24);
  static const Color navy750 = Color(0xFF15352D);
  static const Color navy700 = Color(0xFF1A4036);
  static const Color navy600 = Color(0xFF245A4C);

  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  /// Bundled fonts — avoids Flutter Web fetching from fonts.gstatic.com.
  static const String fontFamily = 'NotoSans';
  static const List<String> fontFamilyFallback = [
    'NotoSansArabic',
    'NotoSansSymbols',
    'sans-serif',
  ];

  static List<Color> get lightWelcomeGradient => [
        lightSurfaceTint,
        lightSurface,
        lightSurfaceTint2,
        const Color(0xFFFFE8D4),
      ];

  static List<Color> get darkWelcomeGradient => [
        navy950,
        navy900,
        const Color(0xFF1A1208),
        navy900,
      ];

  static List<Color> get splashOrbColors => [
        brandTeal,
        brandLime,
        brandOrange,
        brandOrangeLight,
        brandGold,
      ];

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandTeal,
      primary: brandTeal,
      onPrimary: Colors.white,
      secondary: brandOrange,
      surface: lightSurface,
      onSurface: slate900,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: lightScaffold,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: slate800,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: lightSurface.withValues(alpha: 0.95),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: brandOrange.withValues(alpha: 0.12), width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightSurface.withValues(alpha: 0.94),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: brandOrange.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: brandOrangeDeep, size: 26);
        }
        return const IconThemeData(color: slate400, size: 24);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: slate100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: brandOrange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandOrangeDeep,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: brandOrange.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: brandOrangeDeep,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: brandOrange),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return brandOrangeDeep;
        return slate300;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return brandOrange.withValues(alpha: 0.35);
        return slate200;
      }),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.5, color: slate900),
      headlineMedium: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1, color: slate900),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, color: slate900),
      bodyLarge: TextStyle(fontWeight: FontWeight.w600, color: slate800),
      bodyMedium: TextStyle(fontWeight: FontWeight.w500, color: slate700),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandTeal,
      primary: brandGreenLight,
      onPrimary: navy900,
      secondary: brandOrange,
      surface: navy800,
      onSurface: slate50,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: navy900,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: slate50,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: navy750.withValues(alpha: 0.75),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: brandOrange.withValues(alpha: 0.18), width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navy850.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: brandOrange.withValues(alpha: 0.24),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: brandOrangeLight, size: 26);
        }
        return const IconThemeData(color: slate500, size: 24);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: navy750.withValues(alpha: 0.85),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: brandOrangeLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandOrangeDeep,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: brandOrange.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: brandOrangeDeep,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: brandOrangeLight),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return brandOrangeLight;
        return slate600;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return brandOrange.withValues(alpha: 0.4);
        return navy600;
      }),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.5, color: slate50),
      headlineMedium: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1, color: slate50),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, color: slate50),
      bodyLarge: TextStyle(fontWeight: FontWeight.w600, color: slate200),
      bodyMedium: TextStyle(fontWeight: FontWeight.w500, color: slate400),
    ),
  );
}
