# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- Treat `lib/core/theme/tokens.dart` as the single source of truth for visual
  primitives; consume its colors, spacing, typography, and motion tokens rather
  than adding widget-local literals.
- Create feature branches from `staging`, target pull requests to `staging`, and
  use Conventional Commits.
- Never add a co-author line, agent name, or any AI-attribution trailer (e.g. no
  'Co-Authored-By: Claude/Codex/...', no 'Generated with' footer) to any commit
  message. Plain, human-style commit messages only.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
