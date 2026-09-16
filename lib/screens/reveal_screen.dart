import 'package:flutter/material.dart';

import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/quiz_card.dart';

/// The payoff. The guess settles first, then the real answer drops in, then
/// the host calls it. Everything is driven off one controller so the beats
/// stay in step.
class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key});

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  late final Animation<double> _guessIn = _interval(0.00, 0.28);
  late final Animation<double> _labelIn = _interval(0.34, 0.52);
  late final Animation<double> _answerIn = CurvedAnimation(
    parent: _reveal,
    curve: const Interval(0.50, 0.88, curve: Curves.easeOutBack),
  );
  late final Animation<double> _actionsIn = _interval(0.84, 1.0);

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
        parent: _reveal,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final theme = Theme.of(context);
    final turn = game.currentTurn;
    final judged = turn.correct;

    return Stack(
      children: [
        GradientScaffold(
          bottomBar: FadeTransition(
            opacity: _actionsIn,
            child: judged == null
                ? _JudgeButtons(
                    onCorrect: () => game.judge(correct: true),
                    onWrong: () => game.judge(correct: false),
                  )
                : GlowButton(
                    label: 'Next',
                    icon: Icons.arrow_forward_rounded,
                    gradient: judged
                        ? AppGradients.correct
                        : AppGradients.primary,
                    glow: judged ? AppColors.mint : AppColors.violet,
                    onPressed: game.advanceAfterReveal,
                  ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Insets.l),
                Text(
                  turn.presenterPrompt,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: Insets.xl),
                _Rise(
                  animation: _guessIn,
                  child: _AnswerBlock(
                    label: '${turn.guesser.name} guessed',
                    text: turn.guess,
                    colour: AppColors.textSecondary,
                    borderColour: AppColors.hairline,
                    dim: judged != null,
                  ),
                ),
                const SizedBox(height: Insets.l),
                FadeTransition(
                  opacity: _labelIn,
                  child: Column(
                    children: [
                      Container(
                        width: 2,
                        height: 22,
                        color: AppColors.hairlineStrong,
                      ),
                      const SizedBox(height: Insets.m),
                      Text(
                        'The real answer',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: Insets.m),
                    ],
                  ),
                ),
                ScaleTransition(
                  scale: _answerIn,
                  child: FadeTransition(
                    opacity: _interval(0.50, 0.70),
                    child: _AnswerBlock(
                      label: '${turn.answerer.name} said',
                      text: turn.answer,
                      colour: AppColors.textPrimary,
                      borderColour: AppColors.magenta.withValues(alpha: 0.55),
                      glow: AppColors.magenta,
                      big: true,
                    ),
                  ),
                ),
                const SizedBox(height: Insets.l),
                if (judged == null)
                  FadeTransition(
                    opacity: _actionsIn,
                    child: Text(
                      "Host's call — close enough counts.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  )
                else
                  _Verdict(
                    correct: judged,
                    points: game.settings.pointsPerCorrect,
                    coupleName: game.currentCouple.displayName,
                  ),
                const SizedBox(height: Insets.l),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: ConfettiBurst(play: judged == true),
        ),
      ],
    );
  }
}

/// Fade + slide up, the app's standard entrance.
class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({
    required this.label,
    required this.text,
    required this.colour,
    required this.borderColour,
    this.glow,
    this.big = false,
    this.dim = false,
  });

  final String label;
  final String text;
  final Color colour;
  final Color borderColour;
  final Color? glow;
  final bool big;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: dim ? 0.55 : 1,
      child: QuizCard(
        colour: big ? AppColors.surfaceRaised : AppColors.surface,
        borderColour: borderColour,
        glow: glow,
        padding: EdgeInsets.symmetric(
          horizontal: Insets.l,
          vertical: big ? Insets.l + 4 : Insets.m + 4,
        ),
        child: Column(
          children: [
            Text(label.toUpperCase(), style: theme.textTheme.labelMedium),
            const SizedBox(height: Insets.s + 2),
            Text(
              text,
              textAlign: TextAlign.center,
              style: (big
                      ? theme.textTheme.displaySmall
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(color: colour),
            ),
          ],
        ),
      ),
    );
  }
}

class _JudgeButtons extends StatelessWidget {
  const _JudgeButtons({required this.onCorrect, required this.onWrong});

  final VoidCallback onCorrect;
  final VoidCallback onWrong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlowButton(
            label: 'Not quite',
            icon: Icons.close_rounded,
            gradient: AppGradients.wrong,
            glow: AppColors.coral,
            onPressed: onWrong,
          ),
        ),
        const SizedBox(width: Insets.s + 4),
        Expanded(
          child: GlowButton(
            label: 'Correct',
            icon: Icons.check_rounded,
            gradient: AppGradients.correct,
            glow: AppColors.mint,
            onPressed: onCorrect,
          ),
        ),
      ],
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({
    required this.correct,
    required this.points,
    required this.coupleName,
  });

  final bool correct;
  final int points;
  final String coupleName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = correct ? AppColors.mint : AppColors.coral;

    return TweenAnimationBuilder<double>(
      key: ValueKey(correct),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: 0.85 + 0.15 * value.clamp(0.0, 1.2),
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.l,
          vertical: Insets.m,
        ),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Radii.button),
          border: Border.all(color: colour.withValues(alpha: 0.45)),
        ),
        child: Column(
          children: [
            Icon(
              correct ? Icons.celebration_rounded : Icons.favorite_border_rounded,
              color: colour,
              size: 26,
            ),
            const SizedBox(height: Insets.s),
            Text(
              correct ? 'Nailed it!' : 'So close…',
              style: theme.textTheme.headlineSmall?.copyWith(color: colour),
            ),
            const SizedBox(height: Insets.xs),
            Text(
              correct
                  ? '+$points points for $coupleName'
                  : 'No points this time',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
