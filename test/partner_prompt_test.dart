import 'package:duet/data/partner_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void expectDerived(String self, String expected) {
    expect(derivePartnerPrompt(self), expected, reason: self);
  }

  test('possessives become the name', () {
    expectDerived(
      'What is your favourite nut?',
      "What is {name}'s favourite nut?",
    );
    expectDerived("What's your go-to takeaway?", "What's {name}'s go-to takeaway?");
  });

  test('questions starting with an auxiliary keep their grammar', () {
    expectDerived('Do you snore?', 'Does {name} snore?');
    expectDerived('Are you a morning person?', 'Is {name} a morning person?');
    expectDerived('Have you ever been skiing?', 'Has {name} ever been skiing?');
    expectDerived('Did you enjoy it?', 'Did {name} enjoy it?');
    expectDerived(
      'Would you rather fly or be invisible?',
      'Would {name} rather fly or be invisible?',
    );
  });

  test('the bare pronoun is only used when no phrase rule matched', () {
    expectDerived('Who do you admire most?', 'Who does {name} admire most?');
    expectDerived('What makes you laugh?', 'What makes {name} laugh?');
  });

  test('reflexives read naturally', () {
    expectDerived(
      'What do you like about yourself?',
      'What does {name} like about themselves?',
    );
  });

  test('contractions are handled', () {
    expectDerived(
      "What do you do when you're bored?",
      'What does {name} do when they are bored?',
    );
    expectDerived('What have you done today?', 'What has {name} done today?');
  });

  test('only the first pronoun becomes the name', () {
    // "What does Alex do when Alex cannot sleep?" reads like a form letter.
    expectDerived(
      'What do you do when you cannot sleep?',
      'What does {name} do when they cannot sleep?',
    );
    expectDerived(
      'Are you happier now than you were?',
      'Is {name} happier now than they were?',
    );
    expectDerived(
      'What is your favourite thing about your home?',
      "What is {name}'s favourite thing about their home?",
    );
    expectDerived(
      'Would you rather lose your keys or your phone?',
      "Would {name} rather lose their keys or their phone?",
    );
  });

  test('the name is used exactly once', () {
    for (final prompt in [
      'What do you do when you cannot sleep?',
      'Do you think your partner knows you?',
      'What is your favourite thing about your home?',
    ]) {
      final derived = derivePartnerPrompt(prompt);
      expect(nameToken.allMatches(derived).length, 1, reason: prompt);
    }
  });

  test('a prompt with no pronoun is left alone', () {
    expectDerived('Favourite nut?', 'Favourite nut?');
    expect(hasNameToken(derivePartnerPrompt('Favourite nut?')), isFalse);
  });

  test('empty input gives empty output', () {
    expectDerived('   ', '');
  });

  test('derived prompts are askable', () {
    for (final prompt in [
      'What is your favourite nut?',
      'Do you snore?',
      'Would you rather fly or be invisible?',
    ]) {
      expect(hasNameToken(derivePartnerPrompt(prompt)), isTrue, reason: prompt);
    }
  });
}
