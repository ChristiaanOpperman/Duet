import 'package:flutter/material.dart';

import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';
import '../widgets/couple_chip.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/hold_button.dart';
import '../widgets/quiz_card.dart';

enum HandoffMode { answer, guess }

/// The privacy gate between players. It names exactly who should be holding
/// the phone, and requires a deliberate press-and-hold so nobody taps through
/// by accident and sees questions meant for someone else.
class HandoffScreen extends StatelessWidget {
  const HandoffScreen({super.key, required this.mode});

  final HandoffMode mode;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final theme = Theme.of(context);

    final isAnswering = mode == HandoffMode.answer;
    final player =
        isAnswering ? game.currentAnswerer : game.currentTurn.guesser;
    final coupleIndex = isAnswering
        ? game.couples.indexWhere((c) => c.contains(player))
        : game.currentTurn.coupleIndex;

    final eyebrow = isAnswering
        ? 'Player ${game.answererNumber} of ${game.answererCount}'
        : 'Couple ${game.currentCoupleNumber} of ${game.coupleCount}';

    final headline = isAnswering
        ? 'Pass the phone\nto ${player.name}'
        : "${player.name}, guess\n${game.currentTurn.answerer.name}'s answers";

    final blurb = isAnswering
        ? "${player.name} answers ${game.settings.questionsPerPlayer} questions about "
            'themselves. Everyone else — eyes away.'
        : 'No peeking at the answers. Say it out loud if you like, '
            'then type your best guess.';

    return GradientScaffold(
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HoldButton(
            label: "I'm ${player.name} — hold to start",
            gradient: AppGradients.forCouple(coupleIndex),
            onComplete:
                isAnswering ? game.beginAnswering : game.beginGuessing,
          ),
          const SizedBox(height: Insets.s + 4),
          Text(
            'Press and hold so nobody opens this by accident.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            padding: const EdgeInsets.all(Insets.s),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hairlineStrong),
            ),
            child: PlayerAvatar(
              name: player.name,
              coupleIndex: coupleIndex < 0 ? 0 : coupleIndex,
              size: 96,
            ),
          ),
          const SizedBox(height: Insets.l),
          SectionLabel(eyebrow, colour: AppColors.magenta),
          const SizedBox(height: Insets.s + 4),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: Insets.m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.s),
            child: Text(
              blurb,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
