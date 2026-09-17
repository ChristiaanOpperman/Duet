import 'package:flutter/material.dart';

/// How a game is played. Both modes ask the same questions in the same order
/// and score identically — they differ only in where the answers are written.
enum GameMode {
  /// Answers are typed into the app in a private setup round, then each
  /// partner types their guess and the app reveals the two side by side.
  classic(
    'Classic',
    'Answer on the phone in secret, then guess what your partner said.',
    Icons.smartphone_rounded,
  ),

  /// Nothing is typed. The app reads the question out, the pair write on
  /// paper, they reveal to each other, and the host taps the verdict.
  paper(
    'Pen & paper',
    'No typing. Write your answers down, reveal together, host scores it.',
    Icons.draw_rounded,
  );

  const GameMode(this.label, this.blurb, this.icon);

  final String label;
  final String blurb;
  final IconData icon;

  bool get isPaper => this == GameMode.paper;
}
