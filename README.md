# Duet

A couples trivia party game for one shared device.

Up to six couples play. Each person privately answers a handful of questions
about themselves. Then the phone becomes a presenter and asks their partner the
same questions in the second person — *"What is Alex's favourite nut?"* — they
type a guess, the real answer is revealed, and the host calls it. Points go to
the couple, not the player.

Built in Flutter with no dependencies beyond the SDK: offline, no accounts, no
backend.

Every game you finish stays available for the rest of the app session — tap it
on the home screen to review each question, what everyone answered, and what
their partner guessed. It is held in memory only: closing the app clears it,
and nothing is ever written to disk or sent anywhere.

## Running it

```bash
flutter pub get
flutter run -d chrome     # or: -d macos
```

iOS and Android builds need Xcode 16+ and the Android SDK cmdline-tools
respectively. The app uses no plugins, so nothing else is required once those
are installed.

## Editing the questions

`assets/questions/questions.json`. Each entry needs both voices:

```json
{
  "id": "fav-nut",
  "category": "favourites",
  "selfPrompt": "What is your favourite nut?",
  "partnerPrompt": "What is {name}'s favourite nut?"
}
```

`{name}` is replaced with the answering player's name when the presenter asks
their partner. Categories are `favourites`, `habits`, `history` and
`would_you_rather`.

## Development

```bash
flutter analyze
flutter test
flutter test --update-goldens   # after an intentional visual change
```

See `CLAUDE.md` for the architecture.
