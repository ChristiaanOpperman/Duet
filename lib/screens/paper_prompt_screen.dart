import 'package:flutter/material.dart';

import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';
import '../widgets/couple_chip.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/progress_dots.dart';
import '../widgets/quiz_card.dart';
import '../widgets/score_pill.dart';

/// Pen & paper: the question sits on screen for the whole room while the pair
/// write. Nothing is secret here — the answerer and the guesser both read the
/// same card, which is why this mode needs no handoff gates.
class PaperPromptScreen extends StatelessWidget {
  const PaperPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final theme = Theme.of(context);
    final turn = game.currentTurn;
    final accent = AppGradients.forCouple(turn.coupleIndex).colors.first;

    return GradientScaffold(
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlowButton(
            label: 'Both written — reveal together',
            icon: Icons.visibility_rounded,
            onPressed: game.revealOnPaper,
          ),
          const SizedBox(height: Insets.s + 4),
          Text(
            'Turn your papers over at the same time.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Insets.m),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Couple ${game.currentCoupleNumber} of ${game.coupleCount}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              ScorePill(points: game.pointsFor(turn.coupleId), compact: true),
            ],
          ),
          const SizedBox(height: Insets.m),
          ProgressDots(
            count: game.guessBlockLength,
            index: game.guessIndexInBlock,
            activeColour: accent,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Insets.l),
                  QuizCard(
                    glow: accent,
                    padding: const EdgeInsets.all(Insets.l + 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(turn.question.category.icon,
                                size: 15, color: AppColors.cyan),
                            const SizedBox(width: Insets.s),
                            SectionLabel(turn.question.category.label,
                                colour: AppColors.cyan),
                          ],
                        ),
                        const SizedBox(height: Insets.m),
                        Text(
                          turn.presenterPrompt,
                          style: theme.textTheme.displaySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Insets.l),
                  _WhoWritesWhat(
                    answerer: turn.answerer.name,
                    guesser: turn.guesser.name,
                    coupleIndex: turn.coupleIndex,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The instruction that makes the mode work: who writes the truth and who
/// writes the guess. Without it the pair have to remember the rule each turn.
class _WhoWritesWhat extends StatelessWidget {
  const _WhoWritesWhat({
    required this.answerer,
    required this.guesser,
    required this.coupleIndex,
  });

  final String answerer;
  final String guesser;
  final int coupleIndex;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Instruction(
              name: answerer,
              what: 'writes the answer',
              icon: Icons.person_rounded,
              coupleIndex: coupleIndex,
              colour: AppColors.magenta,
            ),
          ),
          const SizedBox(width: Insets.s + 4),
          Expanded(
            child: _Instruction(
              name: guesser,
              what: 'writes the guess',
              icon: Icons.psychology_alt_rounded,
              coupleIndex: coupleIndex,
              colour: AppColors.cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction({
    required this.name,
    required this.what,
    required this.icon,
    required this.coupleIndex,
    required this.colour,
  });

  final String name;
  final String what;
  final IconData icon;
  final int coupleIndex;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return QuizCard(
      colour: AppColors.surface,
      borderColour: colour.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.m,
        vertical: Insets.m,
      ),
      radius: Radii.button,
      child: Column(
        children: [
          PlayerAvatar(name: name, coupleIndex: coupleIndex, size: 36),
          const SizedBox(height: Insets.s + 2),
          Text(
            name,
            style: theme.textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Insets.xs),
          Text(
            what,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colour),
          ),
        ],
      ),
    );
  }
}
