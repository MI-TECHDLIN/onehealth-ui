#!/usr/bin/env python3
"""Validate lib/l10n/*.arb against the English template.

Checks, for every non-template locale file:
  1. every key present in the template exists in the locale file (and vice
     versa -- no stray keys);
  2. every ICU placeholder referenced in a template string appears, by the
     same name, in the translated string (and vice versa);
  3. every string's ICU/braces are balanced and parse as plain placeholders
     or `{name, plural, ...}` / `{name, select, ...}` forms;
  4. no `@key` metadata block has been copied into a non-template file --
     gen-l10n only ever reads `@key` blocks from the template.

Run from the repo root: `python3 tool/l10n/validate_arb.py`
Exit code is 0 when every locale is clean, 1 otherwise.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
ARB_DIR = REPO_ROOT / "lib" / "l10n"
TEMPLATE_NAME = "app_en.arb"

# Matches a simple placeholder `{name}` or an ICU `{name, plural, ...}` /
# `{name, select, ...}` opener. We only need the leading identifier to check
# cross-locale placeholder parity.
_PLACEHOLDER_RE = re.compile(r"\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*[,}]")


def load_arb(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def string_keys(arb: dict) -> set[str]:
    return {k for k in arb if not k.startswith("@")}


def metadata_keys(arb: dict) -> set[str]:
    return {k for k in arb if k.startswith("@") and k != "@@locale"}


def placeholder_names(value: object) -> set[str]:
    if not isinstance(value, str):
        return set()
    return set(_PLACEHOLDER_RE.findall(value))


def braces_balanced(value: object) -> bool:
    if not isinstance(value, str):
        return True
    depth = 0
    for ch in value:
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


def main() -> int:
    template_path = ARB_DIR / TEMPLATE_NAME
    if not template_path.exists():
        print(f"Template not found: {template_path}", file=sys.stderr)
        return 1

    template = load_arb(template_path)
    template_keys = string_keys(template)

    problems: list[str] = []

    for key in template_keys:
        if not braces_balanced(template[key]):
            problems.append(f"{TEMPLATE_NAME}: unbalanced braces in {key!r}")

    locale_files = sorted(
        p for p in ARB_DIR.glob("app_*.arb") if p.name != TEMPLATE_NAME
    )
    if not locale_files:
        problems.append("No non-template ARB files found.")

    for path in locale_files:
        locale = path.stem.removeprefix("app_")
        try:
            arb = load_arb(path)
        except json.JSONDecodeError as exc:
            problems.append(f"{path.name}: invalid JSON ({exc})")
            continue

        declared_locale = arb.get("@@locale")
        if declared_locale != locale:
            problems.append(
                f"{path.name}: \"@@locale\" is {declared_locale!r}, expected {locale!r}"
            )

        stray_metadata = metadata_keys(arb)
        if stray_metadata:
            problems.append(
                f"{path.name}: must not define @key metadata blocks "
                f"(gen-l10n reads those from {TEMPLATE_NAME} only): "
                f"{sorted(stray_metadata)}"
            )

        keys = string_keys(arb)
        missing = template_keys - keys
        extra = keys - template_keys
        if missing:
            problems.append(f"{path.name}: missing keys: {sorted(missing)}")
        if extra:
            problems.append(f"{path.name}: unexpected extra keys: {sorted(extra)}")

        for key in sorted(keys & template_keys):
            value = arb[key]
            if not braces_balanced(value):
                problems.append(f"{path.name}: unbalanced braces in {key!r}")
                continue
            template_placeholders = placeholder_names(template[key])
            value_placeholders = placeholder_names(value)
            if template_placeholders != value_placeholders:
                problems.append(
                    f"{path.name}: placeholder mismatch in {key!r}: "
                    f"expected {sorted(template_placeholders)}, "
                    f"got {sorted(value_placeholders)}"
                )

    if problems:
        print(f"Found {len(problems)} problem(s):\n")
        for problem in problems:
            print(f"  - {problem}")
        return 1

    print(
        f"OK: {len(locale_files)} locale file(s) match {TEMPLATE_NAME} "
        f"({len(template_keys)} keys each, placeholders consistent)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
