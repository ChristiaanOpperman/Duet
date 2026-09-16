import 'package:flutter/material.dart';

/// The four themes the bundled question pack is grouped into. Hosts can switch
/// categories off before a game, so ids must stay stable.
enum QuestionCategory {
  favourites('favourites', 'Favourites', Icons.favorite_rounded),
  habits('habits', 'Habits & Quirks', Icons.psychology_alt_rounded),
  history('history', 'Our History', Icons.auto_stories_rounded),
  wouldYouRather('would_you_rather', 'Would You Rather', Icons.shuffle_rounded),

  /// Questions written by the players during this session. Never present in
  /// the bundled pack — the chip only appears once something has been added.
  custom('custom', 'Your Own', Icons.edit_note_rounded);

  const QuestionCategory(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;

  static QuestionCategory? byId(String id) {
    for (final category in QuestionCategory.values) {
      if (category.id == id) return category;
    }
    return null;
  }
}

/// A question in two voices: [selfPrompt] is what the answerer sees in private
/// ("What is your favourite nut?"), [partnerPrompt] is what the presenter asks
/// their partner ("What is {name}'s favourite nut?").
class Question {
  const Question({
    required this.id,
    required this.category,
    required this.selfPrompt,
    required this.partnerPrompt,
  });

  final String id;
  final QuestionCategory category;
  final String selfPrompt;
  final String partnerPrompt;

  /// Fills the `{name}` slot in [partnerPrompt] with the answerer's name.
  String promptAbout(String name) => partnerPrompt.replaceAll('{name}', name);

  factory Question.fromJson(Map<String, dynamic> json) {
    final categoryId = json['category'] as String?;
    final category = QuestionCategory.byId(categoryId ?? '');
    if (category == null) {
      throw FormatException('Unknown question category "$categoryId"', json);
    }
    final partnerPrompt = json['partnerPrompt'] as String;
    if (!partnerPrompt.contains('{name}')) {
      throw FormatException(
        'partnerPrompt for "${json['id']}" is missing the {name} slot',
        json,
      );
    }
    return Question(
      id: json['id'] as String,
      category: category,
      selfPrompt: json['selfPrompt'] as String,
      partnerPrompt: partnerPrompt,
    );
  }

  @override
  bool operator ==(Object other) => other is Question && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Question($id)';
}
