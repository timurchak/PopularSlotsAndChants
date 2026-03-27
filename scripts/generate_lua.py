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
from archon_common import SPEC_ID_BY_SLUG, format_lua_table
from fetch_archon_consumables import fetch_consumables
from fetch_archon_enchants import fetch_enchants_and_gems
from fetch_archon_gear import fetch_gear

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
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    slugs = list(SPEC_ID_BY_SLUG.keys())
    if args.spec_filter:
        if args.spec_filter not in SPEC_ID_BY_SLUG:
            raise SystemExit(f"error: unknown spec '{args.spec_filter}'. Valid: {', '.join(sorted(slugs))}")
        slugs = [args.spec_filter]

    specs: dict[str, dict] = {}
    spec_ids: dict[int, str] = {}
    total = len(slugs)

    for i, slug in enumerate(slugs, 1):
        class_slug, spec_slug = slug.split("/")
        spec_id = SPEC_ID_BY_SLUG[slug]
        print(f"[{i}/{total}] {slug} (specID={spec_id})...", flush=True)

        try:
            gear = fetch_gear(spec_slug, class_slug)
            time.sleep(REQUEST_DELAY)

            enchants_data = fetch_enchants_and_gems(spec_slug, class_slug)
            time.sleep(REQUEST_DELAY)

            consumables = fetch_consumables(spec_slug, class_slug)
            time.sleep(REQUEST_DELAY)
        except Exception as e:
            print(f"  ERROR: {e}", file=sys.stderr)
            continue

        specs[slug] = {
            "specID": spec_id,
            "classSlug": class_slug,
            "specSlug": spec_slug,
            "gear": gear,
            "enchants": enchants_data["enchants"],
            "epicGems": enchants_data["epicGems"],
            "gems": enchants_data["gems"],
            "consumables": consumables,
        }
        spec_ids[spec_id] = slug
        print(f"  OK: {len(gear)} gear slots, {len(enchants_data['enchants'])} enchant slots, "
              f"{len(enchants_data['epicGems'])} epic gems, {len(enchants_data['gems'])} gems, "
              f"{len(consumables)} consumables")

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
        "failed": total - len(specs),
    }
    print(json.dumps(summary, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
