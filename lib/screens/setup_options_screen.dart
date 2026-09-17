import 'package:flutter/material.dart';

import '../data/question_dealer.dart';
import '../models/game_settings.dart';
import '../models/question.dart';
import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/page_header.dart';
import '../widgets/quiz_card.dart';

/// Step 2: length, scoring and which categories are in play.
class SetupOptionsScreen extends StatelessWidget {
  const SetupOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final theme = Theme.of(context);
    final settings = game.settings;
    final available = game.eligibleQuestions.length;
    final needed =
        QuestionDealer.minimumPoolSize(settings.questionsPerPlayer);
    final playerCount = game.couples.length * 2;
    final turnCount = playerCount * settings.questionsPerPlayer;

    return GradientScaffold(
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!game.hasEnoughQuestions)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.s),
              child: Text(
                'Turn on more categories — $needed questions needed, '
                '$available available.',
                textAlign: TextAlign.center,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: AppColors.coral),
              ),
            ),
          GlowButton(
            label: 'Start the game',
            icon: Icons.play_arrow_rounded,
            onPressed: game.canStartGame ? game.startGame : null,
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: Insets.l),
        children: [
          PageHeader(
            title: 'Game options',
            eyebrow: 'Step 2 of 2',
            onBack: game.goToCouplesSetup,
          ),
          const SizedBox(height: Insets.l),
          QuizCard(
            colour: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Questions each'),
                const SizedBox(height: Insets.s + 4),
                _Segmented(
                  options: GameSettings.questionCountOptions,
                  selected: settings.questionsPerPlayer,
                  onChanged: game.setQuestionsPerPlayer,
                ),
                const SizedBox(height: Insets.s + 4),
                Text(
                  '$playerCount players · $turnCount questions in total',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.m),
          QuizCard(
            colour: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Points per correct'),
                      const SizedBox(height: Insets.xs + 2),
                      Text(
                        'Awarded to the couple, not the player.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _PointsStepper(
                  value: settings.pointsPerCorrect,
                  onChanged: game.setPointsPerCorrect,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.m),
          _CustomQuestionsRow(
            count: game.customQuestions.length,
            onTap: game.goToCustomQuestions,
          ),
          const SizedBox(height: Insets.m),
          QuizCard(
            colour: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Categories'),
                const SizedBox(height: Insets.s + 4),
                Wrap(
                  spacing: Insets.s - 2,
                  runSpacing: Insets.s - 2,
                  children: [
                    for (final category in QuestionCategory.values)
                      if (category != QuestionCategory.custom ||
                          game.customQuestions.isNotEmpty)
                          _CategoryChip(
                          category: category,
                          selected: settings.categories.contains(category),
                          onTap: () => game.toggleCategory(category),
                        ),
                  ],
                ),
                const SizedBox(height: Insets.m),
                Text(
                  '$available questions in the pool',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<int> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.field),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: option == selected
                        ? AppColors.violet
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.field - 4),
                  ),
                  child: Text(
                    '$option',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: option == selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PointsStepper extends StatelessWidget {
  const _PointsStepper({required this.value, required this.onChanged});

  static const _step = 5;
  static const _min = 5;
  static const _max = 50;

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TinyButton(
          icon: Icons.remove_rounded,
          onTap: value > _min ? () => onChanged(value - _step) : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.gold),
          ),
        ),
        _TinyButton(
          icon: Icons.add_rounded,
          onTap: value < _max ? () => onChanged(value + _step) : null,
        ),
      ],
    );
  }
}

class _TinyButton extends StatelessWidget {
  const _TinyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceRaised,
      shape: const CircleBorder(side: BorderSide(color: AppColors.hairline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Insets.s),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final QuestionCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.s + 4,
          vertical: Insets.s + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.magenta.withValues(alpha: 0.18)
              : AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(
            color: selected ? AppColors.magenta : AppColors.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 15,
              color: selected ? AppColors.magenta : AppColors.textMuted,
            ),
            const SizedBox(width: Insets.xs + 2),
            Text(
              category.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entry point to the custom-question writer. Shows the running count so the
/// host can see at a glance whether anything has been added.
class _CustomQuestionsRow extends StatelessWidget {
  const _CustomQuestionsRow({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: QuizCard(
        colour: AppColors.surface,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Your own questions'),
                  const SizedBox(height: Insets.xs + 2),
                  Text(
                    count == 0
                        ? 'Write questions just for this group.'
                        : '$count added · shuffled in with the rest',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Insets.s),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.s + 2,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Radii.pill),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: AppColors.cyan, fontSize: 12),
                ),
              ),
            const SizedBox(width: Insets.s),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
