#!/usr/bin/env python3
"""Fetch consumable data from Archon.gg consumables page."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from archon_common import fetch_archon_page, parse_icon, parse_popularity


def fetch_consumables(spec_slug: str, class_slug: str, mode: str = "mythicplus") -> dict[str, dict]:
    """Return top consumable per category: {category: {id, name, popularity}}."""
    sections = fetch_archon_page(spec_slug, class_slug, "consumables", mode)

    result: dict[str, dict] = {}

    for section in sections:
        props = section.get("props", {})
        if "itemBreakdowns" not in props:
            continue

        for item in props["itemBreakdowns"]:
            category = item.get("slotLabel", "Unknown")
            parsed = parse_icon(item.get("itemMarkdown", ""))
            pop = parse_popularity(item.get("popularityMarkdown", ""))
            entry = {"id": parsed["id"], "name": parsed["name"], "popularity": pop}
            if parsed.get("isSpell"):
                entry["isSpell"] = True
            result[category] = entry

    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Fetch Archon consumable data for a spec.")
    parser.add_argument("--spec", required=True, help="Spec slug (e.g. feral)")
    parser.add_argument("--class", dest="class_slug", required=True, help="Class slug (e.g. druid)")
    args = parser.parse_args()

    data = fetch_consumables(args.spec, args.class_slug)
    print(json.dumps(data, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
