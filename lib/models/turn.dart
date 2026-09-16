import 'player.dart';
import 'question.dart';

/// One unit of play: a question [answerer] answered about themselves, which
/// [guesser] (their partner) later has to guess.
///
/// Deliberately mutable — a turn is filled in across two phases of a single
/// game session, and the whole game is just an ordered list of these. Scores,
/// progress and the scoreboard are all derived from this list, so there is no
/// second source of truth to keep in sync.
class Turn {
  Turn({
    required this.question,
    required this.answerer,
    required this.guesser,
    required this.coupleId,
    required this.coupleIndex,
  });

  final Question question;
  final Player answerer;
  final Player guesser;
  final String coupleId;

  /// Position of the couple in the setup order — drives their colour.
  final int coupleIndex;

  /// What the answerer secretly entered about themselves.
  String answer = '';

  /// What their partner guessed.
  String guess = '';

  /// Null until the host judges the reveal.
  bool? correct;

  bool get isAnswered => answer.trim().isNotEmpty;
  bool get isGuessed => guess.trim().isNotEmpty;
  bool get isJudged => correct != null;

  /// What the presenter reads out, in the second person.
  String get presenterPrompt => question.promptAbout(answerer.name);

  @override
  String toString() =>
      'Turn(${question.id}, ${answerer.name} -> ${guesser.name})';
}
