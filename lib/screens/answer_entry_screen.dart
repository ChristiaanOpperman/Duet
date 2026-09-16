import 'package:flutter/material.dart';

import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/duet_text_field.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/progress_dots.dart';
import '../widgets/quiz_card.dart';

/// Private answer entry. The phase router keys this screen by player and
/// question, so each question gets a fresh controller and a fresh entrance
/// animation rather than the text of the previous answer.
class AnswerEntryScreen extends StatefulWidget {
  const AnswerEntryScreen({super.key});

  @override
  State<AnswerEntryScreen> createState() => _AnswerEntryScreenState();
}

class _AnswerEntryScreenState extends State<AnswerEntryScreen> {
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
    final turn = game.currentAnswerTurn;
    final isLast = game.answerQuestionIndex == game.answerQuestionCount - 1;

    void submit() {
      if (_controller.text.trim().isEmpty) return;
      game.submitAnswer(_controller.text);
    }

    return GradientScaffold(
      bottomBar: ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, value, _) => GlowButton(
          label: isLast ? 'Done — hide the screen' : 'Next question',
          icon: isLast ? Icons.lock_rounded : Icons.arrow_forward_rounded,
          onPressed: value.text.trim().isEmpty ? null : submit,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Insets.m),
          Row(
            children: [
              const Icon(Icons.visibility_off_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: Insets.s),
              Expanded(
                child: Text(
                  '${game.currentAnswerer.name} only — keep it hidden',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.m),
          ProgressDots(
            count: game.answerQuestionCount,
            index: game.answerQuestionIndex,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Insets.xl),
                  Row(
                    children: [
                      Icon(turn.question.category.icon,
                          size: 15, color: AppColors.magenta),
                      const SizedBox(width: Insets.s),
                      SectionLabel(
                        turn.question.category.label,
                        colour: AppColors.magenta,
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.m),
                  Text(
                    turn.question.selfPrompt,
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: Insets.xl),
                  DuetTextField(
                    controller: _controller,
                    hint: 'Your answer',
                    autofocus: true,
                    large: true,
                    maxLength: 60,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: Insets.m),
                  Text(
                    'Keep it short — your partner has to guess it word for word.',
                    style: theme.textTheme.bodyMedium,
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
