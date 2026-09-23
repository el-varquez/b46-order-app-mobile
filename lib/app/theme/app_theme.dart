import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData get light => _theme(
    brightness: Brightness.light,
    background: PopColors.cream,
    surface: PopColors.paper,
    foreground: PopColors.ink,
    outline: PopColors.muted,
  );

  static ThemeData get dark => _theme(
    brightness: Brightness.dark,
    background: PopColors.ink,
    surface: PopColors.inkSoft,
    foreground: PopColors.cream,
    outline: PopColors.brownSoft,
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color foreground,
    required Color outline,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: PopColors.brandRed,
      brightness: brightness,
      primary: PopColors.brandRed,
      onPrimary: PopColors.white,
      surface: surface,
      onSurface: foreground,
      outline: outline,
    );
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PopRadius.md),
          side: BorderSide(color: outline.withValues(alpha: 0.35)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PopRadius.sm),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PopRadius.sm),
          borderSide: BorderSide(color: outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PopRadius.sm),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
