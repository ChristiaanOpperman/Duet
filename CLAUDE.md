# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

**Duet** is a couples trivia party game for one shared device. Up to six couples
play. One partner answers a question about themselves, the other tries to guess
that answer, the host judges it and points go to the couple.

There are **two modes** (`lib/models/game_mode.dart`), chosen on the home
screen. They deal the same questions in the same order and score identically —
they differ only in where the answers get written.

Single Flutter app, no backend, no network, no database. Finished games are
kept **in memory for the app session only** so they can be reviewed; closing
the app discards everything.

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

`chrome`, `macos`, the iOS Simulator and a physical iPhone all work. Android
still needs the SDK cmdline-tools.

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
turn to decide what comes next — another question, a handoff to the other
partner, the between-couples scoreboard, or the results — and is shared by both
modes.

### The two modes

`GameSettings.mode` selects between them and `GameRecord.mode` remembers which
one produced a finished game.

- **Classic** — `answerHandoff → answering` for every player up front, then
  `guessHandoff → guessing → reveal` per turn. Answers and guesses are typed,
  so `Turn.answer` and `Turn.guess` are populated and the reveal shows them
  side by side.
- **Pen & paper** — `paperPrompt → paperVerdict` per turn, and nothing else.
  `startGame` skips the private answer round entirely, and there are no handoff
  gates because everyone can see the question. **`Turn.answer` and
  `Turn.guess` stay empty** — the app never learns what was written, only the
  host's verdict. Anything rendering a turn must handle that; the recap checks
  `record.mode.isPaper` and shows the verdict alone rather than empty lines.

A test asserts a paper game never passes through a typing or handoff phase, and
another asserts both modes deal an identical turn structure from the same seed.

`Turn` is deliberately mutable — it is filled in across two phases of one
session, not a value type.

### Session history

`GameController._history` holds a `GameRecord` (`lib/models/game_record.dart`)
per game played since launch, newest first via the `history` getter.
`_archiveCurrentGame()` snapshots the current game and is called on reaching
results, on `playAgain`, `newGame` and `quitToHome`. It is idempotent (guarded
by `_currentGameArchived`, reset in `startGame`) and skips games where nothing
was ever judged.

A record captures the turn list **by reference**, which is only safe because
`startGame` always builds a brand new list — never reuse or mutate `_turns` in
place, or archived games will silently change.

This history is deliberately **not persisted**. There is no disk write and no
storage plugin; the home screen copy ("Cleared when you close the app") says so
to the user. Adding real persistence means adding a dependency — see Platforms.

Scoring lives in `computeStandings()` (`lib/models/standing.dart`) so the live
game and an archived record can never disagree.

### Question dealing

Each player gets their **own** questions (`lib/data/question_dealer.dart`). Two
invariants, both covered by tests:

1. A player never sees the same question twice.
2. **Partners never share a question** — it would spoil the second reveal.

Questions are otherwise dealt without replacement across the whole table; only
when the pool runs dry do different couples start sharing.

### The question pack

`assets/questions/questions.json` — 167 questions, plain JSON so they can be
edited by hand. Every entry needs two voices: `selfPrompt` ("What is your
favourite nut?") and `partnerPrompt` with a `{name}` slot ("What is {name}'s
favourite nut?"). `QuestionRepository` parses strictly and throws on a bad
entry rather than skipping it. Categories are keyed by the ids in
`QuestionCategory`; adding a category means adding an enum value.

Seven bundled categories: Favourites, Habits & Quirks, Our History, Would You
Rather, Just for Fun, Deep & Meaningful and Spice. **Spice is the only one off
by default** — it is bedroom-flavoured and a host should opt in rather than
discover it with the in-laws at the table. `GameSettings.categories` omits it
and a test enforces that.

A handful of questions in each category are South African — braai sides,
padkos, Ouma rusks, load shedding, Klippies and Coke, coast-versus-bushveld
holidays. It is a light seasoning by design, roughly one question in six; keep
it that way when adding more so the pack still plays anywhere.

Two tests guard the pack's size: every category alone holds enough for six
couples at seven questions each (`QuestionDealer.minimumPoolSize(7)`), so a
host can pick a single category and still start.

`QuestionCategory.custom` is reserved for questions players write during a
session — the bundled pack must never use it, and a repository test enforces
that. The chip for it only appears on the options screen once something has
been written.

### Custom questions

`GameController` holds `_customQuestions` in memory for the session, merged
into `allQuestions` and therefore into `eligibleQuestions` and the deal.
`addCustomQuestion` rejects a partner prompt with no `{name}` token — the
presenter would have no way to say whose answer it wants — and switches the
`custom` category on, since a question added while its category is off would
silently never appear.

`derivePartnerPrompt` (`lib/data/partner_prompt.dart`) writes the second voice
from the first: "What is your favourite nut?" → "What is {name}'s favourite
nut?". Two things matter about it:

- It is a **suggestion**, never applied silently. The screen shows it in an
  editable field with a live preview using a real player's name, and stops
  overwriting once the author edits it by hand.
- Only the *first* pronoun becomes the name; later ones become "they"/"their".
  Naming someone twice reads like a form letter ("What does Alex do when Alex
  cannot sleep?"). This is why it is a single left-to-right scan over one
  combined regex rather than a `replaceAll` per rule — a per-rule pass cannot
  know what an earlier rule already replaced.

## Styling

Design tokens live in `lib/theme/` and screens should reach for them rather than
hard-coding values: `AppColors`, `AppGradients` (including
`AppGradients.forCouple(index)`, which fixes each couple's identity colour),
`AppTypography`, and `Insets` / `Radii` in `app_theme.dart`.

Outfit (display) and Inter (body) are bundled as local TTFs in `assets/fonts/` —
there is no `google_fonts` package and no runtime font fetch.

Shared widgets in `lib/widgets/` cover the whole visual system —
`GradientScaffold` (page chrome with the drifting backdrop blooms), `QuizCard`,
`GlowButton` / `GhostButton`, `HoldButton` (the press-and-hold privacy gate,
classic mode only), `ConfettiBurst`, `StandingsList`. Reuse these instead of building new
one-off containers.

Layout is phone-first; `GradientScaffold` caps content at
`Insets.maxContentWidth` so a desktop or browser window still reads as a phone.

## Tests

- `test/game_controller_test.dart` — phase machine and scoring, driven through
  full playthroughs with a fake repository, plus `session history`,
  `custom questions` and `pen & paper mode` groups.
- `test/partner_prompt_test.dart` — the first-person to second-person rules,
  including that the name appears exactly once.
- `test/question_dealer_test.dart` — the two dealing invariants.
- `test/question_repository_test.dart` — the real bundled pack parses and every
  question has both voices.
- `test/screens_golden_test.dart` — a PNG of every screen at phone size. These
  are **design** regressions; regenerate with `--update-goldens` after an
  intentional style change, and actually look at the diff.

Note the golden test loads the bundled fonts from disk via `FontLoader`, and
settles animations with explicit `pump(Duration)` calls — `pumpAndSettle` hangs
because the backdrop blooms loop forever.
