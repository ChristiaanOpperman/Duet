import 'package:flutter/material.dart';

import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/gradient_text.dart';
import '../widgets/quiz_card.dart';
import '../widgets/standings_list.dart';

/// Final standings, with the winning couple given the full treatment.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final theme = Theme.of(context);
    final standings = game.standings;
    final winner = game.winner;
    final draw = game.isDraw;

    return Stack(
      children: [
        GradientScaffold(
          bottomBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlowButton(
                label: 'Play again',
                icon: Icons.replay_rounded,
                onPressed: game.playAgain,
              ),
              const SizedBox(height: Insets.s),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'New teams',
                      icon: Icons.group_add_rounded,
                      onPressed: game.newGame,
                    ),
                  ),
                  const SizedBox(width: Insets.s),
                  Expanded(
                    child: GhostButton(
                      label: 'Home',
                      icon: Icons.home_rounded,
                      onPressed: game.quitToHome,
                    ),
                  ),
                ],
              ),
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.only(bottom: Insets.l),
            children: [
              const SizedBox(height: Insets.xl),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        size: 56, color: AppColors.gold),
                    const SizedBox(height: Insets.m),
                    SectionLabel(
                      draw ? "It's a tie" : 'Winning couple',
                      colour: AppColors.gold,
                    ),
                    const SizedBox(height: Insets.s + 4),
                    if (winner != null)
                      GradientText(
                        draw ? 'Dead heat!' : winner.couple.displayName,
                        textAlign: TextAlign.center,
                        gradient: draw
                            ? AppGradients.cool
                            : AppGradients.forCouple(winner.index),
                        style: theme.textTheme.displayMedium,
                      ),
                    const SizedBox(height: Insets.m),
                    if (winner != null)
                      Text(
                        draw
                            ? 'Level on ${winner.points} points — '
                                'you know each other equally well.'
                            : '${winner.points} points · '
                                '${winner.correct} of ${winner.total} guessed right',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Insets.xl),
              if (standings.length > 1) ...[
                const SectionLabel('Final standings'),
                const SizedBox(height: Insets.m),
                StandingsList(standings: standings, showRankMedals: true),
                const SizedBox(height: Insets.l),
              ],
              const _BiggestGap(),
            ],
          ),
        ),
        const Positioned.fill(child: ConfettiBurst(play: true, count: 140)),
      ],
    );
  }
}

/// A small closing note: the question that caught the most couples out. It's
/// the thing people actually talk about after the game ends.
class _BiggestGap extends StatelessWidget {
  const _BiggestGap();

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final theme = Theme.of(context);

    final missed = game.turns.where((turn) => turn.correct == false).toList();
    if (missed.isEmpty) {
      return QuizCard(
        colour: AppColors.surface,
        child: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: AppColors.magenta),
            const SizedBox(width: Insets.m),
            Expanded(
              child: Text(
                'Not a single wrong answer all night. Suspicious.',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      );
    }

    // The question that tripped up the most people.
    final byQuestion = <String, List<int>>{};
    for (var i = 0; i < missed.length; i++) {
      byQuestion.putIfAbsent(missed[i].question.id, () => []).add(i);
    }
    final hardestId = byQuestion.entries
        .reduce((a, b) => b.value.length > a.value.length ? b : a)
        .key;
    final hardest =
        missed.firstWhere((turn) => turn.question.id == hardestId);
    final missCount = byQuestion[hardestId]!.length;

    return QuizCard(
      colour: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Hardest question of the night'),
          const SizedBox(height: Insets.s + 2),
          Text(hardest.question.selfPrompt, style: theme.textTheme.titleLarge),
          const SizedBox(height: Insets.s),
          Text(
            missCount == 1
                ? 'Missed once'
                : 'Missed $missCount times',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
