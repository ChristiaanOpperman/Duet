import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Spacing scale (8pt) and radii used across the app. Screens should reach for
/// these instead of hard-coding numbers so the rhythm stays consistent.
abstract final class Insets {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Horizontal page gutter.
  static const gutter = 24.0;

  /// The app is phone-first; on a wide window we keep it phone-shaped.
  static const maxContentWidth = 480.0;
}

abstract final class Radii {
  static const card = 28.0;
  static const button = 20.0;
  static const field = 18.0;
  static const pill = 999.0;
}

abstract final class AppTheme {
  static ThemeData build() {
    const scheme = ColorScheme.dark(
      primary: AppColors.violet,
      onPrimary: Colors.white,
      secondary: AppColors.magenta,
      onSecondary: Colors.white,
      tertiary: AppColors.cyan,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.coral,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.night,
      textTheme: AppTypography.textTheme,
      fontFamily: AppTypography.body,
      splashFactory: InkSparkle.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.magenta,
        selectionColor: Color(0x55FF4D9D),
        selectionHandleColor: AppColors.magenta,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: AppTypography.textTheme.titleMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
        ),
      ),
    );
  }
}
