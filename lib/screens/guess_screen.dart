import 'package:flutter/material.dart';

import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';
import '../widgets/duet_text_field.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/progress_dots.dart';
import '../widgets/quiz_card.dart';
import '../widgets/score_pill.dart';

/// The presenter asks the question in the second person and the guessing
/// partner types what they think their other half said.
class GuessScreen extends StatefulWidget {
  const GuessScreen({super.key});

  @override
  State<GuessScreen> createState() => _GuessScreenState();
}

class _GuessScreenState extends State<GuessScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final theme = Theme.of(context);
    final turn = game.currentTurn;

    void submit() {
      if (_controller.text.trim().isEmpty) return;
      game.submitGuess(_controller.text);
    }

    return GradientScaffold(
      bottomBar: ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, value, _) => GlowButton(
          label: 'Lock it in',
          icon: Icons.lock_rounded,
          onPressed: value.text.trim().isEmpty ? null : submit,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Insets.m),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${turn.guesser.name} guessing for ${turn.answerer.name}',
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ScorePill(
                points: game.pointsFor(turn.coupleId),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: Insets.m),
          ProgressDots(
            count: game.guessBlockLength,
            index: game.guessIndexInBlock,
            activeColour: AppGradients.forCouple(turn.coupleIndex).colors.first,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Insets.xl),
                  QuizCard(
                    glow: AppGradients.forCouple(turn.coupleIndex).colors.first,
                    padding: const EdgeInsets.all(Insets.l + 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(turn.question.category.icon,
                                size: 15, color: AppColors.cyan),
                            const SizedBox(width: Insets.s),
                            SectionLabel(
                              turn.question.category.label,
                              colour: AppColors.cyan,
                            ),
                          ],
                        ),
                        const SizedBox(height: Insets.m),
                        Text(
                          turn.presenterPrompt,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Insets.xl),
                  DuetTextField(
                    controller: _controller,
                    label: 'Your guess',
                    hint: 'What did they say?',
                    autofocus: true,
                    large: true,
                    maxLength: 60,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
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
