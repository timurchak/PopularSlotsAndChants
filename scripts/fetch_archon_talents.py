#!/usr/bin/env python3
"""Fetch talent build data from Archon.gg talents page."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from archon_common import archon_url, fetch_archon_next_data, parse_popularity

TOP_N = 3


def fetch_talents(spec_slug: str, class_slug: str, mode: str = "mythicplus") -> dict:
    """Return talent builds with export strings and hero tree info."""
    url = archon_url(spec_slug, class_slug, "talents", mode)
    parsed = fetch_archon_next_data(url)
    page = parsed["props"]["pageProps"]["page"]

    result = {"heroTrees": [], "builds": []}

    # Hero tree names from blueprints
    hero_names: dict[int, str] = {}
    for bp in page.get("talentTreeBlueprints", {}).values():
        for ht in bp.get("heroTrees", []):
            hero_names[ht["id"]] = ht.get("name", f"Hero {ht['id']}")

    # Hero tree stats
    for section in page["sections"]:
        props = section.get("props", {})
        if "subTreeStats" in props:
            for st in props["subTreeStats"]:
                hero_id = st["id"]
                result["heroTrees"].append({
                    "id": hero_id,
                    "name": hero_names.get(hero_id, f"Hero {hero_id}"),
                    "rank": st["rank"],
                })

    # Talent builds with export codes
    for section in page["sections"]:
        props = section.get("props", {})
        if "talentTreeBuildSets" not in props:
            continue
        for build_set in props["talentTreeBuildSets"]:
            for alt in build_set.get("alternatives", [])[:TOP_N]:
                tree = alt.get("talentTree", {})
                export_code = tree.get("exportCodeParams", {}).get("exportCode", "")
                hero_id = tree.get("dehydratedBuild", {}).get("heroSpecId")

                result["builds"].append({
                    "title": alt.get("title", "Build"),
                    "popularity": parse_popularity(alt.get("popularity", "0%")),
                    "exportCode": export_code,
                    "heroTree": hero_names.get(hero_id, "") if hero_id else "",
                    "heroTreeID": hero_id or 0,
                })
            break  # only first build set

    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Fetch Archon talent data for a spec.")
    parser.add_argument("--spec", required=True, help="Spec slug (e.g. protection)")
    parser.add_argument("--class", dest="class_slug", required=True, help="Class slug (e.g. paladin)")
    args = parser.parse_args()

    data = fetch_talents(args.spec, args.class_slug)
    print(json.dumps(data, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
