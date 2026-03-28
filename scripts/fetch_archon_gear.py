#!/usr/bin/env python3
"""Fetch top gear items per slot from Archon.gg gear-and-tier-set page."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from archon_common import fetch_archon_page, get_slot_name, parse_icon, parse_popularity

TOP_N = 3


def fetch_gear(spec_slug: str, class_slug: str, mode: str = "mythicplus") -> dict[str, list[dict]]:
    """Return top items per slot: {slot: [{id, name, popularity}, ...]}."""
    sections = fetch_archon_page(spec_slug, class_slug, "gear-and-tier-set", mode)

    # Find the section with gear tables
    gear_tables = None
    for section in sections:
        props = section.get("props", {})
        if "tables" in props and "warning" in props:
            gear_tables = props["tables"]
            break

    if not gear_tables:
        raise RuntimeError(f"No gear tables found for {spec_slug}/{class_slug}")

    result: dict[str, list[dict]] = {}
    for table in gear_tables:
        columns = table.get("columns", {})
        data = table.get("data", [])
        if not data:
            continue

        item_col = columns.get("item", {})
        slot = get_slot_name(item_col.get("header", ""))

        items = []
        for row in data[:TOP_N]:
            parsed = parse_icon(row.get("item", ""))
            pop = parse_popularity(row.get("popularity", row.get("popularityAndReportLink", "")))
            items.append({"id": parsed["id"], "name": parsed["name"], "popularity": pop})

        result[slot] = items

    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Fetch Archon gear data for a spec.")
    parser.add_argument("--spec", required=True, help="Spec slug (e.g. elemental)")
    parser.add_argument("--class", dest="class_slug", required=True, help="Class slug (e.g. shaman)")
    args = parser.parse_args()

    data = fetch_gear(args.spec, args.class_slug)
    print(json.dumps(data, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
