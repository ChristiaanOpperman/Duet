import 'couple.dart';
import 'turn.dart';

/// A couple's line on the scoreboard.
class Standing {
  const Standing({
    required this.couple,
    required this.index,
    required this.points,
    required this.correct,
    required this.judged,
    required this.total,
  });

  final Couple couple;

  /// Setup position, which fixes the couple's colour.
  final int index;
  final int points;
  final int correct;

  /// How many of this couple's turns have been judged so far.
  final int judged;
  final int total;
}

/// Scores are always derived from the turn list — never tracked alongside it.
/// Shared by the live game and by archived [GameRecord]s so a recap can never
/// disagree with the scoreboard it was captured from.
List<Standing> computeStandings({
  required List<Couple> couples,
  required List<Turn> turns,
  required int pointsPerCorrect,
}) {
  final rows = [
    for (var index = 0; index < couples.length; index++)
      () {
        final couple = couples[index];
        final own = turns.where((turn) => turn.coupleId == couple.id);
        final correct = own.where((turn) => turn.correct == true).length;
        return Standing(
          couple: couple,
          index: index,
          points: correct * pointsPerCorrect,
          correct: correct,
          judged: own.where((turn) => turn.isJudged).length,
          total: own.length,
        );
      }(),
  ];
  rows.sort((a, b) {
    final byPoints = b.points.compareTo(a.points);
    return byPoints != 0 ? byPoints : a.index.compareTo(b.index);
  });
  return rows;
}
