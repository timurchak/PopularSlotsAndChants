#!/usr/bin/env python3
"""Validate that generated addon data contains every spec and game mode."""

from __future__ import annotations

import argparse
import re
from datetime import datetime, timezone
from pathlib import Path

from archon_common import GAME_MODES, SPEC_ID_BY_SLUG

DEFAULT_INPUT = Path(__file__).resolve().parent.parent / "PopularSlotsAndChants_Data.lua"
MODE_FIELDS = (
    "gear",
    "enchants",
    "epicGems",
    "gems",
    "consumables",
    "talents",
    "stats",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate generated Archon Lua data.")
    parser.add_argument("path", type=Path, nargs="?", default=DEFAULT_INPUT)
    parser.add_argument(
        "--max-age-hours",
        type=float,
        default=None,
        help="Reject data older than this many hours.",
    )
    return parser.parse_args()


def count_key(lua_content: str, key: str) -> int:
    return lua_content.count(f'["{key}"] = {{')


def main() -> int:
    args = parse_args()
    lua_content = args.path.read_text(encoding="utf-8")
    expected_specs = len(SPEC_ID_BY_SLUG)
    expected_mode_results = expected_specs * len(GAME_MODES)
    errors: list[str] = []

    generated_at_match = re.search(
        r'\["generatedAtUtc"\] = "([^"]+)"',
        lua_content,
    )
    if not generated_at_match:
        errors.append("generatedAtUtc is missing")
    elif args.max_age_hours is not None:
        generated_at = datetime.fromisoformat(generated_at_match.group(1))
        age_hours = (datetime.now(timezone.utc) - generated_at).total_seconds() / 3600
        if age_hours < -0.25:
            errors.append(f"generatedAtUtc is {-age_hours:.1f} hours in the future")
        elif age_hours > args.max_age_hours:
            errors.append(
                f"generated data is {age_hours:.1f} hours old; "
                f"maximum is {args.max_age_hours:g}"
            )

    for mode in GAME_MODES:
        actual = count_key(lua_content, mode)
        if actual != expected_specs:
            errors.append(f"{mode}: expected {expected_specs}, found {actual}")

    for field in MODE_FIELDS:
        actual = count_key(lua_content, field)
        if actual != expected_mode_results:
            errors.append(f"{field}: expected {expected_mode_results}, found {actual}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1

    print(f"Validated {expected_specs} specs across {len(GAME_MODES)} modes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
