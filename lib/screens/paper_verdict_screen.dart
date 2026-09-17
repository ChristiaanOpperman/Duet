import 'package:flutter/material.dart';

import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/quiz_card.dart';

/// Pen & paper: the pair have shown each other their papers. The app never saw
/// either answer, so it cannot reveal anything — it only asks the host for the
/// verdict and keeps the score.
class PaperVerdictScreen extends StatefulWidget {
  const PaperVerdictScreen({super.key});

  @override
  State<PaperVerdictScreen> createState() => _PaperVerdictScreenState();
}

class _PaperVerdictScreenState extends State<PaperVerdictScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _pop = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
  );
  late final Animation<double> _actions = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0.55, 1, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _enter.dispose();
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
            opacity: _actions,
            child: judged == null
                ? Row(
                    children: [
                      Expanded(
                        child: GlowButton(
                          label: 'Not quite',
                          icon: Icons.close_rounded,
                          gradient: AppGradients.wrong,
                          glow: AppColors.coral,
                          onPressed: () => game.judge(correct: false),
                        ),
                      ),
                      const SizedBox(width: Insets.s + 4),
                      Expanded(
                        child: GlowButton(
                          label: 'Matched',
                          icon: Icons.check_rounded,
                          gradient: AppGradients.correct,
                          glow: AppColors.mint,
                          onPressed: () => game.judge(correct: true),
                        ),
                      ),
                    ],
                  )
                : GlowButton(
                    label: 'Next',
                    icon: Icons.arrow_forward_rounded,
                    gradient:
                        judged ? AppGradients.correct : AppGradients.primary,
                    glow: judged ? AppColors.mint : AppColors.violet,
                    onPressed: game.advanceAfterReveal,
                  ),
          ),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _pop,
                child: Column(
                  children: [
                    Text(
                      turn.presenterPrompt,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: Insets.xl),
                    Text(
                      'Show each other',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: Insets.m),
                    Text(
                      'Did ${turn.guesser.name} get '
                      "${turn.answerer.name}'s answer?",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Insets.xl),
              if (judged == null)
                FadeTransition(
                  opacity: _actions,
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
              const Spacer(),
            ],
          ),
        ),
        Positioned.fill(child: ConfettiBurst(play: judged == true)),
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
      child: QuizCard(
        colour: colour.withValues(alpha: 0.14),
        borderColour: colour.withValues(alpha: 0.45),
        radius: Radii.button,
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.l,
          vertical: Insets.m,
        ),
        child: Column(
          children: [
            Icon(
              correct
                  ? Icons.celebration_rounded
                  : Icons.favorite_border_rounded,
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
              correct ? '+$points for $coupleName' : 'No points this time',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
