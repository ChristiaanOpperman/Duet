import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The app's one card shape. Everything that needs to sit above the backdrop
/// uses this so radii, borders and shadows never drift apart.
class QuizCard extends StatelessWidget {
  const QuizCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Insets.l),
    this.colour = AppColors.surfaceRaised,
    this.borderColour = AppColors.hairline,
    this.glow,
    this.radius = Radii.card,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color colour;
  final Color borderColour;
  final Color? glow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColour),
        boxShadow: [
          BoxShadow(
            color: (glow ?? Colors.black).withValues(alpha: glow == null ? 0.35 : 0.34),
            blurRadius: glow == null ? 24 : 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Small uppercase label used above cards and section headers.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.colour});

  final String text;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(color: colour ?? AppColors.textMuted),
    );
  }
}
