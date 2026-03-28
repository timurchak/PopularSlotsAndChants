#!/usr/bin/env python3
"""Generate a Lua data file from Archon.gg for all 40 WoW specs."""

from __future__ import annotations

import argparse
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from archon_common import GAME_MODES, SPEC_ID_BY_SLUG, format_lua_table
from fetch_archon_consumables import fetch_consumables
from fetch_archon_enchants import fetch_enchants_and_gems
from fetch_archon_gear import fetch_gear
from fetch_archon_stats import fetch_stats
from fetch_archon_talents import fetch_talents

DEFAULT_OUTPUT = Path(__file__).resolve().parent.parent / "PopularSlotsAndChants_Data.lua"
REQUEST_DELAY = 0.5  # seconds between HTTP requests


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate Archon data Lua file for all specs.")
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Lua output path (default: {DEFAULT_OUTPUT}).",
    )
    parser.add_argument(
        "--spec-filter",
        default=None,
        help="Only process this spec slug (e.g. 'shaman/elemental') for testing.",
    )
    parser.add_argument(
        "--mode",
        choices=["mythicplus", "raid", "all"],
        default="all",
        help="Which game mode to fetch (default: all).",
    )
    return parser.parse_args()


def fetch_mode_data(spec_slug: str, class_slug: str, mode: str) -> dict:
    """Fetch all data categories for a single spec and mode."""
    gear = fetch_gear(spec_slug, class_slug, mode)
    time.sleep(REQUEST_DELAY)

    enchants_data = fetch_enchants_and_gems(spec_slug, class_slug, mode)
    time.sleep(REQUEST_DELAY)

    consumables = fetch_consumables(spec_slug, class_slug, mode)
    time.sleep(REQUEST_DELAY)

    talents = fetch_talents(spec_slug, class_slug, mode)
    time.sleep(REQUEST_DELAY)

    stats = fetch_stats(spec_slug, class_slug, mode)
    time.sleep(REQUEST_DELAY)

    return {
        "gear": gear,
        "enchants": enchants_data["enchants"],
        "epicGems": enchants_data["epicGems"],
        "gems": enchants_data["gems"],
        "consumables": consumables,
        "talents": talents,
        "stats": stats,
    }


def main() -> int:
    args = parse_args()

    slugs = list(SPEC_ID_BY_SLUG.keys())
    if args.spec_filter:
        if args.spec_filter not in SPEC_ID_BY_SLUG:
            raise SystemExit(f"error: unknown spec '{args.spec_filter}'. Valid: {', '.join(sorted(slugs))}")
        slugs = [args.spec_filter]

    modes = list(GAME_MODES.keys()) if args.mode == "all" else [args.mode]

    specs: dict[str, dict] = {}
    spec_ids: dict[int, str] = {}
    total = len(slugs)
    failed = 0

    for mode in modes:
        print(f"\n=== Mode: {mode} ===", flush=True)
        for i, slug in enumerate(slugs, 1):
            class_slug, spec_slug = slug.split("/")
            spec_id = SPEC_ID_BY_SLUG[slug]
            print(f"[{i}/{total}] {slug} (specID={spec_id}, {mode})...", flush=True)

            # Initialize spec entry on first encounter
            if slug not in specs:
                specs[slug] = {
                    "specID": spec_id,
                    "classSlug": class_slug,
                    "specSlug": spec_slug,
                }
                spec_ids[spec_id] = slug

            try:
                mode_data = fetch_mode_data(spec_slug, class_slug, mode)
            except Exception as e:
                print(f"  ERROR: {e}", file=sys.stderr)
                failed += 1
                continue

            specs[slug][mode] = mode_data
            md = mode_data
            print(f"  OK: {len(md['gear'])} gear slots, {len(md['enchants'])} enchant slots, "
                  f"{len(md['epicGems'])} epic gems, {len(md['gems'])} gems, "
                  f"{len(md['consumables'])} consumables, "
                  f"{len(md['talents'].get('builds', []))} talent builds, "
                  f"{len(md['stats'])} stats")

    dataset = {
        "generatedAtUtc": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "source": "Archon.gg",
        "specIDs": dict(sorted(spec_ids.items())),
        "specs": specs,
    }

    lua_content = (
        "local _, ns = ...\n\n"
        f"ns.ArchonData = {format_lua_table(dataset)}\n"
    )
    args.output.write_text(lua_content, encoding="utf-8")

    summary = {
        "output": str(args.output),
        "specCount": len(specs),
        "modes": modes,
        "failed": failed,
    }
    print(json.dumps(summary, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
