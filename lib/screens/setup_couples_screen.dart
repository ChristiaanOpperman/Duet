import 'package:flutter/material.dart';

import '../models/game_settings.dart';
import '../state/game_controller.dart';
import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';
import '../widgets/duet_text_field.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/page_header.dart';
import '../widgets/quiz_card.dart';

/// Step 1: how many couples, and who they are.
class SetupCouplesScreen extends StatefulWidget {
  const SetupCouplesScreen({super.key});

  @override
  State<SetupCouplesScreen> createState() => _SetupCouplesScreenState();
}

class _SetupCouplesScreenState extends State<SetupCouplesScreen> {
  /// One pair of controllers per couple, kept in step with the couple count.
  final List<List<TextEditingController>> _fields = [];

  @override
  void initState() {
    super.initState();
    final game = GameScope.read(context);
    for (final couple in game.couples) {
      _fields.add([
        TextEditingController(text: couple.partnerA.name),
        TextEditingController(text: couple.partnerB.name),
      ]);
    }
  }

  @override
  void dispose() {
    for (final pair in _fields) {
      for (final controller in pair) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _syncFields(GameController game) {
    while (_fields.length < game.couples.length) {
      final couple = game.couples[_fields.length];
      _fields.add([
        TextEditingController(text: couple.partnerA.name),
        TextEditingController(text: couple.partnerB.name),
      ]);
    }
    while (_fields.length > game.couples.length) {
      for (final controller in _fields.removeLast()) {
        controller.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    _syncFields(game);
    final theme = Theme.of(context);

    return GradientScaffold(
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!game.namesAreUnique)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.s),
              child: Text(
                'Every player needs a different name.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.coral),
              ),
            ),
          GlowButton(
            label: 'Next: game options',
            icon: Icons.arrow_forward_rounded,
            onPressed: game.couplesAreNamed && game.namesAreUnique
                ? game.goToOptionsSetup
                : null,
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: Insets.l),
        children: [
          PageHeader(
            title: "Who's playing?",
            eyebrow: 'Step 1 of 2',
            onBack: game.goHome,
          ),
          const SizedBox(height: Insets.l),
          _CoupleCounter(
            count: game.couples.length,
            onChanged: game.setCoupleCount,
          ),
          const SizedBox(height: Insets.l),
          for (var i = 0; i < game.couples.length; i++) ...[
            _CoupleCard(
              index: i,
              nameA: _fields[i][0],
              nameB: _fields[i][1],
              onChanged: (isPartnerA, value) => game.setPlayerName(
                coupleIndex: i,
                isPartnerA: isPartnerA,
                name: value,
              ),
            ),
            const SizedBox(height: Insets.m),
          ],
        ],
      ),
    );
  }
}

class _CoupleCounter extends StatelessWidget {
  const _CoupleCounter({required this.count, required this.onChanged});

  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return QuizCard(
      colour: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.l,
        vertical: Insets.m,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Couples', style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  '${GameSettings.minCouples}–${GameSettings.maxCouples} teams',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: count > GameSettings.minCouples
                ? () => onChanged(count - 1)
                : null,
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: count < GameSettings.maxCouples
                ? () => onChanged(count + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? AppColors.surfaceRaised
          : AppColors.surfaceRaised.withValues(alpha: 0.4),
      shape: const CircleBorder(side: BorderSide(color: AppColors.hairline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Insets.s + 2),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _CoupleCard extends StatelessWidget {
  const _CoupleCard({
    required this.index,
    required this.nameA,
    required this.nameB,
    required this.onChanged,
  });

  final int index;
  final TextEditingController nameA;
  final TextEditingController nameB;
  final void Function(bool isPartnerA, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final gradient = AppGradients.forCouple(index);
    return QuizCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Insets.s + 2),
              SectionLabel('Couple ${index + 1}',
                  colour: gradient.colors.first),
            ],
          ),
          const SizedBox(height: Insets.m),
          DuetTextField(
            controller: nameA,
            hint: 'First partner',
            textInputAction: TextInputAction.next,
            maxLength: 16,
            onChanged: (value) => onChanged(true, value),
          ),
          const SizedBox(height: Insets.s + 2),
          Row(
            children: [
              Expanded(child: Container(height: 1, color: AppColors.hairline)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.s + 2),
                child: Icon(Icons.favorite_rounded,
                    size: 14, color: gradient.colors.first),
              ),
              Expanded(child: Container(height: 1, color: AppColors.hairline)),
            ],
          ),
          const SizedBox(height: Insets.s + 2),
          DuetTextField(
            controller: nameB,
            hint: 'Second partner',
            textInputAction: TextInputAction.next,
            maxLength: 16,
            onChanged: (value) => onChanged(false, value),
          ),
        ],
      ),
    );
  }
}
