# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- Add durable project-specific notes here as they are discovered through real work.
- Never surface a raw exception message, stack trace, or HTTP status code in user-facing UI copy. Route API/sign-in failures through `lib/core/errors/friendly_error.dart` (`FriendlyError.fromFailure`; pass `isSignIn: true` for sign-in attempts so a 401 reads as bad credentials, not an expired session) to get plain-language copy, and display it via `lib/core/widgets/friendly_error_banner.dart` (`FriendlyErrorBanner` / `showFriendlyErrorSnackBar`) rather than inventing a new error-display pattern per screen. Both expose a `mood` parameter as the intended drop-in point for a mascot character.
- Branch flow: create `feature/*` branches from `staging` and PR them into `staging` for review; `staging` promotes to `main`. Commits follow Conventional Commits. See `CONTRIBUTING.md`.
- Commit messages are plain and human-style: never add a co-author line, agent name, or any AI-attribution trailer (e.g. `Co-Authored-By: Claude/Codex/...`, `Generated with ...`). If your tooling appends this automatically, suppress it explicitly.
- Treat `lib/core/theme/tokens.dart` as the single source of truth for visual
  primitives; consume its colors, spacing, typography, and motion tokens rather
  than adding widget-local literals.
- Add routes through `lib/app/app_router.dart`, and keep feature screens inside
  its persistent shell rather than creating a second navigation stack.
- Register locales in `lib/core/localization/app_locale.dart` and add copy to
  `lib/l10n/*.arb`; unreviewed strings must retain the English per-string fallback.
- Read app language and Demo/Live mode through `AppSettingsScope`. Keep all
  drafts, history, auth, and repositories isolated by `AppMode.storageNamespace`.
- Use and extend `docs/manual-qa.md` when verifying or changing UI behaviour.
- Ripple's mood/render API lives in `lib/core/mascot/aqua_mascot.dart`; drive
  reusable gestures and narration visemes through `ripple_controller.dart`.
- Import `lib/core/widgets/component_kit.dart` for the reusable field UI
  primitives and evidence badges; their reduced-motion and semantic states are
  represented in the debug mascot gallery.
- Headings, titles and buttons use the bundled Baloo 2 face via
  `AppTypography.displayFontFamily`/`displayFamilyFor(locale)` (set on
  `app_theme.dart`'s `displaySmall`/`headlineMedium`/`titleLarge` and applied
  directly in `AquaButton`'s label style, since that shares `labelLarge` with
  non-heading chip/picture-choice text). It is a font asset
  (`assets/fonts/baloo2/`, OFL-licensed), not `google_fonts`, so it renders
  offline; never applies to Arabic, which always keeps Noto Sans Arabic.
  Everything else (body, labels, chips) stays on Noto Sans/`familyFor`.
- Icons are Phosphor (`phosphor_flutter`, MIT) everywhere: `PhosphorIconsRegular.*`
  for idle states, `PhosphorIconsFill.*` for selected/active ones -- do not
  reintroduce Material `Icons.*`. For concepts Phosphor doesn't cover (stream
  check, ripple drop, water quality, riparian bank, field safety, narration
  wave), use `WaterIconWidget`/`WaterIcon` from `lib/core/icons/water_icons.dart`
  instead of drawing a one-off `CustomPainter`.
- The captain builds locally on Flutter 3.41.7 stable (Dart 3.11.5). Before
  adding or upgrading any dependency in `pubspec.yaml`, check its `environment:`
  constraint on pub.dev and do not pick a version that needs a newer Flutter or
  Dart than that. Keep `environment.sdk: ^3.11.5` unless a future captain
  machine ships an older Dart that can't satisfy it.
- There is no Flutter/Dart SDK in this worktree; `flutter analyze` / `flutter test`
  can only be run by the captain. Review type correctness by reading, and ask
  the captain to paste the actual analyzer/test output rather than assuming a fix worked.
- Dart 3 sharp edge seen in `aqua_mascot.dart`: `math.max`/`math.min` on two
  `double` operands can still infer `num` (not `double`) when the call sits in
  a position with no downward double context (e.g. a bare `final x = ...`
  local, as opposed to a named arg typed `double`). If the result later feeds
  a `double`-typed parameter directly (not through `.clamp(...)`/`.toDouble()`),
  add an explicit `.toDouble()` at the declaration rather than threading the
  fix through every call site.
- A static member and an instance member can't share a name in the same Dart
  class (`conflicting_static_and_instance`); `RippleVisemeFrame` in
  `ripple_controller.dart` keeps the instance field `open` (mouth openness)
  and names the viseme preset `openMouth` to avoid this.
- `Radio`/`RadioListTile`'s `groupValue`/`onChanged` are deprecated since
  Flutter 3.32; wrap the group in a `RadioGroup<T>` ancestor that owns
  `groupValue`/`onChanged` instead (see the language picker in
  `lib/features/settings/settings_screen.dart`).
- The read-aloud narration pipeline (speaker control, word-by-word highlight,
  Ripple talk-viseme sync) lives in `lib/core/audio/` (`ReadAloudService`,
  `NarrationAudioPlayer`) and `lib/core/widgets/read_aloud_control.dart`
  (`ReadAloudControl`, `ReadAloudHighlightedText`); it is screen-agnostic, so
  reuse it rather than building a second player for assessment questions.
  Narration audio/timing assets are generated offline by
  `scripts/narration/generate_narration.py` -- see that directory's README for
  the Piper setup, regeneration steps, and a known espeak-ng word-boundary
  limitation. Never add a Python/TTS toolchain to the Flutter app itself.
- First-launch gating (`AppSettingsController.onboardingComplete`) and the
  `/onboarding` route in `lib/app/app_router.dart` are the only places that
  decide whether onboarding shows; replay it from Settings via
  `OnboardingScreen(isReplay: true)` rather than duplicating its screens.
- Live transport/auth is centralized in `lib/data/repositories/live_api_client.dart`
  and `auth_repository.dart`; inject `http.Client` and `TokenStore` in tests and
  keep every test on a fake client/base URI. Demo assessment/reference content
  comes from the bundled `assets/data/assessment-content.json` and must never
  fall through to Live networking.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
