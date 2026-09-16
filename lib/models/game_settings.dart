import 'question.dart';

/// Host-configurable options, chosen on the setup screens before a game.
class GameSettings {
  const GameSettings({
    this.questionsPerPlayer = 5,
    this.pointsPerCorrect = 10,
    this.categories = const {
      QuestionCategory.favourites,
      QuestionCategory.habits,
      QuestionCategory.history,
      QuestionCategory.wouldYouRather,
      QuestionCategory.custom,
    },
  });

  /// How many questions each player answers about themselves.
  final int questionsPerPlayer;

  /// Awarded to the couple for every guess the host marks correct.
  final int pointsPerCorrect;

  final Set<QuestionCategory> categories;

  static const questionCountOptions = [3, 5, 7];
  static const maxCouples = 6;
  static const minCouples = 1;

  GameSettings copyWith({
    int? questionsPerPlayer,
    int? pointsPerCorrect,
    Set<QuestionCategory>? categories,
  }) =>
      GameSettings(
        questionsPerPlayer: questionsPerPlayer ?? this.questionsPerPlayer,
        pointsPerCorrect: pointsPerCorrect ?? this.pointsPerCorrect,
        categories: categories ?? this.categories,
      );
}
