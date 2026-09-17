import 'package:flutter/material.dart';

import 'screens/answer_entry_screen.dart';
import 'screens/custom_questions_screen.dart';
import 'screens/guess_screen.dart';
import 'screens/handoff_screen.dart';
import 'screens/home_screen.dart';
import 'screens/how_to_play_screen.dart';
import 'screens/paper_prompt_screen.dart';
import 'screens/paper_verdict_screen.dart';
import 'screens/recap_screen.dart';
import 'screens/results_screen.dart';
import 'screens/reveal_screen.dart';
import 'screens/scoreboard_screen.dart';
import 'screens/setup_couples_screen.dart';
import 'screens/setup_options_screen.dart';
import 'state/game_controller.dart';
import 'state/game_phase.dart';
import 'state/game_scope.dart';
import 'theme/app_theme.dart';

class DuetApp extends StatefulWidget {
  const DuetApp({super.key, this.controller});

  /// Injectable so tests and previews can drive a pre-built game.
  final GameController? controller;

  @override
  State<DuetApp> createState() => _DuetAppState();
}

class _DuetAppState extends State<DuetApp> {
  late final GameController _controller = widget.controller ?? GameController();
  late final bool _ownsController = widget.controller == null;

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: GameScope(
        controller: _controller,
        child: const _PhaseRouter(),
      ),
    );
  }
}

/// Maps [GamePhase] to a screen. Transitions slide and fade so moving through
/// the game reads as one continuous flow rather than a stack of pages.
class _PhaseRouter extends StatelessWidget {
  const _PhaseRouter();

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(_screenKey(game)),
        child: _screenFor(game.phase),
      ),
    );
  }

  /// Guessing and answering screens must re-animate on every question, not
  /// just when the phase changes, so their key carries the position too.
  String _screenKey(GameController game) => switch (game.phase) {
        GamePhase.answering =>
          'answering-${game.currentAnswerer.id}-${game.answerQuestionIndex}',
        GamePhase.answerHandoff => 'answer-handoff-${game.currentAnswerer.id}',
        GamePhase.guessing => 'guessing-${game.currentTurn.question.id}'
            '-${game.currentTurn.guesser.id}',
        GamePhase.guessHandoff => 'guess-handoff-${game.currentTurn.guesser.id}',
        GamePhase.reveal => 'reveal-${game.currentTurn.question.id}'
            '-${game.currentTurn.guesser.id}',
        GamePhase.recap => 'recap-${game.openRecord?.number}',
        GamePhase.paperPrompt => 'paper-${game.currentTurn.question.id}'
            '-${game.currentTurn.guesser.id}',
        GamePhase.paperVerdict => 'paper-verdict-'
            '${game.currentTurn.question.id}-${game.currentTurn.guesser.id}',
        _ => game.phase.name,
      };

  Widget _screenFor(GamePhase phase) => switch (phase) {
        GamePhase.home => const HomeScreen(),
        GamePhase.howToPlay => const HowToPlayScreen(),
        GamePhase.setupCouples => const SetupCouplesScreen(),
        GamePhase.setupOptions => const SetupOptionsScreen(),
        GamePhase.customQuestions => const CustomQuestionsScreen(),
        GamePhase.answerHandoff => const HandoffScreen(mode: HandoffMode.answer),
        GamePhase.answering => const AnswerEntryScreen(),
        GamePhase.guessHandoff => const HandoffScreen(mode: HandoffMode.guess),
        GamePhase.guessing => const GuessScreen(),
        GamePhase.reveal => const RevealScreen(),
        GamePhase.scoreboard => const ScoreboardScreen(),
        GamePhase.results => const ResultsScreen(),
        GamePhase.recap => const RecapScreen(),
        GamePhase.paperPrompt => const PaperPromptScreen(),
        GamePhase.paperVerdict => const PaperVerdictScreen(),
      };
}
