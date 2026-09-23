# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- Add durable project-specific notes here as they are discovered through real work.
- Never surface a raw exception message, stack trace, or HTTP status code in user-facing UI copy. Route API/sign-in failures through `lib/core/errors/friendly_error.dart` (`FriendlyError.fromFailure`; pass `isSignIn: true` for sign-in attempts so a 401 reads as bad credentials, not an expired session) to get plain-language copy, and display it via `lib/core/widgets/friendly_error_banner.dart` (`FriendlyErrorBanner` / `showFriendlyErrorSnackBar`) rather than inventing a new error-display pattern per screen. Both expose a `mood` parameter as the intended drop-in point for a mascot character.
- Branch flow: `feature/*` branches PR into `staging` for review; `staging` promotes to `main`. Commits follow Conventional Commits. See `CONTRIBUTING.md`.
- Commit messages are plain and human-style: never add a co-author line, agent name, or any AI-attribution trailer (e.g. `Co-Authored-By: Claude/Codex/...`, `Generated with ...`). If your tooling appends this automatically, suppress it explicitly.
- Treat `lib/core/theme/tokens.dart` as the single source of truth for visual
  primitives; consume its colors, spacing, typography, and motion tokens rather
  than adding widget-local literals.
- Create feature branches from `staging`, target pull requests to `staging`, and
  use Conventional Commits.
- Never add a co-author line, agent name, or any AI-attribution trailer (e.g. no
  'Co-Authored-By: Claude/Codex/...', no 'Generated with' footer) to any commit
  message. Plain, human-style commit messages only.
  'Use MI-TECHDLIN to commit instead of traysesupport

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
