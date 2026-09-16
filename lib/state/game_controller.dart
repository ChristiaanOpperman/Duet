import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/question_dealer.dart';
import '../data/question_repository.dart';
import '../models/couple.dart';
import '../models/game_record.dart';
import '../models/game_settings.dart';
import '../models/player.dart';
import '../models/question.dart';
import '../models/standing.dart';
import '../models/turn.dart';
import 'game_phase.dart';

export '../models/standing.dart' show Standing;

/// The whole game: setup, secret answers, guessing rounds, scoring.
///
/// State is held in memory for one sitting — there is no persistence, so a
/// restart begins a fresh game. The source of truth is [_turns]; scores and
/// progress are derived from it rather than tracked separately.
class GameController extends ChangeNotifier {
  GameController({QuestionRepository? repository, DateTime Function()? now})
      : _repository = repository ?? QuestionRepository(),
        _now = now ?? DateTime.now;

  final QuestionRepository _repository;

  /// Injectable so tests get a fixed timestamp — a real clock in an archived
  /// record makes the recap screen impossible to golden.
  final DateTime Function() _now;

  GamePhase _phase = GamePhase.home;
  GameSettings _settings = const GameSettings();
  List<Couple> _couples = _blankCouples(3);
  List<Question> _pool = const [];
  bool _loading = true;
  Object? _loadError;

  List<Turn> _turns = [];
  final List<GameRecord> _history = [];
  bool _currentGameArchived = false;
  GameRecord? _openRecord;
  GamePhase _recapReturnPhase = GamePhase.home;
  Map<String, List<Turn>> _turnsByAnswerer = {};
  List<Player> _answerOrder = [];
  int _answererIndex = 0;
  int _answerQuestionIndex = 0;
  int _turnIndex = 0;

  // ---------------------------------------------------------------- loading

  Future<void> init() async {
    try {
      _pool = await _repository.load();
      _loadError = null;
    } catch (error) {
      _loadError = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  bool get isLoading => _loading;
  Object? get loadError => _loadError;

  // ------------------------------------------------------------------ state

  GamePhase get phase => _phase;
  GameSettings get settings => _settings;
  List<Couple> get couples => List.unmodifiable(_couples);
  List<Turn> get turns => List.unmodifiable(_turns);

  /// Games played this session, newest first. In memory only — closing the app
  /// discards them.
  List<GameRecord> get history => List.unmodifiable(_history.reversed);

  bool get hasHistory => _history.isNotEmpty;

  /// The record the recap screen is currently showing.
  GameRecord? get openRecord => _openRecord;

  /// Questions available under the currently selected categories.
  List<Question> get eligibleQuestions => [
        for (final question in _pool)
          if (_settings.categories.contains(question.category)) question,
      ];

  /// A game needs two non-overlapping sets for every couple.
  bool get hasEnoughQuestions =>
      eligibleQuestions.length >=
      QuestionDealer.minimumPoolSize(_settings.questionsPerPlayer);

  bool get couplesAreNamed => _couples.every(
        (couple) => couple.players.every((p) => p.name.trim().isNotEmpty),
      );

  /// Names have to be distinct or the handoff screens become ambiguous.
  bool get namesAreUnique {
    final names = [
      for (final couple in _couples)
        for (final player in couple.players) player.name.trim().toLowerCase(),
    ].where((name) => name.isNotEmpty);
    return names.length == names.toSet().length;
  }

  bool get canStartGame =>
      couplesAreNamed && namesAreUnique && hasEnoughQuestions;

  // ------------------------------------------------------------ setup edits

  void setCoupleCount(int count) {
    final clamped = count.clamp(GameSettings.minCouples, GameSettings.maxCouples);
    if (clamped == _couples.length) return;
    if (clamped < _couples.length) {
      _couples = _couples.sublist(0, clamped);
    } else {
      _couples = [
        ..._couples,
        for (var i = _couples.length; i < clamped; i++) _blankCouple(i),
      ];
    }
    notifyListeners();
  }

  void setPlayerName({
    required int coupleIndex,
    required bool isPartnerA,
    required String name,
  }) {
    final couple = _couples[coupleIndex];
    _couples[coupleIndex] = isPartnerA
        ? couple.copyWith(partnerA: couple.partnerA.copyWith(name: name))
        : couple.copyWith(partnerB: couple.partnerB.copyWith(name: name));
    notifyListeners();
  }

  void setQuestionsPerPlayer(int value) {
    if (value == _settings.questionsPerPlayer) return;
    _settings = _settings.copyWith(questionsPerPlayer: value);
    notifyListeners();
  }

  void setPointsPerCorrect(int value) {
    if (value == _settings.pointsPerCorrect) return;
    _settings = _settings.copyWith(pointsPerCorrect: value);
    notifyListeners();
  }

  void toggleCategory(QuestionCategory category) {
    final next = {..._settings.categories};
    if (!next.remove(category)) next.add(category);
    // Never let the host switch every category off.
    if (next.isEmpty) return;
    _settings = _settings.copyWith(categories: next);
    notifyListeners();
  }

  // ------------------------------------------------------------- navigation

  void goHome() => _setPhase(GamePhase.home);
  void showHowToPlay() => _setPhase(GamePhase.howToPlay);
  void goToCouplesSetup() => _setPhase(GamePhase.setupCouples);
  void goToOptionsSetup() => _setPhase(GamePhase.setupOptions);

  /// Opens a recap, remembering where to go back to.
  void showRecap(GameRecord record) {
    _openRecord = record;
    _recapReturnPhase = _phase;
    _phase = GamePhase.recap;
    notifyListeners();
  }

  void closeRecap() {
    _openRecord = null;
    _phase = _recapReturnPhase;
    notifyListeners();
  }

  void _setPhase(GamePhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    notifyListeners();
  }

  // ------------------------------------------------------------------- play

  /// Deals questions and builds the full running order. [random] is injectable
  /// so tests get a deterministic deal.
  void startGame({Random? random}) {
    final dealt = QuestionDealer.deal(
      couples: _couples,
      pool: eligibleQuestions,
      questionsPerPlayer: _settings.questionsPerPlayer,
      random: random,
    );

    _turns = [];
    // Couple by couple: all of A's questions (guessed by B), then all of B's.
    for (var index = 0; index < _couples.length; index++) {
      final couple = _couples[index];
      for (final answerer in couple.players) {
        for (final question in dealt[answerer.id]!) {
          _turns.add(
            Turn(
              question: question,
              answerer: answerer,
              guesser: couple.partnerOf(answerer),
              coupleId: couple.id,
              coupleIndex: index,
            ),
          );
        }
      }
    }

    _turnsByAnswerer = {};
    for (final turn in _turns) {
      _turnsByAnswerer.putIfAbsent(turn.answerer.id, () => []).add(turn);
    }

    _answerOrder = [for (final couple in _couples) ...couple.players];
    _answererIndex = 0;
    _answerQuestionIndex = 0;
    _turnIndex = 0;
    _currentGameArchived = false;
    _phase = GamePhase.answerHandoff;
    notifyListeners();
  }

  // -------------------------------------------------------- answering phase

  Player get currentAnswerer => _answerOrder[_answererIndex];

  int get answererNumber => _answererIndex + 1;
  int get answererCount => _answerOrder.length;

  List<Turn> get _currentAnswererTurns =>
      _turnsByAnswerer[currentAnswerer.id] ?? const [];

  Turn get currentAnswerTurn => _currentAnswererTurns[_answerQuestionIndex];

  int get answerQuestionIndex => _answerQuestionIndex;
  int get answerQuestionCount => _currentAnswererTurns.length;

  /// Leaves the handoff gate and starts the current player's private set.
  void beginAnswering() => _setPhase(GamePhase.answering);

  /// Records one secret answer and moves to the next question, the next
  /// player's handoff, or the first guessing round.
  void submitAnswer(String answer) {
    currentAnswerTurn.answer = answer.trim();

    if (_answerQuestionIndex + 1 < answerQuestionCount) {
      _answerQuestionIndex++;
      notifyListeners();
      return;
    }

    _answerQuestionIndex = 0;
    if (_answererIndex + 1 < _answerOrder.length) {
      _answererIndex++;
      _phase = GamePhase.answerHandoff;
    } else {
      _turnIndex = 0;
      _phase = GamePhase.guessHandoff;
    }
    notifyListeners();
  }

  // --------------------------------------------------------- guessing phase

  Turn get currentTurn => _turns[_turnIndex];

  Couple get currentCouple =>
      _couples.firstWhere((couple) => couple.id == currentTurn.coupleId);

  /// The run of consecutive turns the current guesser is working through.
  int get _blockStart {
    var start = _turnIndex;
    while (start > 0 &&
        _turns[start - 1].guesser.id == currentTurn.guesser.id &&
        _turns[start - 1].coupleId == currentTurn.coupleId) {
      start--;
    }
    return start;
  }

  int get guessIndexInBlock => _turnIndex - _blockStart;

  int get guessBlockLength {
    var end = _blockStart;
    while (end < _turns.length &&
        _turns[end].guesser.id == currentTurn.guesser.id &&
        _turns[end].coupleId == currentTurn.coupleId) {
      end++;
    }
    return end - _blockStart;
  }

  int get currentCoupleNumber => currentTurn.coupleIndex + 1;
  int get coupleCount => _couples.length;

  void beginGuessing() => _setPhase(GamePhase.guessing);

  void submitGuess(String guess) {
    currentTurn.guess = guess.trim();
    currentTurn.correct = null;
    _phase = GamePhase.reveal;
    notifyListeners();
  }

  /// The host's call on whether the guess counted. Deliberately manual —
  /// "macademia" for "macadamia" should score, and no string match gets that
  /// consistently right.
  void judge({required bool correct}) {
    currentTurn.correct = correct;
    notifyListeners();
  }

  /// Leaves the reveal for whatever comes next: another guess, a handoff to
  /// the other partner, the scoreboard between couples, or the results.
  void advanceAfterReveal() {
    final previous = currentTurn;
    final next = _turnIndex + 1;

    if (next >= _turns.length) {
      _archiveCurrentGame();
      _phase = GamePhase.results;
      notifyListeners();
      return;
    }

    _turnIndex = next;
    final upcoming = _turns[next];
    if (upcoming.coupleId != previous.coupleId) {
      _phase = GamePhase.scoreboard;
    } else if (upcoming.guesser.id != previous.guesser.id) {
      _phase = GamePhase.guessHandoff;
    } else {
      _phase = GamePhase.guessing;
    }
    notifyListeners();
  }

  /// The scoreboard always sits between couples, so the next thing is a gate.
  void continueFromScoreboard() => _setPhase(GamePhase.guessHandoff);

  // --------------------------------------------------------------- progress

  /// 0..1 across the whole guessing half of the game.
  double get gameProgress =>
      _turns.isEmpty ? 0 : (_turnIndex + 1) / _turns.length;

  // ----------------------------------------------------------------- scores

  int pointsFor(String coupleId) =>
      correctFor(coupleId) * _settings.pointsPerCorrect;

  int correctFor(String coupleId) => _turns
      .where((turn) => turn.coupleId == coupleId && turn.correct == true)
      .length;

  List<Standing> get standings => computeStandings(
        couples: _couples,
        turns: _turns,
        pointsPerCorrect: _settings.pointsPerCorrect,
      );

  Standing? get winner {
    final rows = standings;
    return rows.isEmpty ? null : rows.first;
  }

  /// True when the top two are level — the results screen says so rather than
  /// crowning an arbitrary couple.
  bool get isDraw {
    final rows = standings;
    return rows.length > 1 && rows[0].points == rows[1].points;
  }

  // ---------------------------------------------------------------- restart

  /// Same couples and settings, freshly dealt questions. The finished game is
  /// archived first so "play again" never destroys what just happened.
  void playAgain() {
    _archiveCurrentGame();
    startGame();
  }

  /// Back to the couples screen, keeping the names already entered.
  void newGame() {
    _archiveCurrentGame();
    _clearRound();
    _phase = GamePhase.setupCouples;
    notifyListeners();
  }

  void quitToHome() {
    _archiveCurrentGame();
    _clearRound();
    _phase = GamePhase.home;
    notifyListeners();
  }

  /// Snapshots the current game into the session history. Idempotent, so
  /// reaching the results screen and then tapping "play again" archives once.
  /// A game nobody has judged a single answer in isn't worth keeping.
  void _archiveCurrentGame() {
    if (_currentGameArchived) return;
    if (!_turns.any((turn) => turn.isJudged)) return;

    _history.add(
      GameRecord(
        number: _history.length + 1,
        playedAt: _now(),
        couples: List.unmodifiable(_couples),
        turns: List.unmodifiable(_turns),
        pointsPerCorrect: _settings.pointsPerCorrect,
        questionsPerPlayer: _settings.questionsPerPlayer,
      ),
    );
    _currentGameArchived = true;
  }

  void _clearRound() {
    _turns = [];
    _turnsByAnswerer = {};
    _answerOrder = [];
    _answererIndex = 0;
    _answerQuestionIndex = 0;
    _turnIndex = 0;
  }

  // ---------------------------------------------------------------- helpers

  static List<Couple> _blankCouples(int count) =>
      [for (var i = 0; i < count; i++) _blankCouple(i)];

  static Couple _blankCouple(int index) => Couple(
        id: 'couple-$index',
        partnerA: Player(id: 'couple-$index-a', name: ''),
        partnerB: Player(id: 'couple-$index-b', name: ''),
      );
}
