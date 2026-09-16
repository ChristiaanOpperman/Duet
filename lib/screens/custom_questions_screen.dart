import 'package:flutter/material.dart';

import '../data/partner_prompt.dart';
import '../models/question.dart';
import '../state/game_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/duet_text_field.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/page_header.dart';
import '../widgets/quiz_card.dart';

/// Write your own questions for this session.
///
/// The awkward part of authoring a question here is the second voice: the app
/// has to ask the partner about someone by name. Rather than make the author
/// think in templates, the partner prompt is derived from what they type and
/// shown as an editable field with a live preview using a real player's name.
class CustomQuestionsScreen extends StatefulWidget {
  const CustomQuestionsScreen({super.key});

  @override
  State<CustomQuestionsScreen> createState() => _CustomQuestionsScreenState();
}

class _CustomQuestionsScreenState extends State<CustomQuestionsScreen> {
  final _selfController = TextEditingController();
  final _partnerController = TextEditingController();
  final _partnerFocus = FocusNode();

  /// True once the author edits the partner prompt by hand — after that we
  /// stop overwriting their wording on every keystroke.
  bool _partnerEditedByHand = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selfController.addListener(_syncPartnerPrompt);
  }

  @override
  void dispose() {
    _selfController.removeListener(_syncPartnerPrompt);
    _selfController.dispose();
    _partnerController.dispose();
    _partnerFocus.dispose();
    super.dispose();
  }

  void _syncPartnerPrompt() {
    if (_partnerEditedByHand) return;
    final derived = derivePartnerPrompt(_selfController.text);
    if (derived != _partnerController.text) {
      _partnerController.value = TextEditingValue(
        text: derived,
        selection: TextSelection.collapsed(offset: derived.length),
      );
    }
  }

  void _insertNameToken() {
    final text = _partnerController.text;
    final selection = _partnerController.selection;
    final at = selection.isValid ? selection.start : text.length;
    final updated = text.replaceRange(at, selection.isValid ? selection.end : at, nameToken);
    _partnerEditedByHand = true;
    _partnerController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: at + nameToken.length),
    );
    _partnerFocus.requestFocus();
    setState(() => _error = null);
  }

  void _add() {
    final self = _selfController.text.trim();
    final partner = _partnerController.text.trim();

    if (self.isEmpty) {
      setState(() => _error = 'Write the question first.');
      return;
    }
    if (partner.isEmpty) {
      setState(() => _error = 'The app needs a way to ask their partner.');
      return;
    }
    if (!hasNameToken(partner)) {
      setState(() => _error =
          'Put $nameToken where the name goes, so the app knows whose '
          'answer to ask about.');
      return;
    }

    GameScope.read(context)
        .addCustomQuestion(selfPrompt: self, partnerPrompt: partner);

    _selfController.clear();
    _partnerController.clear();
    _partnerEditedByHand = false;
    setState(() => _error = null);
    FocusScope.of(context).unfocus();
  }

  /// A real player's name makes the preview concrete; fall back to a
  /// placeholder before anyone has been named.
  String _previewName(List<String> names) =>
      names.firstWhere((name) => name.trim().isNotEmpty, orElse: () => 'Alex');

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final theme = Theme.of(context);
    final questions = game.customQuestions;
    final previewName = _previewName([
      for (final couple in game.couples)
        for (final player in couple.players) player.name,
    ]);

    return GradientScaffold(
      bottomBar: GlowButton(
        label: 'Done',
        icon: Icons.check_rounded,
        onPressed: game.goToOptionsSetup,
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: Insets.l),
        children: [
          PageHeader(
            title: 'Your own questions',
            eyebrow: 'This session',
            onBack: game.goToOptionsSetup,
          ),
          const SizedBox(height: Insets.m),
          Text(
            'Shuffled in with the 92 built-in questions. Cleared when you '
            'close the app.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Insets.l),
          QuizCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DuetTextField(
                  controller: _selfController,
                  label: 'The question they answer',
                  hint: 'What is your favourite nut?',
                  maxLength: 90,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: Insets.m),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'THEIR PARTNER HEARS',
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                    _TokenButton(onTap: _insertNameToken),
                  ],
                ),
                const SizedBox(height: Insets.s),
                DuetTextField(
                  controller: _partnerController,
                  focusNode: _partnerFocus,
                  hint: "What is $nameToken's favourite nut?",
                  maxLength: 90,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    _partnerEditedByHand = true;
                    setState(() => _error = null);
                  },
                  onSubmitted: (_) => _add(),
                ),
                if (_partnerController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: Insets.m),
                  _Preview(
                    text: _partnerController.text.replaceAll(
                      nameToken,
                      previewName,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: Insets.m),
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.coral),
                  ),
                ],
                const SizedBox(height: Insets.l),
                GlowButton(
                  label: 'Add question',
                  icon: Icons.add_rounded,
                  onPressed: _add,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          if (questions.isEmpty)
            const _EmptyState()
          else ...[
            SectionLabel('Added this session · ${questions.length}'),
            const SizedBox(height: Insets.m),
            for (final question in questions) ...[
              _CustomQuestionCard(
                question: question,
                previewName: previewName,
                onRemove: () => game.removeCustomQuestion(question.id),
              ),
              const SizedBox(height: Insets.s + 4),
            ],
          ],
        ],
      ),
    );
  }
}

class _TokenButton extends StatelessWidget {
  const _TokenButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Insets.s + 2, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
        ),
        child: Text(
          '+ $nameToken',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: AppColors.cyan, fontSize: 12),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.m),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.field),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THEY WILL SEE', style: theme.textTheme.labelMedium),
          const SizedBox(height: Insets.s),
          Text(
            text,
            style: theme.textTheme.titleLarge?.copyWith(color: AppColors.cyan),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const Icon(Icons.edit_note_rounded, size: 40, color: AppColors.textMuted),
        const SizedBox(height: Insets.m),
        Text(
          'Nothing added yet',
          style: theme.textTheme.titleLarge
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: Insets.s),
        Text(
          'Your questions get shuffled in with the 92 that ship with the app.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _CustomQuestionCard extends StatelessWidget {
  const _CustomQuestionCard({
    required this.question,
    required this.previewName,
    required this.onRemove,
  });

  final Question question;
  final String previewName;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return QuizCard(
      colour: AppColors.surface,
      padding: const EdgeInsets.all(Insets.m + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.selfPrompt, style: theme.textTheme.titleLarge),
                const SizedBox(height: Insets.s),
                Text(
                  question.promptAbout(previewName),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: Insets.s),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.textMuted,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
