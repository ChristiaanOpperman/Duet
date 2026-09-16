import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gradient tokens. [primary] is the app's signature fill — it appears on the
/// logo lockup, primary buttons and the winner podium, so it should stay the
/// only place magenta meets violet.
abstract final class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.magenta, AppColors.violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cool = LinearGradient(
    colors: [AppColors.violet, AppColors.cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const correct = LinearGradient(
    colors: [AppColors.mint, Color(0xFF23B0C9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const wrong = LinearGradient(
    colors: [AppColors.coral, Color(0xFFB03B7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const podium = LinearGradient(
    colors: [AppColors.gold, Color(0xFFFF7A45)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backdrop = LinearGradient(
    colors: [AppColors.night, AppColors.nightDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// One distinct gradient per couple (up to the 6 the game supports) so teams
  /// stay tellable apart on the scoreboard at a glance.
  static const couples = <LinearGradient>[
    LinearGradient(
      colors: [Color(0xFFFF4D9D), Color(0xFFFF7A45)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF7B5CFF), Color(0xFF41E0FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF3DDC97), Color(0xFF1FA7C4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFFC53D), Color(0xFFFF6B6B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF9C6BFF), Color(0xFFFF4D9D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF41E0FF), Color(0xFF3DDC97)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static LinearGradient forCouple(int index) =>
      couples[index % couples.length];
}
