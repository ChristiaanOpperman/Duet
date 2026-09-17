import 'couple.dart';
import 'game_mode.dart';
import 'standing.dart';
import 'turn.dart';

/// A finished (or abandoned) game, kept so it can be reviewed later.
///
/// Records live in memory for the lifetime of the app session only — closing
/// the app discards them. Nothing is written to disk and nothing leaves the
/// device.
///
/// The turn list is captured by reference, which is safe because
/// `GameController.startGame` always builds a brand new list rather than
/// reusing the old one: an archived record can never be mutated by the game
/// that follows it.
class GameRecord {
  GameRecord({
    required this.number,
    required this.playedAt,
    required this.couples,
    required this.turns,
    required this.pointsPerCorrect,
    required this.questionsPerPlayer,
    required this.mode,
  });

  /// 1 for the first game of the session, 2 for the next, and so on.
  final int number;
  final DateTime playedAt;
  final List<Couple> couples;
  final List<Turn> turns;
  final int pointsPerCorrect;
  final int questionsPerPlayer;

  /// Paper games never captured the answers — only the verdicts — so the
  /// recap has to render them differently.
  final GameMode mode;

  /// False when the game was abandoned partway — the recap says so rather
  /// than presenting a half-played game as a final result.
  bool get isComplete => turns.every((turn) => turn.isJudged);

  List<Turn> get playedTurns =>
      turns.where((turn) => turn.isJudged).toList(growable: false);

  int get correctCount =>
      turns.where((turn) => turn.correct == true).length;

  List<Standing> get standings => computeStandings(
        couples: couples,
        turns: turns,
        pointsPerCorrect: pointsPerCorrect,
      );

  Standing? get winner {
    final rows = standings;
    return rows.isEmpty ? null : rows.first;
  }

  bool get isDraw {
    final rows = standings;
    return rows.length > 1 && rows[0].points == rows[1].points;
  }

  /// The turns belonging to one couple, in the order they were played.
  List<Turn> turnsFor(String coupleId) =>
      turns.where((turn) => turn.coupleId == coupleId).toList(growable: false);
}
