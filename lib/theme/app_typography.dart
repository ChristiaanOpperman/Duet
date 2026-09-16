import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Outfit carries headings and anything the room reads from across a table;
/// Inter carries body copy, fields and labels.
abstract final class AppTypography {
  static const display = 'Outfit';
  static const body = 'Inter';

  static const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: display,
      fontSize: 52,
      fontWeight: FontWeight.w800,
      height: 1.05,
      letterSpacing: -1.5,
      color: AppColors.textPrimary,
    ),
    displayMedium: TextStyle(
      fontFamily: display,
      fontSize: 40,
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: -1,
      color: AppColors.textPrimary,
    ),
    displaySmall: TextStyle(
      fontFamily: display,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.5,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: display,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.3,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontFamily: display,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: display,
      fontSize: 19,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: body,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: body,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textSecondary,
    ),
    bodyMedium: TextStyle(
      fontFamily: body,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: body,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.2,
      color: AppColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontFamily: body,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 1.4,
      color: AppColors.textMuted,
    ),
  );
}
