import 'package:duet/data/question_dealer.dart';
import 'package:duet/data/question_repository.dart';
import 'package:duet/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Question> questions;

  setUpAll(() async {
    questions = await QuestionRepository().load();
  });

  test('the bundled pack parses', () {
    expect(questions, isNotEmpty);
  });

  test('every question has both voices, and a {name} slot for the partner', () {
    for (final question in questions) {
      expect(question.selfPrompt.trim(), isNotEmpty, reason: question.id);
      expect(question.partnerPrompt, contains('{name}'), reason: question.id);
      expect(question.promptAbout('Alex'), contains('Alex'));
      expect(question.promptAbout('Alex'), isNot(contains('{name}')));
    }
  });

  test('ids are unique', () {
    final ids = questions.map((q) => q.id).toSet();
    expect(ids.length, questions.length);
  });

  test('every bundled category is represented', () {
    final used = questions.map((q) => q.category).toSet();
    final bundled = QuestionCategory.values
        .where((category) => category != QuestionCategory.custom);
    expect(used, containsAll(bundled));
  });

  test('the pack never ships a question in the custom category', () {
    // `custom` is reserved for questions players write during a session.
    expect(
      questions.any((q) => q.category == QuestionCategory.custom),
      isFalse,
    );
  });

  test('the pack is big enough for a full table at the longest setting', () {
    // 6 couples x 2 partners x 7 questions, all dealt without repeats.
    expect(questions.length, greaterThanOrEqualTo(6 * 2 * 7));
    expect(
      questions.length,
      greaterThanOrEqualTo(QuestionDealer.minimumPoolSize(7)),
    );
  });
}
