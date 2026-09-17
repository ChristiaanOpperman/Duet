import 'package:flutter/material.dart';

import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/page_header.dart';
import '../widgets/quiz_card.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _steps = [
    (
      '1',
      'Set up your couples',
      'Up to six couples. Everyone plays on this one device, so keep it on the table.',
    ),
    (
      '2',
      'Pick how you write',
      'Classic: the phone goes round and everyone types their answers in secret, then types their guesses. Pen & paper: nothing is typed — the question goes on screen and the pair write on paper.',
    ),
    (
      '3',
      'Guess your partner',
      'One of you writes the true answer, the other writes what they think it is. Reveal at the same time.',
    ),
    (
      '4',
      'Reveal and score',
      'Classic shows both answers side by side. On paper you show each other. Either way the host calls it: close enough scores, way off does not.',
    ),
    (
      '5',
      'Crown a couple',
      'Points go to the pair, not the person. Highest total takes the trophy.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final theme = Theme.of(context);

    return GradientScaffold(
      bottomBar: GlowButton(
        label: 'Got it',
        onPressed: game.goHome,
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: Insets.l),
        children: [
          PageHeader(
            title: 'How to play',
            eyebrow: 'The rules',
            onBack: game.goHome,
          ),
          const SizedBox(height: Insets.l),
          for (final (number, title, body) in _steps) ...[
            QuizCard(
              padding: const EdgeInsets.all(Insets.m + 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      number,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: Insets.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleLarge),
                        const SizedBox(height: Insets.xs),
                        Text(body, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.s + 4),
          ],
          const SizedBox(height: Insets.s),
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded,
                  size: 18, color: AppColors.gold),
              const SizedBox(width: Insets.s),
              Expanded(
                child: Text(
                  'Host tip: be generous. "Macademia" still counts.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.gold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
