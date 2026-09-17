import 'package:flutter/material.dart';

import '../models/couple.dart';
import '../models/turn.dart';
import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';
import '../widgets/couple_chip.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/page_header.dart';
import '../widgets/quiz_card.dart';
import '../widgets/standings_list.dart';

/// Reviews one archived game: the standings, then every question with what was
/// answered and what was guessed. This is the only place the answers are
/// visible after their reveal, so it stays readable rather than clever.
class RecapScreen extends StatelessWidget {
  const RecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final record = game.openRecord;
    final theme = Theme.of(context);

    if (record == null) {
      // Nothing open — shouldn't happen, but never strand the user here.
      return GradientScaffold(
        bottomBar: GlowButton(label: 'Back', onPressed: game.closeRecap),
        child: const SizedBox.shrink(),
      );
    }

    final played = record.playedTurns.length;

    return GradientScaffold(
      bottomBar: GlowButton(
        label: 'Done',
        icon: Icons.check_rounded,
        onPressed: game.closeRecap,
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: Insets.l),
        children: [
          PageHeader(
            title: 'Game ${record.number}',
            eyebrow: 'Recap · ${_clock(record.playedAt)}',
            onBack: game.closeRecap,
          ),
          const SizedBox(height: Insets.m),
          Text(
            '${record.mode.label} · ${record.questionsPerPlayer} questions '
            'each · ${record.pointsPerCorrect} pts per correct · '
            '${record.correctCount} of $played guessed right',
            style: theme.textTheme.bodyMedium,
          ),
          if (record.mode.isPaper) ...[
            const SizedBox(height: Insets.s + 2),
            Text(
              'Answers were written on paper, so only the verdicts were '
              'recorded.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
          if (!record.isComplete) ...[
            const SizedBox(height: Insets.m),
            _UnfinishedNotice(remaining: record.turns.length - played),
          ],
          const SizedBox(height: Insets.l),
          StandingsList(standings: record.standings, showRankMedals: true),
          const SizedBox(height: Insets.xl),
          const SectionLabel('Every answer'),
          const SizedBox(height: Insets.m),
          for (var i = 0; i < record.couples.length; i++)
            _CoupleSection(
              couple: record.couples[i],
              index: i,
              turns: record.turnsFor(record.couples[i].id),
              pointsPerCorrect: record.pointsPerCorrect,
              showWrittenAnswers: !record.mode.isPaper,
            ),
        ],
      ),
    );
  }
}

/// 24-hour clock without pulling in `intl` for one string.
String _clock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

class _UnfinishedNotice extends StatelessWidget {
  const _UnfinishedNotice({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.m,
        vertical: Insets.s + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.button),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_outline_rounded,
              size: 18, color: AppColors.gold),
          const SizedBox(width: Insets.s),
          Expanded(
            child: Text(
              'Unfinished — $remaining '
              '${remaining == 1 ? 'question' : 'questions'} never played.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoupleSection extends StatelessWidget {
  const _CoupleSection({
    required this.couple,
    required this.index,
    required this.turns,
    required this.pointsPerCorrect,
    required this.showWrittenAnswers,
  });

  final Couple couple;
  final int index;
  final List<Turn> turns;
  final int pointsPerCorrect;
  final bool showWrittenAnswers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.m),
          child: CoupleChip(couple: couple, index: index),
        ),
        for (final turn in turns) ...[
          _TurnCard(
            turn: turn,
            coupleIndex: index,
            pointsPerCorrect: pointsPerCorrect,
            showWrittenAnswers: showWrittenAnswers,
          ),
          const SizedBox(height: Insets.s + 4),
        ],
        const SizedBox(height: Insets.l),
      ],
    );
  }
}

class _TurnCard extends StatelessWidget {
  const _TurnCard({
    required this.turn,
    required this.coupleIndex,
    required this.pointsPerCorrect,
    required this.showWrittenAnswers,
  });

  final Turn turn;
  final int coupleIndex;
  final int pointsPerCorrect;

  /// False for paper games, where the app never saw what was written.
  final bool showWrittenAnswers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correct = turn.correct;
    final accent = AppGradients.forCouple(coupleIndex).colors.first;

    return QuizCard(
      colour: AppColors.surface,
      padding: const EdgeInsets.all(Insets.m + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(turn.question.category.icon, size: 14, color: accent),
              const SizedBox(width: Insets.s),
              Expanded(
                child: SectionLabel(turn.question.category.label,
                    colour: accent),
              ),
              _VerdictChip(correct: correct, points: pointsPerCorrect),
            ],
          ),
          const SizedBox(height: Insets.s + 4),
          Text(turn.question.selfPrompt, style: theme.textTheme.titleLarge),
          if (showWrittenAnswers) ...[
            const SizedBox(height: Insets.m),
            _Line(
              who: turn.answerer.name,
              verb: 'said',
              text: turn.answer,
              colour: AppColors.textPrimary,
            ),
            const SizedBox(height: Insets.s),
            _Line(
              who: turn.guesser.name,
              verb: 'guessed',
              text: correct == null ? '—' : turn.guess,
              colour: switch (correct) {
                true => AppColors.mint,
                false => AppColors.coral,
                null => AppColors.textMuted,
              },
            ),
          ] else ...[
            const SizedBox(height: Insets.s),
            Text(
              '${turn.answerer.name} answered · ${turn.guesser.name} guessed',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.who,
    required this.verb,
    required this.text,
    required this.colour,
  });

  final String who;
  final String verb;
  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            '$who $verb',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: Insets.s),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(color: colour),
          ),
        ),
      ],
    );
  }
}

class _VerdictChip extends StatelessWidget {
  const _VerdictChip({required this.correct, required this.points});

  final bool? correct;
  final int points;

  @override
  Widget build(BuildContext context) {
    if (correct == null) {
      return Text(
        'Not played',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.textMuted),
      );
    }

    final hit = correct!;
    final colour = hit ? AppColors.mint : AppColors.coral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.s + 2, vertical: 3),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: colour.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hit ? Icons.check_rounded : Icons.close_rounded,
              size: 13, color: colour),
          const SizedBox(width: 3),
          Text(
            hit ? '+$points' : '0',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: colour, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
