"""Shared utilities for Archon.gg data fetching and Lua generation."""

from __future__ import annotations

import json
import re
import subprocess
from typing import Any


# WoW spec ID mapping (class/spec → numeric ID)
SPEC_ID_BY_SLUG = {
    "death-knight/blood": 250,
    "death-knight/frost": 251,
    "death-knight/unholy": 252,
    "demon-hunter/havoc": 577,
    "demon-hunter/vengeance": 581,
    "demon-hunter/devourer": 1480,
    "druid/balance": 102,
    "druid/feral": 103,
    "druid/guardian": 104,
    "druid/restoration": 105,
    "evoker/devastation": 1467,
    "evoker/preservation": 1468,
    "evoker/augmentation": 1473,
    "hunter/beast-mastery": 253,
    "hunter/marksmanship": 254,
    "hunter/survival": 255,
    "mage/arcane": 62,
    "mage/fire": 63,
    "mage/frost": 64,
    "monk/brewmaster": 268,
    "monk/mistweaver": 270,
    "monk/windwalker": 269,
    "paladin/holy": 65,
    "paladin/protection": 66,
    "paladin/retribution": 70,
    "priest/discipline": 256,
    "priest/holy": 257,
    "priest/shadow": 258,
    "rogue/assassination": 259,
    "rogue/outlaw": 260,
    "rogue/subtlety": 261,
    "shaman/elemental": 262,
    "shaman/enhancement": 263,
    "shaman/restoration": 264,
    "warlock/affliction": 265,
    "warlock/demonology": 266,
    "warlock/destruction": 267,
    "warrior/arms": 71,
    "warrior/fury": 72,
    "warrior/protection": 73,
}

ARCHON_BASE = "https://www.archon.gg/wow/builds"

GAME_MODES = {
    "mythicplus": {"path": "mythic-plus", "suffix": "10/all-dungeons/this-week"},
    "raid":       {"path": "raid",        "suffix": "mythic/all-bosses"},
}


def archon_url(spec_slug: str, class_slug: str, page_type: str, mode: str = "mythicplus") -> str:
    """Build an Archon.gg URL. Archon uses {spec}/{class} order."""
    m = GAME_MODES[mode]
    return f"{ARCHON_BASE}/{spec_slug}/{class_slug}/{m['path']}/{page_type}/{m['suffix']}"


def fetch_archon_page(spec_slug: str, class_slug: str, page_type: str, mode: str = "mythicplus") -> list[dict]:
    """Fetch an Archon.gg page and return its sections from __NEXT_DATA__."""
    url = archon_url(spec_slug, class_slug, page_type, mode)
    result = subprocess.run(
        [
            "curl", "-s",
            "-H", "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                   "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "-H", "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            url,
        ],
        capture_output=True,
        text=True,
        timeout=30,
    )
    if result.returncode != 0:
        raise RuntimeError(f"curl failed for {url}: {result.stderr}")

    html = result.stdout
    match = re.search(r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>', html, re.DOTALL)
    if not match:
        raise RuntimeError(f"No __NEXT_DATA__ found in {url}")

    parsed = json.loads(match.group(1))
    return parsed["props"]["pageProps"]["page"]["sections"]


def parse_icon(markup: str) -> dict[str, Any]:
    """Parse item/spell ID and name from <GearIcon>, <ItemIcon>, or <SpellIcon> markup."""
    item_id_m = re.search(r"id=\{(\d+)\}", markup)
    name_m = re.search(r">([^<>{]+)</(?:GearIcon|ItemIcon|SpellIcon)>", markup)
    if not name_m:
        name_m = re.search(r"&nbsp;([^<]+)</", markup)
    return {
        "id": int(item_id_m.group(1)) if item_id_m else 0,
        "name": name_m.group(1).strip() if name_m else "Unknown",
    }


def parse_popularity(markup: str) -> float:
    """Parse popularity percentage from <Styled>XX.X%</Styled> or plain string."""
    m = re.search(r"([\d.]+)%", markup)
    return float(m.group(1)) if m else 0.0


def get_slot_name(column_header: str) -> str:
    """Extract slot name from column header like <ImageIcon ...>Main-Hand</ImageIcon>."""
    m = re.search(r">([^<]+)</ImageIcon>", column_header)
    return m.group(1) if m else "Unknown"


# --- Lua formatting (from BetterGearCompare) ---

def lua_quote(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def lua_key(value: int | str) -> str:
    if isinstance(value, int):
        return f"[{value}]"
    return f"[{lua_quote(value)}]"


def lua_scalar(value: object) -> str:
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return lua_quote(value)
    raise TypeError(f"Unsupported Lua scalar type: {type(value)!r}")


def format_lua_table(value: object, indent: int = 0) -> str:
    space = "  " * indent
    next_space = "  " * (indent + 1)

    if isinstance(value, dict):
        if not value:
            return "{}"
        lines = ["{"]
        for key, nested in value.items():
            lines.append(f"{next_space}{lua_key(key)} = {format_lua_table(nested, indent + 1)},")
        lines.append(f"{space}}}")
        return "\n".join(lines)

    if isinstance(value, list):
        if not value:
            return "{}"
        lines = ["{"]
        for nested in value:
            lines.append(f"{next_space}{format_lua_table(nested, indent + 1)},")
        lines.append(f"{space}}}")
        return "\n".join(lines)

    return lua_scalar(value)
