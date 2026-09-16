import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'quiz_card.dart';

/// Consistent top-of-page block: optional back affordance, an uppercase
/// eyebrow for context ("Round 2 of 3") and the page title.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null)
              _CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack!),
            if (onBack != null) const SizedBox(width: Insets.m),
            const Spacer(),
            ?trailing,
          ],
        ),
        const SizedBox(height: Insets.l),
        if (eyebrow != null) ...[
          SectionLabel(eyebrow!, colour: AppColors.magenta),
          const SizedBox(height: Insets.s),
        ],
        Text(title, style: Theme.of(context).textTheme.displaySmall),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.8),
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back_rounded,
              size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
