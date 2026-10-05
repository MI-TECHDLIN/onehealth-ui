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
_IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
_OPTION_RE = re.compile(r"(?:=?-?\d+(?:\.\d+)?|[A-Za-z_][A-Za-z0-9_-]*)")


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


def _matching_brace(value: str, start: int) -> int:
    depth = 0
    for index in range(start, len(value)):
        if value[index] == "{":
            depth += 1
        elif value[index] == "}":
            depth -= 1
            if depth == 0:
                return index
    return -1


def _split_top_level(value: str, maxsplit: int) -> list[str]:
    parts: list[str] = []
    start = 0
    depth = 0
    for index, char in enumerate(value):
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
        elif char == "," and depth == 0 and len(parts) < maxsplit:
            parts.append(value[start:index].strip())
            start = index + 1
    parts.append(value[start:].strip())
    return parts


def _validate_argument(argument: str) -> str | None:
    parts = _split_top_level(argument, 2)
    if not parts[0] or not _IDENTIFIER_RE.fullmatch(parts[0]):
        return f"invalid placeholder name {parts[0]!r}"
    if len(parts) == 1:
        return None

    argument_type = parts[1]
    if argument_type in {"number", "date", "time"}:
        return None
    if argument_type not in {"plural", "select", "selectordinal"}:
        return f"unsupported ICU argument type {argument_type!r}"
    if len(parts) != 3 or not parts[2]:
        return f"{argument_type} argument has no options"

    options = parts[2]
    if argument_type in {"plural", "selectordinal"}:
        offset = re.match(r"offset\s*:\s*\d+\s*", options)
        if offset:
            options = options[offset.end() :]

    option_names: set[str] = set()
    index = 0
    while index < len(options):
        while index < len(options) and options[index].isspace():
            index += 1
        match = _OPTION_RE.match(options, index)
        if match is None:
            return f"invalid {argument_type} option near {options[index:]!r}"
        option_names.add(match.group())
        index = match.end()
        while index < len(options) and options[index].isspace():
            index += 1
        if index >= len(options) or options[index] != "{":
            return f"option {match.group()!r} has no message block"
        end = _matching_brace(options, index)
        if end < 0:
            return f"option {match.group()!r} has an unclosed message block"
        nested_error = validate_icu(options[index + 1 : end])
        if nested_error:
            return f"option {match.group()!r}: {nested_error}"
        index = end + 1

    if "other" not in option_names:
        return f"{argument_type} argument is missing its other option"
    return None


def validate_icu(value: object) -> str | None:
    """Return a concise parse error, or None for a valid ICU message."""
    if not isinstance(value, str):
        return "value is not a string"
    index = 0
    while index < len(value):
        if value[index] == "}":
            return "unexpected closing brace"
        if value[index] != "{":
            index += 1
            continue
        end = _matching_brace(value, index)
        if end < 0:
            return "unclosed opening brace"
        argument_error = _validate_argument(value[index + 1 : end])
        if argument_error:
            return argument_error
        index = end + 1
    return None


def main() -> int:
    template_path = ARB_DIR / TEMPLATE_NAME
    if not template_path.exists():
        print(f"Template not found: {template_path}", file=sys.stderr)
        return 1

    template = load_arb(template_path)
    template_keys = string_keys(template)

    problems: list[str] = []

    for key in template_keys:
        icu_error = validate_icu(template[key])
        if icu_error:
            problems.append(f"{TEMPLATE_NAME}: invalid ICU in {key!r}: {icu_error}")

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
            icu_error = validate_icu(value)
            if icu_error:
                problems.append(
                    f"{path.name}: invalid ICU in {key!r}: {icu_error}"
                )
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
