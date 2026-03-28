#!/usr/bin/env python3
"""Fetch stat priority data from Archon.gg overview page."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from archon_common import fetch_archon_page


def fetch_stats(spec_slug: str, class_slug: str) -> list[dict]:
    """Return stat priorities from the overview page."""
    sections = fetch_archon_page(spec_slug, class_slug, "overview")

    for section in sections:
        props = section.get("props", {})
        if "stats" in props:
            result = []
            for stat in sorted(props["stats"], key=lambda s: s.get("order", 99)):
                result.append({
                    "name": stat["name"],
                    "order": stat["order"],
                    "value": stat["value"],
                })
            return result

    return []


def main() -> int:
    parser = argparse.ArgumentParser(description="Fetch Archon stat priority data for a spec.")
    parser.add_argument("--spec", required=True, help="Spec slug (e.g. elemental)")
    parser.add_argument("--class", dest="class_slug", required=True, help="Class slug (e.g. shaman)")
    args = parser.parse_args()

    data = fetch_stats(args.spec, args.class_slug)
    print(json.dumps(data, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
