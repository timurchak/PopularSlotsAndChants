# Popular Slots & Chants

A World of Warcraft addon that displays popular gear, enchants, gems, and consumables from [Archon.gg](https://www.archon.gg) Mythic+ data — right inside the game.

## Features

- **Gear** — Top 3 most popular items per equipment slot
- **Enchants** — Top 3 enchants per slot (weapon, rings, head, shoulders, chest, legs, feet)
- **Gems** — Top 3 epic gems and regular gems
- **Consumables** — Most popular flask, potions, and weapon buffs
- **All 40 specs** supported with auto-detection of your current specialization
- **Difficulty selector** — View items at Veteran, Champion, Hero, or Myth upgrade levels
- **Shift+Click** to link any item in chat
- **Localization** — English and Russian

## Usage

Type `/psc` or `/popularslots` in chat to open the window.

## Data Source

All data is sourced from [Archon.gg](https://www.archon.gg) Mythic+ overview pages. Archon aggregates thousands of top parses from Warcraft Logs to determine the most popular gear choices for each specialization.

Data is updated with each addon release via Python scripts that parse Archon's public pages.

## Installation

Download the latest release from the [Releases](../../releases) page and extract to:
```
World of Warcraft/_retail_/Interface/AddOns/PopularSlotsAndChants
```

## Building from Source

```bash
# Generate data for all 40 specs (~2 minutes)
python3 scripts/generate_lua.py

# Install locally (macOS)
python3 scripts/install.py

# Build release ZIP
./build-release.sh 0.1.0
```
## TODO
- [X] Add addon icon
- [ ] Add minimup button
- [ ] Think about auto update every day/week
- [ ] Add talents
- [ ] Add export stats to BGC
- [ ] Add all for raid
