import 'dart:io';
import 'dart:math';

import 'package:duet/app.dart';
import 'package:duet/data/question_repository.dart';
import 'package:duet/models/game_mode.dart';
import 'package:duet/models/question.dart';
import 'package:duet/state/game_controller.dart';
import 'package:duet/state/game_phase.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders every screen at phone size and compares it against a checked-in
/// PNG. These are design regressions, not logic tests — regenerate with
/// `flutter test --update-goldens` after a deliberate style change.
void main() {
  // Asset I/O has to happen outside a testWidgets body — awaiting rootBundle
  // inside the fake-async zone of a second test never completes.
  late final List<Question> pack;

  setUpAll(() async {
    await _loadAppFonts();
    pack = await QuestionRepository().load();
  });

  Future<GameController> game({
    int couples = 3,
    int questionsPerPlayer = 3,
  }) async {
    final controller = GameController(
      repository: _PreloadedRepository(pack),
      now: () => DateTime(2026, 9, 16, 20, 15),
    );
    await controller.init();
    controller.setCoupleCount(couples);
    controller.setQuestionsPerPlayer(questionsPerPlayer);
    const names = [
      ['Alex', 'Sam'],
      ['Jo', 'Riley'],
      ['Nina', 'Theo'],
    ];
    for (var i = 0; i < couples; i++) {
      controller.setPlayerName(
          coupleIndex: i, isPartnerA: true, name: names[i][0]);
      controller.setPlayerName(
          coupleIndex: i, isPartnerA: false, name: names[i][1]);
    }
    return controller;
  }

  /// Fills in every secret answer so the game reaches the guessing rounds.
  /// Answers are varied so the recap screenshot shows real-looking content
  /// rather than the same word twenty times.
  void answerEverything(GameController controller) {
    var i = 0;
    while (controller.phase != GamePhase.guessHandoff) {
      if (controller.phase == GamePhase.answerHandoff) {
        controller.beginAnswering();
        continue;
      }
      controller.submitAnswer(_answers[i++ % _answers.length]);
    }
  }

  Future<void> shoot(
    WidgetTester tester,
    GameController controller,
    String name, {
    double scroll = 0,
    Future<void> Function(WidgetTester tester)? afterPump,
  }) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(DuetApp(controller: controller));
    // The backdrop blooms loop forever, so settle by hand rather than with
    // pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 1200));

    if (afterPump != null) {
      await afterPump(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    if (scroll != 0) {
      await tester.drag(find.byType(ListView).last, Offset(0, -scroll));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    await expectLater(
      find.byType(DuetApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('home', (tester) async {
    await shoot(tester, await game(), 'home');
  });

  testWidgets('how to play', (tester) async {
    final controller = await game()..showHowToPlay();
    await shoot(tester, controller, 'how_to_play');
  });

  testWidgets('setup couples', (tester) async {
    final controller = await game()..goToCouplesSetup();
    await shoot(tester, controller, 'setup_couples');
  });

  testWidgets('setup options', (tester) async {
    final controller = await game()..goToOptionsSetup();
    await shoot(tester, controller, 'setup_options');
  });

  testWidgets('custom questions, empty', (tester) async {
    final controller = await game()..goToCustomQuestions();
    await shoot(tester, controller, 'custom_questions_empty');
  });

  testWidgets('custom questions with entries', (tester) async {
    final controller = await game();
    controller.addCustomQuestion(
      selfPrompt: 'What is your favourite nut?',
      partnerPrompt: "What is {name}'s favourite nut?",
    );
    controller.addCustomQuestion(
      selfPrompt: 'Which of my friends would you save first?',
      partnerPrompt: "Which of {name}'s friends would you save first?",
    );
    controller.goToCustomQuestions();
    await shoot(tester, controller, 'custom_questions');
  });

  testWidgets('custom question being written', (tester) async {
    final controller = await game()..goToCustomQuestions();
    await shoot(
      tester,
      controller,
      'custom_questions_writing',
      afterPump: (tester) async {
        // Types only the first field: the partner prompt and the preview
        // underneath it should both derive themselves.
        await tester.enterText(
          find.byType(TextField).first,
          'What do you do when you cannot sleep?',
        );
      },
    );
  });

  testWidgets('paper prompt', (tester) async {
    final controller = await game();
    controller.setMode(GameMode.paper);
    controller.startGame(random: Random(1));
    await shoot(tester, controller, 'paper_prompt');
  });

  testWidgets('paper verdict, awaiting the call', (tester) async {
    final controller = await game();
    controller.setMode(GameMode.paper);
    controller.startGame(random: Random(1));
    controller.revealOnPaper();
    await shoot(tester, controller, 'paper_verdict');
  });

  testWidgets('paper verdict, matched', (tester) async {
    final controller = await game();
    controller.setMode(GameMode.paper);
    controller.startGame(random: Random(1));
    controller.revealOnPaper();
    controller.judge(correct: true);
    await shoot(tester, controller, 'paper_verdict_matched');
  });

  testWidgets('setup options scrolled to the categories', (tester) async {
    final controller = await game()..goToOptionsSetup();
    await shoot(tester, controller, 'setup_options_categories', scroll: 700);
  });

  testWidgets('answer handoff', (tester) async {
    final controller = await game();
    controller.startGame(random: Random(1));
    await shoot(tester, controller, 'answer_handoff');
  });

  testWidgets('answer entry', (tester) async {
    final controller = await game();
    controller.startGame(random: Random(1));
    controller.beginAnswering();
    await shoot(tester, controller, 'answer_entry');
  });

  testWidgets('guess handoff', (tester) async {
    final controller = await game();
    controller.startGame(random: Random(1));
    answerEverything(controller);
    await shoot(tester, controller, 'guess_handoff');
  });

  testWidgets('guessing', (tester) async {
    final controller = await game();
    controller.startGame(random: Random(1));
    answerEverything(controller);
    controller.beginGuessing();
    await shoot(tester, controller, 'guessing');
  });

  testWidgets('reveal before judging', (tester) async {
    final controller = await game();
    controller.startGame(random: Random(1));
    answerEverything(controller);
    controller.beginGuessing();
    controller.submitGuess('Macadamia');
    await shoot(tester, controller, 'reveal');
  });

  testWidgets('reveal after a correct call', (tester) async {
    final controller = await game();
    controller.startGame(random: Random(1));
    answerEverything(controller);
    controller.beginGuessing();
    controller.submitGuess('Macadamia');
    controller.judge(correct: true);
    await shoot(tester, controller, 'reveal_correct');
  });

  testWidgets('scoreboard', (tester) async {
    final controller = await game();
    controller.startGame(random: Random(1));
    answerEverything(controller);
    _playUntil(controller, GamePhase.scoreboard);
    await shoot(tester, controller, 'scoreboard');
  });

  testWidgets('recap of a finished game', (tester) async {
    final controller = await game();
    controller.startGame(random: Random(1));
    answerEverything(controller);
    _playUntil(controller, GamePhase.results);
    controller.showRecap(controller.history.first);
    await shoot(tester, controller, 'recap');
  });

  testWidgets('recap scrolled to the answers', (tester) async {
    final controller = await game();
    controller.startGame(random: Random(1));
    answerEverything(controller);
    _playUntil(controller, GamePhase.results);
    controller.showRecap(controller.history.first);
    await shoot(tester, controller, 'recap_answers', scroll: 1100);
  });

  testWidgets('home with session history', (tester) async {
    final controller = await game();
    controller.startGame(random: Random(1));
    answerEverything(controller);
    _playUntil(controller, GamePhase.results);
    controller.quitToHome();
    await shoot(tester, controller, 'home_with_history');
  });

  testWidgets('results', (tester) async {
    final controller = await game();
    controller.startGame(random: Random(1));
    answerEverything(controller);
    _playUntil(controller, GamePhase.results);
    await shoot(tester, controller, 'results');
  });
}

const _answers = [
  'Macadamia',
  'Pistachio',
  'Rocky road',
  'Left side, always',
  'Three times',
  'Salt and vinegar',
  'The mountains',
  'Sunday morning',
  'Flat white',
  'Camping, obviously',
];

const _guesses = [
  'Macadamia',
  'Cashew',
  'Rocky road',
  'The right side',
  'Twice',
  'Salt and vinegar',
  'The beach',
];

/// Plays the guessing rounds, marking a mix of right and wrong, until the
/// game reaches [target].
void _playUntil(GameController controller, GamePhase target) {
  var judged = 0;
  var guard = 0;
  while (controller.phase != target) {
    if (guard++ > 500) throw StateError('never reached $target');
    switch (controller.phase) {
      case GamePhase.guessHandoff:
        controller.beginGuessing();
      case GamePhase.guessing:
        controller.submitGuess(_guesses[guard % _guesses.length]);
      case GamePhase.reveal:
        controller.judge(correct: judged++ % 3 != 0);
        controller.advanceAfterReveal();
      case GamePhase.scoreboard:
        controller.continueFromScoreboard();
      default:
        throw StateError('unexpected phase ${controller.phase}');
    }
  }
}

/// Serves the real bundled pack without touching the asset bundle again.
class _PreloadedRepository extends QuestionRepository {
  _PreloadedRepository(this.questions);

  final List<Question> questions;

  @override
  Future<List<Question>> load() async => questions;
}

Future<void> _loadAppFonts() async {
  const families = {
    'Outfit': [
      'assets/fonts/Outfit-Regular.ttf',
      'assets/fonts/Outfit-SemiBold.ttf',
      'assets/fonts/Outfit-Bold.ttf',
      'assets/fonts/Outfit-ExtraBold.ttf',
    ],
    'Inter': [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
      'assets/fonts/Inter-Bold.ttf',
    ],
  };

  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(
        File(path).readAsBytes().then((bytes) => bytes.buffer.asByteData()),
      );
    }
    await loader.load();
  }

  // flutter_tester runs with --disable-asset-fonts, so the icon font has to be
  // loaded by hand or every icon renders as an empty box in the goldens.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!icons.existsSync()) return;
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(icons.readAsBytes().then((bytes) => bytes.buffer.asByteData()));
  await iconLoader.load();
}
