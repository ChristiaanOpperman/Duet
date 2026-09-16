import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';
import 'couple_chip.dart';
import 'score_pill.dart';

/// The leaderboard, shared by the between-rounds scoreboard and the final
/// results. Bars are scaled against the leader so the gap is readable without
/// doing the arithmetic.
class StandingsList extends StatelessWidget {
  const StandingsList({
    super.key,
    required this.standings,
    this.highlightCoupleId,
    this.showRankMedals = false,
  });

  final List<Standing> standings;

  /// Drawn with a brighter border — the couple who just played.
  final String? highlightCoupleId;
  final bool showRankMedals;

  @override
  Widget build(BuildContext context) {
    final leader = standings.isEmpty
        ? 0
        : standings.map((s) => s.points).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (var rank = 0; rank < standings.length; rank++) ...[
          _StandingRow(
            standing: standings[rank],
            rank: rank,
            leaderPoints: leader,
            highlighted: standings[rank].couple.id == highlightCoupleId,
            showMedal: showRankMedals,
          ),
          if (rank < standings.length - 1) const SizedBox(height: Insets.s + 4),
        ],
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.standing,
    required this.rank,
    required this.leaderPoints,
    required this.highlighted,
    required this.showMedal,
  });

  final Standing standing;
  final int rank;
  final int leaderPoints;
  final bool highlighted;
  final bool showMedal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = AppGradients.forCouple(standing.index);
    final fraction = leaderPoints == 0 ? 0.0 : standing.points / leaderPoints;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(Insets.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.button),
        border: Border.all(
          color: highlighted ? gradient.colors.first : AppColors.hairline,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 26,
                child: showMedal && rank < 3
                    ? Icon(
                        Icons.emoji_events_rounded,
                        size: 20,
                        color: switch (rank) {
                          0 => AppColors.gold,
                          1 => const Color(0xFFC6CBE0),
                          _ => const Color(0xFFCD8B5A),
                        },
                      )
                    : Text(
                        '${rank + 1}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: AppColors.textMuted),
                      ),
              ),
              const SizedBox(width: Insets.s),
              Expanded(
                child: CoupleChip(
                  couple: standing.couple,
                  index: standing.index,
                ),
              ),
              const SizedBox(width: Insets.s),
              ScorePill(points: standing.points),
            ],
          ),
          const SizedBox(height: Insets.s + 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: Stack(
                    children: [
                      Container(height: 8, color: AppColors.surfaceSunken),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 750),
                        curve: Curves.easeOutCubic,
                        widthFactor: fraction.clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(gradient: gradient),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Insets.m),
              Text(
                '${standing.correct}/${standing.total}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
