import 'package:flutter/material.dart';

import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/gradient_text.dart';
import '../widgets/quiz_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final theme = Theme.of(context);

    return GradientScaffold(
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlowButton(
            label: game.isLoading ? 'Loading questions…' : 'Start a game',
            icon: Icons.play_arrow_rounded,
            onPressed: game.isLoading || game.loadError != null
                ? null
                : game.goToCouplesSetup,
          ),
          const SizedBox(height: Insets.s),
          GhostButton(
            label: 'How to play',
            icon: Icons.help_outline_rounded,
            onPressed: game.showHowToPlay,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          const DuetMark(size: 104),
          const SizedBox(height: Insets.xl),
          GradientText('Duet', style: theme.textTheme.displayLarge),
          const SizedBox(height: Insets.m),
          Text(
            'How well do you really\nknow each other?',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const Spacer(flex: 2),
          if (game.loadError != null)
            QuizCard(
              colour: AppColors.coral.withValues(alpha: 0.12),
              borderColour: AppColors.coral.withValues(alpha: 0.4),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.coral),
                  const SizedBox(height: Insets.s),
                  Text(
                    "The question pack couldn't be loaded.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    '${game.loadError}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else
            const _HowItWorksStrip(),
          const Spacer(),
        ],
      ),
    );
  }
}

/// A three-beat summary so a first-time host knows the shape of the game
/// before pressing start.
class _HowItWorksStrip extends StatelessWidget {
  const _HowItWorksStrip();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.lock_outline_rounded, 'Answer\nin secret'),
      (Icons.record_voice_over_rounded, 'Guess your\npartner'),
      (Icons.emoji_events_rounded, 'Win\nbragging rights'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final (icon, label) in steps)
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(Insets.m),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Icon(icon, color: AppColors.magenta, size: 22),
                ),
                const SizedBox(height: Insets.s + 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
