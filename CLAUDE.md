# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

**Duet** is a couples trivia party game for one shared device. Up to six couples
play. Each player privately answers questions about themselves, then the device
becomes a presenter and asks their partner to guess those answers. The host
judges each guess and points go to the couple.

Single Flutter app, no backend, no network, no persistence — a game lives in
memory for one sitting.

## Commands

```bash
flutter pub get
flutter run -d chrome          # primary dev target (see Platforms)
flutter run -d macos
flutter analyze                # must stay at zero issues
flutter test                   # unit + golden tests
flutter test --update-goldens  # after a deliberate visual change
```

## Platforms

`chrome` and `macos` are the only targets that run on this machine today: iOS
needs Xcode 16+ (15.2 installed) and Android needs the SDK cmdline-tools.

**The app has zero pub dependencies beyond `flutter_lints`, and that is
deliberate.** No plugins means no CocoaPods step and no platform channels, so
iOS and Android will build as soon as the toolchains are in place. Confetti,
gradients and every animation are hand-rolled for this reason — think hard
before adding a dependency.

## Architecture

### One state machine, no Navigator

`GameController` (`lib/state/game_controller.dart`) is a `ChangeNotifier` that
owns the entire game. `GamePhase` (`lib/state/game_phase.dart`) enumerates every
screen, and `_PhaseRouter` in `lib/app.dart` maps phase → screen inside an
`AnimatedSwitcher`. There is no `Navigator` and no routes: **adding a screen
means adding a phase**, a case in `_screenFor`, and a transition method on the
controller.

Screens read the controller with `GameScope.of(context)`
(`lib/state/game_scope.dart`), an `InheritedNotifier`. `GameScope.read` is the
non-subscribing variant for `initState`.

### `List<Turn>` is the single source of truth

`startGame()` deals questions and builds an ordered `List<Turn>`
(`lib/models/turn.dart`). A `Turn` is one `(question, answerer, guesser)` unit
plus the answer, the guess and the host's verdict. Everything else — scores,
standings, progress, which couple is up — is **derived** from that list. Do not
add a parallel score or progress field; compute it from `_turns`.

The list is ordered couple by couple, and within a couple all of partner A's
questions (guessed by B) then all of B's. `advanceAfterReveal()` reads the next
turn to decide whether the next phase is another guess, a handoff to the other
partner, the between-couples scoreboard, or the results.

`Turn` is deliberately mutable — it is filled in across two phases of one
session, not a value type.

### Question dealing

Each player gets their **own** questions (`lib/data/question_dealer.dart`). Two
invariants, both covered by tests:

1. A player never sees the same question twice.
2. **Partners never share a question** — it would spoil the second reveal.

Questions are otherwise dealt without replacement across the whole table; only
when the pool runs dry do different couples start sharing.

### The question pack

`assets/questions/questions.json` — 92 questions, plain JSON so they can be
edited by hand. Every entry needs two voices: `selfPrompt` ("What is your
favourite nut?") and `partnerPrompt` with a `{name}` slot ("What is {name}'s
favourite nut?"). `QuestionRepository` parses strictly and throws on a bad
entry rather than skipping it. Categories are keyed by the ids in
`QuestionCategory`; adding a category means adding an enum value.

## Styling

Design tokens live in `lib/theme/` and screens should reach for them rather than
hard-coding values: `AppColors`, `AppGradients` (including
`AppGradients.forCouple(index)`, which fixes each couple's identity colour),
`AppTypography`, and `Insets` / `Radii` in `app_theme.dart`.

Outfit (display) and Inter (body) are bundled as local TTFs in `assets/fonts/` —
there is no `google_fonts` package and no runtime font fetch.

Shared widgets in `lib/widgets/` cover the whole visual system —
`GradientScaffold` (page chrome with the drifting backdrop blooms), `QuizCard`,
`GlowButton` / `GhostButton`, `HoldButton` (the press-and-hold privacy gate),
`ConfettiBurst`, `StandingsList`. Reuse these instead of building new
one-off containers.

Layout is phone-first; `GradientScaffold` caps content at
`Insets.maxContentWidth` so a desktop or browser window still reads as a phone.

## Tests

- `test/game_controller_test.dart` — phase machine and scoring, driven through
  full playthroughs with a fake repository.
- `test/question_dealer_test.dart` — the two dealing invariants.
- `test/question_repository_test.dart` — the real bundled pack parses and every
  question has both voices.
- `test/screens_golden_test.dart` — a PNG of every screen at phone size. These
  are **design** regressions; regenerate with `--update-goldens` after an
  intentional style change, and actually look at the diff.

Note the golden test loads the bundled fonts from disk via `FontLoader`, and
settles animations with explicit `pump(Duration)` calls — `pumpAndSettle` hangs
because the backdrop blooms loop forever.
