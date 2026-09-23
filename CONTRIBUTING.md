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
