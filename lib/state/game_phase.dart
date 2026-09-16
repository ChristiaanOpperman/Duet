/// Every screen the game can be on. [GameController] owns the transitions and
/// `DuetApp` maps each value to a screen, so adding a screen means adding a
/// phase here rather than threading a Navigator through the game.
enum GamePhase {
  home,
  howToPlay,

  /// Name the couples.
  setupCouples,

  /// Questions per player, points, categories.
  setupOptions,

  /// Writing your own questions for this session.
  customQuestions,

  /// "Pass the phone to Alex" — privacy gate before secret answers.
  answerHandoff,

  /// Alex privately answers their own questions.
  answering,

  /// "Sam, guess Alex's answers" — gate before a guessing block.
  guessHandoff,

  /// Sam types a guess for one of Alex's questions.
  guessing,

  /// The real answer is revealed and the host judges it.
  reveal,

  /// Standings between couples' rounds.
  scoreboard,

  /// Final podium.
  results,

  /// Reviewing a finished game from this session's history: every question,
  /// what was answered, what was guessed.
  recap,
}
