# Contributing

## Branch flow

This project uses a three-branch flow:

1. **`feature/*`** — all work happens on a feature branch cut from `staging`.
2. **`staging`** — feature branches open a PR into `staging` for review.
3. **`main`** — once changes are reviewed and verified on `staging`, `staging` is promoted to `main`.

Do not open PRs directly against `main`; target `staging`.

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for every commit
(e.g. `fix: ...`, `feat: ...`, `chore: ...`, `docs: ...`).

## Flutter foundation

- Run `flutter pub get`, `flutter gen-l10n`, `flutter analyze`, and
  `flutter test` before opening a UI PR.
- Add visual primitives to `lib/core/theme/tokens.dart`, routes to
  `lib/app/app_router.dart`, and localized copy to ARB files under `lib/l10n/`.
- Keep Demo and Live data behind the repository interfaces under
  `lib/data/repositories/`; never share persisted drafts, history, or auth
  between modes.
