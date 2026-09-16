import 'dart:math';

import 'package:duet/data/question_repository.dart';
import 'package:duet/models/question.dart';
import 'package:duet/state/game_controller.dart';
import 'package:duet/state/game_phase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the bundled pack so controller tests don't depend on its
/// exact contents.
class _FakeRepository extends QuestionRepository {
  _FakeRepository(this.count);

  final int count;

  @override
  Future<List<Question>> load() async => [
        for (var i = 0; i < count; i++)
          Question(
            id: 'q$i',
            category: QuestionCategory.values[i % QuestionCategory.values.length],
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
}

class _BrokenRepository extends QuestionRepository {
  @override
  Future<List<Question>> load() async => throw const FormatException('nope');
}
