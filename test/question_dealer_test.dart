import 'dart:math';

import 'package:duet/data/question_dealer.dart';
import 'package:duet/models/couple.dart';
import 'package:duet/models/player.dart';
import 'package:duet/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

List<Question> poolOf(int count) => [
      for (var i = 0; i < count; i++)
        Question(
          id: 'q$i',
          category: QuestionCategory.favourites,
          selfPrompt: 'Self $i?',
          partnerPrompt: "{name}'s $i?",
        ),
    ];

List<Couple> couplesOf(int count) => [
      for (var i = 0; i < count; i++)
        Couple(
          id: 'c$i',
          partnerA: Player(id: 'c$i-a', name: 'A$i'),
          partnerB: Player(id: 'c$i-b', name: 'B$i'),
        ),
    ];

void main() {
  test('every player gets exactly the requested number of questions', () {
    final dealt = QuestionDealer.deal(
      couples: couplesOf(3),
      pool: poolOf(90),
      questionsPerPlayer: 5,
      random: Random(1),
    );

    expect(dealt.length, 6);
    for (final questions in dealt.values) {
      expect(questions.length, 5);
      expect(questions.map((q) => q.id).toSet().length, 5,
          reason: 'no repeats within a player');
    }
  });

  test('partners never share a question', () {
    for (var seed = 0; seed < 25; seed++) {
      final couples = couplesOf(6);
      final dealt = QuestionDealer.deal(
        couples: couples,
        pool: poolOf(90),
        questionsPerPlayer: 7,
        random: Random(seed),
      );

      for (final couple in couples) {
        final a = dealt[couple.partnerA.id]!.map((q) => q.id).toSet();
        final b = dealt[couple.partnerB.id]!.map((q) => q.id).toSet();
        expect(a.intersection(b), isEmpty, reason: 'seed $seed');
      }
    }
  });

  test('deals without replacement while the pool allows it', () {
    final dealt = QuestionDealer.deal(
      couples: couplesOf(6),
      pool: poolOf(84),
      questionsPerPlayer: 7,
      random: Random(3),
    );

    final all = dealt.values.expand((q) => q).map((q) => q.id).toList();
    expect(all.length, 84);
    expect(all.toSet().length, 84, reason: 'exactly exhausts the pool');
  });

  test('a small pool is reused across couples but never inside one', () {
    final couples = couplesOf(4);
    // Only enough for one couple — the other three must reuse.
    final dealt = QuestionDealer.deal(
      couples: couples,
      pool: poolOf(6),
      questionsPerPlayer: 3,
      random: Random(7),
    );

    for (final couple in couples) {
      final a = dealt[couple.partnerA.id]!.map((q) => q.id).toSet();
      final b = dealt[couple.partnerB.id]!.map((q) => q.id).toSet();
      expect(a.length, 3);
      expect(b.length, 3);
      expect(a.intersection(b), isEmpty);
    }
  });

  test('rejects a pool too small to give a couple two distinct sets', () {
    expect(
      () => QuestionDealer.deal(
        couples: couplesOf(1),
        pool: poolOf(5),
        questionsPerPlayer: 3,
      ),
      throwsArgumentError,
    );
  });
}
