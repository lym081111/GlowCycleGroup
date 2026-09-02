import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The single Material 3 theme used by [GlowCycleApp].
ThemeData glowCycleTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
      onSurface: ink,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0.4,
      shadowColor: brandPink.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.6),
      ),
    ),
  );
}

/// Maps a resolved lifecycle status to its accent colour.
Color statusColor(String status) {
  switch (status) {
    case 'Safe':
    case 'Unopened':
      return sage;
    case 'Use Soon':
      return amber;
    case 'Expired':
      return danger;
    case 'Finished':
      return blue;
    case 'Recycled':
      return sage;
    default:
      return ink;
  }
}

/// Maps a product category to its representative icon.
IconData categoryIcon(String category) {
  switch (category) {
    case 'Skincare':
      return Icons.water_drop_outlined;
    case 'Makeup':
      return Icons.brush_outlined;
    case 'Haircare':
      return Icons.air_outlined;
    case 'Bodycare':
      return Icons.spa_outlined;
    case 'Fragrance':
      return Icons.local_florist_outlined;
    default:
      return Icons.auto_awesome_outlined;
  }
}

/// Maps a product category to a light/dark gradient pair.
List<Color> categoryPalette(String category) {
  switch (category) {
    case 'Skincare':
      return const [Color(0xFFE3F4EA), Color(0xFF8EC9A0)];
    case 'Makeup':
      return const [Color(0xFFFFDDE4), Color(0xFFD8788D)];
    case 'Haircare':
      return const [Color(0xFFFFEBC8), Color(0xFFD8A34E)];
    case 'Bodycare':
      return const [Color(0xFFE9E0FF), Color(0xFF9D87C7)];
    case 'Fragrance':
      return const [Color(0xFFE0F4FF), Color(0xFF7EB3CF)];
    default:
      return const [Color(0xFFF2ECE7), Color(0xFFB99182)];
  }
}
