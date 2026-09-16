import 'package:flutter/material.dart';

/// The Duet palette. Deep violet night, hot magenta accents, high contrast.
abstract final class AppColors {
  // Backdrop
  static const night = Color(0xFF120E24);
  static const nightDeep = Color(0xFF07050F);

  // Surfaces
  static const surface = Color(0xFF211A3D);
  static const surfaceRaised = Color(0xFF2C2350);
  static const surfaceSunken = Color(0xFF191331);

  // Brand
  static const violet = Color(0xFF7B5CFF);
  static const magenta = Color(0xFFFF4D9D);
  static const cyan = Color(0xFF41E0FF);

  // Semantic
  static const mint = Color(0xFF3DDC97);
  static const coral = Color(0xFFFF5C7A);
  static const gold = Color(0xFFFFC53D);

  // Type
  static const textPrimary = Color(0xFFF6F3FF);
  static const textSecondary = Color(0xFFA99DD2);
  static const textMuted = Color(0xFF6F6597);

  // Lines
  static const hairline = Color(0x1AFFFFFF);
  static const hairlineStrong = Color(0x33FFFFFF);
}
