import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "Question 2 of 5" made visual. The active dot stretches into a bar so the
/// position is readable at a glance from across the room.
class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.count,
    required this.index,
    this.activeColour = AppColors.magenta,
  });

  final int count;
  final int index;
  final Color activeColour;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: i == index ? 26 : 6,
            decoration: BoxDecoration(
              color: i == index
                  ? activeColour
                  : i < index
                      ? activeColour.withValues(alpha: 0.45)
                      : AppColors.hairlineStrong,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
      ],
    );
  }
}
