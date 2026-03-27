#!/usr/bin/env python3
"""Fetch enchant and gem data from Archon.gg enchants-and-gems page."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from archon_common import fetch_archon_page, get_slot_name, parse_icon, parse_popularity

TOP_N = 3


def fetch_enchants_and_gems(spec_slug: str, class_slug: str) -> dict:
    """Return enchants by slot, epic gems, and gems."""
    sections = fetch_archon_page(spec_slug, class_slug, "enchants-and-gems")

    result = {"enchants": {}, "epicGems": [], "gems": []}

    for section in sections:
        props = section.get("props", {})
        title = props.get("title", "")

        # Enchant Tables — section with tables[] and "Enchant Tables" in title
        if "tables" in props and "Enchant" in title:
            for table in props["tables"]:
                columns = table.get("columns", {})
                data = table.get("data", [])
                if not data:
                    continue
                slot = get_slot_name(columns.get("item", {}).get("header", ""))
                items = []
                for row in data[:TOP_N]:
                    parsed = parse_icon(row.get("item", ""))
                    pop = parse_popularity(row.get("popularity", row.get("popularityAndReportLink", "")))
                    items.append({"id": parsed["id"], "name": parsed["name"], "popularity": pop})
                result["enchants"][slot] = items

        # Epic Gems — single table with "Epic Gem" in title
        elif "table" in props and "Epic Gem" in title:
            for row in props["table"].get("data", [])[:TOP_N]:
                parsed = parse_icon(row.get("item", ""))
                pop = parse_popularity(row.get("popularity", row.get("popularityAndReportLink", "")))
                result["epicGems"].append({"id": parsed["id"], "name": parsed["name"], "popularity": pop})

        # Gems — single table with "Gems" in title but not "Epic"
        elif "table" in props and "Gem" in title and "Epic" not in title:
            for row in props["table"].get("data", [])[:TOP_N]:
                parsed = parse_icon(row.get("item", ""))
                pop = parse_popularity(row.get("popularity", row.get("popularityAndReportLink", "")))
                result["gems"].append({"id": parsed["id"], "name": parsed["name"], "popularity": pop})

    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Fetch Archon enchant/gem data for a spec.")
    parser.add_argument("--spec", required=True, help="Spec slug (e.g. restoration)")
    parser.add_argument("--class", dest="class_slug", required=True, help="Class slug (e.g. shaman)")
    args = parser.parse_args()

    data = fetch_enchants_and_gems(args.spec, args.class_slug)
    print(json.dumps(data, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
