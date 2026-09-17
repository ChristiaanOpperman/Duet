import 'dart:math';

import 'package:duet/data/question_repository.dart';
import 'package:duet/models/game_mode.dart';
import 'package:duet/models/question.dart';
import 'package:duet/state/game_controller.dart';
import 'package:duet/state/game_phase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the bundled pack so controller tests don't depend on its
/// exact contents. Like the real pack it never produces `custom` questions —
/// those only ever come from players writing them during a session.
class _FakeRepository extends QuestionRepository {
  _FakeRepository(this.count);

  static final _bundled = [
    for (final category in QuestionCategory.values)
      if (category != QuestionCategory.custom) category,
  ];

  final int count;

  @override
  Future<List<Question>> load() async => [
        for (var i = 0; i < count; i++)
          Question(
            id: 'q$i',
            category: _bundled[i % _bundled.length],
            selfPrompt: 'Self prompt $i?',
            partnerPrompt: "{name}'s prompt $i?",
          ),
      ];
}

Future<GameController> readyGame({
  int couples = 2,
  int questionsPerPlayer = 3,
  int poolSize = 60,
}) async {
  final game = GameController(repository: _FakeRepository(poolSize));
  await game.init();
  game.setCoupleCount(couples);
  game.setQuestionsPerPlayer(questionsPerPlayer);
  for (var i = 0; i < couples; i++) {
    game.setPlayerName(coupleIndex: i, isPartnerA: true, name: 'A$i');
    game.setPlayerName(coupleIndex: i, isPartnerA: false, name: 'B$i');
  }
  return game;
}

/// Fills in every secret answer, leaving the game at the first guess handoff.
void answerEverything(GameController game) {
  var guard = 0;
  while (game.phase != GamePhase.guessHandoff) {
    expect(guard++, lessThan(500), reason: 'answering did not terminate');
    if (game.phase == GamePhase.answerHandoff) {
      game.beginAnswering();
      continue;
    }
    final turn = game.currentAnswerTurn;
    game.submitAnswer('${turn.answerer.name}:${turn.question.id}');
  }
}

void main() {
  test('starts on home and needs names before it can start', () async {
    final game = GameController(repository: _FakeRepository(60));
    await game.init();
    expect(game.phase, GamePhase.home);
    expect(game.canStartGame, isFalse);

    game.setPlayerName(coupleIndex: 0, isPartnerA: true, name: 'Alex');
    expect(game.canStartGame, isFalse, reason: 'other players still unnamed');
  });

  test('rejects duplicate names', () async {
    final game = await readyGame();
    expect(game.canStartGame, isTrue);
    game.setPlayerName(coupleIndex: 1, isPartnerA: true, name: 'A0');
    expect(game.namesAreUnique, isFalse);
    expect(game.canStartGame, isFalse);
  });

  test('changing the couple count keeps the names already entered', () async {
    final game = await readyGame(couples: 3);
    expect(game.couples[1].partnerA.name, 'A1');
    game.setCoupleCount(2);
    game.setCoupleCount(3);
    expect(game.couples[1].partnerA.name, 'A1');
    expect(game.couples[2].partnerA.name, isEmpty, reason: 'new couple is blank');
  });

  test('a category with too few questions blocks the start', () async {
    final game = await readyGame(questionsPerPlayer: 7, poolSize: 8);
    // 8 questions across 4 categories -> 2 per category, far short of 14.
    for (final category in QuestionCategory.values.skip(1)) {
      game.toggleCategory(category);
    }
    expect(game.hasEnoughQuestions, isFalse);
    expect(game.canStartGame, isFalse);
  });

  test('the last category cannot be switched off', () async {
    final game = await readyGame();
    for (final category in QuestionCategory.values) {
      game.toggleCategory(category);
    }
    expect(game.settings.categories, isNotEmpty);
  });

  test('startGame builds one turn per player per question', () async {
    final game = await readyGame(couples: 3, questionsPerPlayer: 5);
    game.startGame(random: Random(1));

    expect(game.phase, GamePhase.answerHandoff);
    expect(game.turns.length, 3 * 2 * 5);
    expect(game.answererCount, 6);

    // Every turn is guessed by the answerer's partner, never themselves.
    for (final turn in game.turns) {
      expect(turn.guesser.id, isNot(turn.answerer.id));
      final couple = game.couples.firstWhere((c) => c.id == turn.coupleId);
      expect(couple.contains(turn.answerer), isTrue);
      expect(couple.contains(turn.guesser), isTrue);
    }
  });

  test('turns run couple by couple, one guesser at a time', () async {
    final game = await readyGame(couples: 3, questionsPerPlayer: 3);
    game.startGame(random: Random(2));

    final coupleOrder = game.turns.map((t) => t.coupleIndex).toList();
    expect(coupleOrder, List.generate(18, (i) => i ~/ 6));

    final guesserBlocks = <String>[];
    for (final turn in game.turns) {
      if (guesserBlocks.isEmpty || guesserBlocks.last != turn.guesser.id) {
        guesserBlocks.add(turn.guesser.id);
      }
    }
    expect(guesserBlocks.length, 6, reason: 'each player guesses in one block');
  });

  test('answering walks every player then hands off to guessing', () async {
    final game = await readyGame(couples: 2, questionsPerPlayer: 3);
    game.startGame(random: Random(3));
    answerEverything(game);

    expect(game.phase, GamePhase.guessHandoff);
    expect(game.turns.every((turn) => turn.isAnswered), isTrue);
  });

  test('a full playthrough scores only correct guesses', () async {
    final game = await readyGame(couples: 2, questionsPerPlayer: 3);
    game.setPointsPerCorrect(10);
    game.startGame(random: Random(4));
    answerEverything(game);

    // Couple 0 gets everything right; couple 1 gets nothing right.
    var guard = 0;
    while (game.phase != GamePhase.results) {
      expect(guard++, lessThan(500), reason: 'guessing did not terminate');
      switch (game.phase) {
        case GamePhase.guessHandoff:
          game.beginGuessing();
        case GamePhase.guessing:
          game.submitGuess('a guess');
        case GamePhase.reveal:
          game.judge(correct: game.currentTurn.coupleIndex == 0);
          game.advanceAfterReveal();
        case GamePhase.scoreboard:
          game.continueFromScoreboard();
        default:
          fail('unexpected phase ${game.phase}');
      }
    }

    final standings = game.standings;
    expect(standings.first.couple.id, game.couples[0].id);
    expect(standings.first.points, 6 * 10);
    expect(standings.first.correct, 6);
    expect(standings.last.points, 0);
    expect(game.isDraw, isFalse);
    expect(game.winner?.couple.id, game.couples[0].id);
  });

  test('the scoreboard appears between couples, not inside one', () async {
    final game = await readyGame(couples: 3, questionsPerPlayer: 2);
    game.startGame(random: Random(5));
    answerEverything(game);

    var scoreboards = 0;
    var handoffs = 0;
    var guard = 0;
    while (game.phase != GamePhase.results) {
      expect(guard++, lessThan(500));
      switch (game.phase) {
        case GamePhase.guessHandoff:
          handoffs++;
          game.beginGuessing();
        case GamePhase.guessing:
          game.submitGuess('g');
        case GamePhase.reveal:
          game.judge(correct: false);
          game.advanceAfterReveal();
        case GamePhase.scoreboard:
          scoreboards++;
          game.continueFromScoreboard();
        default:
          fail('unexpected phase ${game.phase}');
      }
    }

    expect(scoreboards, 2, reason: 'between three couples');
    expect(handoffs, 6, reason: 'one per guesser');
  });

  test('an all-square game reports a draw', () async {
    final game = await readyGame(couples: 2, questionsPerPlayer: 2);
    game.startGame(random: Random(6));
    answerEverything(game);

    var guard = 0;
    while (game.phase != GamePhase.results) {
      expect(guard++, lessThan(500));
      switch (game.phase) {
        case GamePhase.guessHandoff:
          game.beginGuessing();
        case GamePhase.guessing:
          game.submitGuess('g');
        case GamePhase.reveal:
          game.judge(correct: true);
          game.advanceAfterReveal();
        case GamePhase.scoreboard:
          game.continueFromScoreboard();
        default:
          fail('unexpected phase ${game.phase}');
      }
    }

    expect(game.isDraw, isTrue);
    expect(game.standings.every((s) => s.points == game.standings.first.points),
        isTrue);
  });

  test('play again keeps the couples and clears the old answers', () async {
    final game = await readyGame(couples: 2, questionsPerPlayer: 2);
    game.startGame(random: Random(7));
    answerEverything(game);
    final firstNames = game.couples.map((c) => c.displayName).toList();

    game.playAgain();
    expect(game.phase, GamePhase.answerHandoff);
    expect(game.couples.map((c) => c.displayName).toList(), firstNames);
    expect(game.turns.every((turn) => turn.answer.isEmpty), isTrue);
    expect(game.turns.every((turn) => turn.correct == null), isTrue);
  });

  test('quitting to home discards the round', () async {
    final game = await readyGame();
    game.startGame(random: Random(8));
    game.quitToHome();
    expect(game.phase, GamePhase.home);
    expect(game.turns, isEmpty);
  });

  test('a load failure is surfaced rather than thrown', () async {
    final game = GameController(repository: _BrokenRepository());
    await game.init();
    expect(game.isLoading, isFalse);
    expect(game.loadError, isNotNull);
  });

  group('session history', () {
    /// Plays the guessing rounds to the results screen, judging with [verdict].
    void playOut(GameController game, bool Function(int index) verdict) {
      var index = 0;
      var guard = 0;
      while (game.phase != GamePhase.results) {
        expect(guard++, lessThan(500));
        switch (game.phase) {
          case GamePhase.guessHandoff:
            game.beginGuessing();
          case GamePhase.guessing:
            game.submitGuess('guess-$index');
          case GamePhase.reveal:
            game.judge(correct: verdict(index++));
            game.advanceAfterReveal();
          case GamePhase.scoreboard:
            game.continueFromScoreboard();
          default:
            fail('unexpected phase ${game.phase}');
        }
      }
    }

    test('starts empty', () async {
      final game = await readyGame();
      expect(game.hasHistory, isFalse);
      expect(game.history, isEmpty);
    });

    test('a finished game is archived with its answers and guesses', () async {
      final game = await readyGame(couples: 2, questionsPerPlayer: 2);
      game.startGame(random: Random(11));
      answerEverything(game);
      playOut(game, (i) => i.isEven);

      expect(game.history, hasLength(1));
      final record = game.history.single;
      expect(record.number, 1);
      expect(record.isComplete, isTrue);
      expect(record.turns, hasLength(8));
      for (final turn in record.turns) {
        expect(turn.answer, isNotEmpty);
        expect(turn.guess, isNotEmpty);
        expect(turn.isJudged, isTrue);
      }
      expect(record.correctCount, 4);
      expect(record.questionsPerPlayer, 2);
      expect(record.pointsPerCorrect, game.settings.pointsPerCorrect);
    });

    test('the record scores exactly like the live game did', () async {
      final game = await readyGame(couples: 3, questionsPerPlayer: 2);
      game.startGame(random: Random(12));
      answerEverything(game);
      final live = [for (final s in game.standings) s.points];
      playOut(game, (i) => i % 3 != 0);

      final record = game.history.single;
      expect(
        [for (final s in record.standings) s.points],
        [for (final s in game.standings) s.points],
      );
      expect(live.every((points) => points == 0), isTrue,
          reason: 'sanity: nothing was scored before the guessing rounds');
    });

    test('reaching results archives once, not again on play again', () async {
      final game = await readyGame(couples: 2, questionsPerPlayer: 2);
      game.startGame(random: Random(13));
      answerEverything(game);
      playOut(game, (_) => true);

      expect(game.history, hasLength(1));
      game.playAgain();
      expect(game.history, hasLength(1), reason: 'no duplicate archive');
    });

    test('play again keeps the finished game readable', () async {
      final game = await readyGame(couples: 2, questionsPerPlayer: 2);
      game.startGame(random: Random(14));
      answerEverything(game);
      playOut(game, (_) => true);
      final firstAnswers = [for (final t in game.history.single.turns) t.answer];

      game.playAgain();
      answerEverything(game);

      // The new game has blank guesses, but the archived one is untouched.
      expect(game.turns.every((t) => t.guess.isEmpty), isTrue);
      expect([for (final t in game.history.single.turns) t.answer],
          firstAnswers);
      expect(game.history.single.turns.every((t) => t.isJudged), isTrue);
    });

    test('two games this session produce two records, newest first', () async {
      final game = await readyGame(couples: 2, questionsPerPlayer: 2);
      game.startGame(random: Random(15));
      answerEverything(game);
      playOut(game, (_) => true);
      game.playAgain();
      answerEverything(game);
      playOut(game, (_) => false);

      expect(game.history, hasLength(2));
      expect(game.history.first.number, 2, reason: 'newest first');
      expect(game.history.last.number, 1);
      expect(game.history.first.correctCount, 0);
      expect(game.history.last.correctCount, 8);
    });

    test('quitting midway archives a partial game', () async {
      final game = await readyGame(couples: 2, questionsPerPlayer: 3);
      game.startGame(random: Random(16));
      answerEverything(game);
      game.beginGuessing();
      game.submitGuess('only one');
      game.judge(correct: true);
      game.advanceAfterReveal();
      game.quitToHome();

      expect(game.history, hasLength(1));
      final record = game.history.single;
      expect(record.isComplete, isFalse);
      expect(record.playedTurns, hasLength(1));
      expect(record.turns, hasLength(12), reason: 'unplayed turns are kept');
    });

    test('a game nobody judged is not archived', () async {
      final game = await readyGame();
      game.startGame(random: Random(17));
      answerEverything(game);
      game.quitToHome();
      expect(game.history, isEmpty);
    });

    test('the recap returns to wherever it was opened from', () async {
      final game = await readyGame(couples: 2, questionsPerPlayer: 2);
      game.startGame(random: Random(18));
      answerEverything(game);
      playOut(game, (_) => true);

      expect(game.phase, GamePhase.results);
      game.showRecap(game.history.single);
      expect(game.phase, GamePhase.recap);
      expect(game.openRecord, isNotNull);

      game.closeRecap();
      expect(game.phase, GamePhase.results);
      expect(game.openRecord, isNull);

      game.quitToHome();
      game.showRecap(game.history.single);
      game.closeRecap();
      expect(game.phase, GamePhase.home, reason: 'back to home this time');
    });
  });

  group('custom questions', () {
    test('start empty and are added to the pool', () async {
      final game = await readyGame();
      expect(game.customQuestions, isEmpty);
      // These two differ: spice is off by default, so the eligible pool is
      // smaller than everything the app knows about.
      final eligibleBefore = game.eligibleQuestions.length;
      final allBefore = game.allQuestions.length;
      expect(eligibleBefore, lessThan(allBefore));

      game.addCustomQuestion(
        selfPrompt: 'What is your favourite nut?',
        partnerPrompt: "What is {name}'s favourite nut?",
      );

      expect(game.customQuestions, hasLength(1));
      expect(game.eligibleQuestions.length, eligibleBefore + 1);
      expect(game.allQuestions.length, allBefore + 1);
    });

    test('are trimmed and given unique ids', () async {
      final game = await readyGame();
      game.addCustomQuestion(
        selfPrompt: '  Do you snore?  ',
        partnerPrompt: '  Does {name} snore?  ',
      );
      game.addCustomQuestion(
        selfPrompt: 'Do you snore?',
        partnerPrompt: 'Does {name} snore?',
      );

      final ids = game.customQuestions.map((q) => q.id).toSet();
      expect(ids, hasLength(2), reason: 'duplicate text still gets a new id');
      expect(game.customQuestions.first.selfPrompt, 'Do you snore?');
      expect(game.customQuestions.first.partnerPrompt, 'Does {name} snore?');
    });

    test('a partner prompt without the name token is rejected', () async {
      final game = await readyGame();
      expect(
        () => game.addCustomQuestion(
          selfPrompt: 'What is your favourite nut?',
          partnerPrompt: 'What is their favourite nut?',
        ),
        throwsArgumentError,
      );
      expect(game.customQuestions, isEmpty);
    });

    test('empty prompts are rejected', () async {
      final game = await readyGame();
      expect(
        () => game.addCustomQuestion(selfPrompt: '  ', partnerPrompt: '{name}?'),
        throwsArgumentError,
      );
      expect(
        () => game.addCustomQuestion(selfPrompt: 'Something?', partnerPrompt: ''),
        throwsArgumentError,
      );
    });

    test('adding one switches its category on', () async {
      final game = await readyGame();
      game.toggleCategory(QuestionCategory.custom);
      expect(game.settings.categories.contains(QuestionCategory.custom), isFalse);

      game.addCustomQuestion(
        selfPrompt: 'Do you snore?',
        partnerPrompt: 'Does {name} snore?',
      );

      expect(game.settings.categories.contains(QuestionCategory.custom), isTrue,
          reason: 'otherwise the question would silently never appear');
    });

    test('switching the category off excludes them from the pool', () async {
      final game = await readyGame();
      game.addCustomQuestion(
        selfPrompt: 'Do you snore?',
        partnerPrompt: 'Does {name} snore?',
      );
      final withCustom = game.eligibleQuestions.length;

      game.toggleCategory(QuestionCategory.custom);
      expect(game.eligibleQuestions.length, withCustom - 1);
      expect(
        game.eligibleQuestions.any((q) => q.category == QuestionCategory.custom),
        isFalse,
      );
    });

    test('removing one takes it back out of the pool', () async {
      final game = await readyGame();
      game.addCustomQuestion(
        selfPrompt: 'Do you snore?',
        partnerPrompt: 'Does {name} snore?',
      );
      final id = game.customQuestions.single.id;
      final withCustom = game.eligibleQuestions.length;

      game.removeCustomQuestion(id);
      expect(game.customQuestions, isEmpty);
      expect(game.eligibleQuestions.length, withCustom - 1);

      game.removeCustomQuestion('does-not-exist');
      expect(game.customQuestions, isEmpty, reason: 'unknown id is a no-op');
    });

    test('a game can be played entirely on custom questions', () async {
      final game = await readyGame(couples: 1, questionsPerPlayer: 3);
      for (final category in QuestionCategory.values) {
        if (category != QuestionCategory.custom &&
            game.settings.categories.contains(category)) {
          game.toggleCategory(category);
        }
      }
      for (var i = 0; i < 6; i++) {
        game.addCustomQuestion(
          selfPrompt: 'Custom question $i?',
          partnerPrompt: "{name}'s custom question $i?",
        );
      }

      expect(game.settings.categories, {QuestionCategory.custom});
      expect(game.hasEnoughQuestions, isTrue);
      expect(game.canStartGame, isTrue);

      game.startGame(random: Random(31));
      expect(game.turns, hasLength(6));
      expect(
        game.turns.every((t) => t.question.category == QuestionCategory.custom),
        isTrue,
      );
      // The invariant still holds for questions the players wrote.
      final a = game.turns
          .where((t) => t.answerer.id == game.couples.single.partnerA.id)
          .map((t) => t.question.id)
          .toSet();
      final b = game.turns
          .where((t) => t.answerer.id == game.couples.single.partnerB.id)
          .map((t) => t.question.id)
          .toSet();
      expect(a.intersection(b), isEmpty);
    });

    test('too few custom questions alone blocks the start', () async {
      final game = await readyGame(couples: 1, questionsPerPlayer: 3);
      for (final category in QuestionCategory.values) {
        if (category != QuestionCategory.custom &&
            game.settings.categories.contains(category)) {
          game.toggleCategory(category);
        }
      }
      game.addCustomQuestion(
        selfPrompt: 'Only one?',
        partnerPrompt: 'Only one for {name}?',
      );

      expect(game.hasEnoughQuestions, isFalse);
      expect(game.canStartGame, isFalse);
    });

    test('they survive across games in the session', () async {
      final game = await readyGame(couples: 2, questionsPerPlayer: 2);
      game.addCustomQuestion(
        selfPrompt: 'Do you snore?',
        partnerPrompt: 'Does {name} snore?',
      );
      game.startGame(random: Random(32));
      game.quitToHome();
      expect(game.customQuestions, hasLength(1));
      game.newGame();
      expect(game.customQuestions, hasLength(1));
    });
  });

  group('pen & paper mode', () {
    /// Plays a whole paper game, judging with [verdict]. Fails loudly if the
    /// game ever asks for typed input.
    void playPaper(GameController game, bool Function(int index) verdict) {
      var index = 0;
      var guard = 0;
      while (game.phase != GamePhase.results) {
        expect(guard++, lessThan(500));
        switch (game.phase) {
          case GamePhase.paperPrompt:
            game.revealOnPaper();
          case GamePhase.paperVerdict:
            game.judge(correct: verdict(index++));
            game.advanceAfterReveal();
          case GamePhase.scoreboard:
            game.continueFromScoreboard();
          default:
            fail('paper mode should never reach ${game.phase}');
        }
      }
    }

    test('starts straight on the first question, skipping answer entry',
        () async {
      final game = await readyGame(couples: 2, questionsPerPlayer: 3);
      game.setMode(GameMode.paper);
      game.startGame(random: Random(41));

      expect(game.isPaperMode, isTrue);
      expect(game.phase, GamePhase.paperPrompt,
          reason: 'no private answer round on paper');
      expect(game.turns, hasLength(12));
    });

    test('deals the same turn structure as a classic game', () async {
      final classic = await readyGame(couples: 3, questionsPerPlayer: 2);
      classic.startGame(random: Random(42));

      final paper = await readyGame(couples: 3, questionsPerPlayer: 2);
      paper.setMode(GameMode.paper);
      paper.startGame(random: Random(42));

      expect(
        paper.turns.map((t) => '${t.question.id}:${t.answerer.id}').toList(),
        classic.turns.map((t) => '${t.question.id}:${t.answerer.id}').toList(),
      );
    });

    test('never passes through a typing or handoff phase', () async {
      final game = await readyGame(couples: 2, questionsPerPlayer: 2);
      game.setMode(GameMode.paper);
      game.startGame(random: Random(43));

      final seen = <GamePhase>{};
      var guard = 0;
      while (game.phase != GamePhase.results) {
        expect(guard++, lessThan(500));
        seen.add(game.phase);
        switch (game.phase) {
          case GamePhase.paperPrompt:
            game.revealOnPaper();
          case GamePhase.paperVerdict:
            game.judge(correct: true);
            game.advanceAfterReveal();
          case GamePhase.scoreboard:
            game.continueFromScoreboard();
          default:
            fail('unexpected phase ${game.phase}');
        }
      }

      expect(
        seen.intersection({
          GamePhase.answerHandoff,
          GamePhase.answering,
          GamePhase.guessHandoff,
          GamePhase.guessing,
          GamePhase.reveal,
        }),
        isEmpty,
      );
    });

    test('the scoreboard still sits between couples', () async {
      final game = await readyGame(couples: 3, questionsPerPlayer: 2);
      game.setMode(GameMode.paper);
      game.startGame(random: Random(44));

      var scoreboards = 0;
      var guard = 0;
      while (game.phase != GamePhase.results) {
        expect(guard++, lessThan(500));
        switch (game.phase) {
          case GamePhase.paperPrompt:
            game.revealOnPaper();
          case GamePhase.paperVerdict:
            game.judge(correct: false);
            game.advanceAfterReveal();
          case GamePhase.scoreboard:
            scoreboards++;
            game.continueFromScoreboard();
          default:
            fail('unexpected phase ${game.phase}');
        }
      }
      expect(scoreboards, 2, reason: 'between three couples');
    });

    test('scores exactly like a classic game', () async {
      final game = await readyGame(couples: 2, questionsPerPlayer: 3);
      game.setMode(GameMode.paper);
      game.setPointsPerCorrect(10);
      game.startGame(random: Random(45));

      playPaper(game, (i) => game.currentTurn.coupleIndex == 0);

      expect(game.standings.first.couple.id, game.couples[0].id);
      expect(game.standings.first.points, 6 * 10);
      expect(game.standings.last.points, 0);
    });

    test('archives a record that knows it was played on paper', () async {
      final game = await readyGame(couples: 2, questionsPerPlayer: 2);
      game.setMode(GameMode.paper);
      game.startGame(random: Random(46));
      playPaper(game, (_) => true);

      final record = game.history.single;
      expect(record.mode, GameMode.paper);
      expect(record.isComplete, isTrue);
      // The app never saw the answers, so the recap must not pretend it did.
      expect(record.turns.every((t) => t.answer.isEmpty), isTrue);
      expect(record.turns.every((t) => t.guess.isEmpty), isTrue);
      expect(record.turns.every((t) => t.isJudged), isTrue);
    });

    test('the mode persists across games until changed', () async {
      final game = await readyGame(couples: 2, questionsPerPlayer: 2);
      game.setMode(GameMode.paper);
      game.startGame(random: Random(47));
      playPaper(game, (_) => true);

      game.playAgain();
      expect(game.phase, GamePhase.paperPrompt);

      game.setMode(GameMode.classic);
      game.startGame(random: Random(48));
      expect(game.phase, GamePhase.answerHandoff);
    });
  });
}

class _BrokenRepository extends QuestionRepository {
  @override
  Future<List<Question>> load() async => throw const FormatException('nope');
}
