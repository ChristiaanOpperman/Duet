/// Turns a question written in the first person into the one the presenter
/// reads out to the partner.
///
/// "What is your favourite nut?" → "What is {name}'s favourite nut?"
///
/// Only the *first* pronoun becomes the name; later ones become "they" and
/// "their", because naming someone twice in one sentence reads like a form
/// letter — "What does Alex do when Alex cannot sleep?".
///
/// This is a convenience, not a guarantee. English is not mechanically
/// transformable and unusual phrasings will come out wrong, so the result is
/// always offered to the author in an editable field with a live preview
/// rather than used directly.
library;

/// The token the presenter swaps for the answering player's name.
const nameToken = '{name}';

/// `(pattern, first occurrence, later occurrences)`.
///
/// Ordered longest-match-first: "do you" has to win before the bare "you"
/// rule sees it, or "Do you snore?" becomes "Do {name} snore?".
const _rules = <(String, String, String)>[
  (r'\bare\s+you\b', 'is {name}', 'are they'),
  (r'\bwere\s+you\b', 'was {name}', 'were they'),
  (r'\bdo\s+you\b', 'does {name}', 'do they'),
  (r'\bdid\s+you\b', 'did {name}', 'did they'),
  (r'\bhave\s+you\b', 'has {name}', 'have they'),
  (r'\bhad\s+you\b', 'had {name}', 'had they'),
  (r'\bwill\s+you\b', 'will {name}', 'will they'),
  (r'\bwould\s+you\b', 'would {name}', 'would they'),
  (r'\bcould\s+you\b', 'could {name}', 'could they'),
  (r'\bcan\s+you\b', 'can {name}', 'can they'),
  (r'\bshould\s+you\b', 'should {name}', 'should they'),
  (r"\byou'?re\b", '{name} is', 'they are'),
  (r'\byou\s+are\b', '{name} is', 'they are'),
  (r'\byou\s+were\b', '{name} was', 'they were'),
  (r"\byou'?ve\b", '{name} has', 'they have'),
  (r'\byou\s+have\b', '{name} has', 'they have'),
  (r'\byourself\b', 'themselves', 'themselves'),
  (r'\byours\b', "{name}'s", 'theirs'),
  (r'\byour\b', "{name}'s", 'their'),
  (r'\byou\b', '{name}', 'they'),
];

/// One alternation over every rule, each wrapped in a capturing group so the
/// matching rule can be identified. A single left-to-right scan is what makes
/// "first occurrence versus later" possible at all — `replaceAll` per rule
/// cannot know what another rule already replaced.
final _combined = RegExp(
  _rules.map((rule) => '(${rule.$1})').join('|'),
  caseSensitive: false,
);

String derivePartnerPrompt(String selfPrompt) {
  final source = selfPrompt.trim();
  if (source.isEmpty) return '';

  final startedCapitalised =
      RegExp(r'^[A-Za-z]').hasMatch(source) && source[0] == source[0].toUpperCase();

  final buffer = StringBuffer();
  var cursor = 0;
  var named = false;

  for (final match in _combined.allMatches(source)) {
    final index = _matchedRule(match);
    if (index == null) continue;

    buffer.write(source.substring(cursor, match.start));
    final rule = _rules[index];
    final replacement = named ? rule.$3 : rule.$2;
    buffer.write(replacement);
    if (replacement.contains(nameToken)) named = true;
    cursor = match.end;
  }
  buffer.write(source.substring(cursor));

  var result = buffer.toString();
  // A rule that fires on the first word leaves it lower case ("Do you…" →
  // "does {name}…"), so put the capital back.
  if (startedCapitalised && RegExp(r'^[a-z]').hasMatch(result)) {
    result = result[0].toUpperCase() + result.substring(1);
  }
  return result;
}

int? _matchedRule(RegExpMatch match) {
  for (var i = 0; i < _rules.length; i++) {
    if (match.group(i + 1) != null) return i;
  }
  return null;
}

/// Whether a partner prompt can actually be asked — without the token the
/// presenter has no way to say whose answer it wants.
bool hasNameToken(String partnerPrompt) => partnerPrompt.contains(nameToken);
