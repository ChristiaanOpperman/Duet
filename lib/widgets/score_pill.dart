import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Score readout. [ScorePill] animates between values so points landing after
/// a correct guess are visibly counted up rather than just replaced.
class ScorePill extends StatelessWidget {
  const ScorePill({
    super.key,
    required this.points,
    this.colour = AppColors.gold,
    this.icon = Icons.star_rounded,
    this.compact = false,
  });

  final int points;
  final Color colour;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Insets.s + 2 : Insets.m,
        vertical: compact ? 4 : Insets.s,
      ),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: colour.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 18, color: colour),
          const SizedBox(width: Insets.xs + 2),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: points.toDouble(), end: points.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              value.round().toString(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colour,
                    fontSize: compact ? 13 : 16,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Counts from one value to another — used on the scoreboard so a couple's
/// total visibly ticks up after their round.
class CountingScore extends StatelessWidget {
  const CountingScore({
    super.key,
    required this.value,
    this.style,
  });

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        v.round().toString(),
        style: style ?? Theme.of(context).textTheme.displaySmall,
      ),
    );
  }
}
