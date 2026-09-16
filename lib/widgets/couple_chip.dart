import 'package:flutter/material.dart';

import '../models/couple.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';

/// A gradient disc with the player's initial. Couples share a gradient so the
/// two halves of a pair read as a team.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    required this.coupleIndex,
    this.size = 44,
  });

  final String name;
  final int coupleIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppGradients.forCouple(coupleIndex),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppGradients.forCouple(coupleIndex)
                .colors
                .first
                .withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: size * 0.42,
            ),
      ),
    );
  }
}

/// Both halves of a couple, overlapped, with the team name beside them.
class CoupleChip extends StatelessWidget {
  const CoupleChip({
    super.key,
    required this.couple,
    required this.index,
    this.trailing,
    this.avatarSize = 40,
  });

  final Couple couple;
  final int index;
  final Widget? trailing;

  /// Shrunk in tight rows (the scoreboard) so long pairs of names still fit
  /// before the ellipsis kicks in.
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: avatarSize * 1.75,
          height: avatarSize,
          child: Stack(
            children: [
              PlayerAvatar(
                name: couple.partnerA.name,
                coupleIndex: index,
                size: avatarSize,
              ),
              // Overlap only the outer edge — enough to read as a pair without
              // covering the first partner's initial.
              Positioned(
                left: avatarSize * 0.75,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: AppColors.surface, width: 2),
                    ),
                  ),
                  child: PlayerAvatar(
                    name: couple.partnerB.name,
                    coupleIndex: index,
                    size: avatarSize,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Insets.s + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                couple.displayName,
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
