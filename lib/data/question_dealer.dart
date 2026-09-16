import 'dart:math';

import '../models/couple.dart';
import '../models/question.dart';

/// Hands every player their own private set of questions.
///
/// Two rules matter:
///   1. A player never gets the same question twice.
///   2. **Partners never share a question.** If both halves of a couple were
///      asked the same thing, the second reveal would give the answer away.
///
/// Questions are otherwise dealt without replacement across the whole table.
/// Only if the pool runs dry do different couples start sharing questions —
/// harmless, since they never hear each other's answers in advance.
abstract final class QuestionDealer {
  /// The smallest pool that can serve a game — a single couple still needs two
  /// non-overlapping sets.
  static int minimumPoolSize(int questionsPerPlayer) => questionsPerPlayer * 2;

  static Map<String, List<Question>> deal({
    required List<Couple> couples,
    required List<Question> pool,
    required int questionsPerPlayer,
    Random? random,
  }) {
    if (questionsPerPlayer < 1) {
      throw ArgumentError.value(
        questionsPerPlayer,
        'questionsPerPlayer',
        'must be at least 1',
      );
    }
    final needed = minimumPoolSize(questionsPerPlayer);
    if (pool.length < needed) {
      throw ArgumentError(
        'Need at least $needed questions to deal $questionsPerPlayer each, '
        'but the pool holds ${pool.length}.',
      );
    }

    final shuffled = [...pool]..shuffle(random ?? Random());
    final dealtGlobally = <String>{};
    final byPlayer = <String, List<Question>>{};

    for (final couple in couples) {
      final dealtInCouple = <String>{};

      for (final player in couple.players) {
        final picked = <Question>[];

        // Preferred: questions nobody at the table has been asked yet.
        for (final question in shuffled) {
          if (picked.length == questionsPerPlayer) break;
          if (dealtGlobally.contains(question.id)) continue;
          if (dealtInCouple.contains(question.id)) continue;
          picked.add(question);
        }

        // Fallback once the pool is exhausted: reuse across couples, but never
        // inside this one.
        if (picked.length < questionsPerPlayer) {
          for (final question in shuffled) {
            if (picked.length == questionsPerPlayer) break;
            if (dealtInCouple.contains(question.id)) continue;
            if (picked.contains(question)) continue;
            picked.add(question);
          }
        }

        dealtGlobally.addAll(picked.map((q) => q.id));
        dealtInCouple.addAll(picked.map((q) => q.id));
        byPlayer[player.id] = picked;
      }
    }

    return byPlayer;
  }
}
