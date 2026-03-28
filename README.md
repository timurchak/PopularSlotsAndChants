# Popular Slots & Chants

WoW Retail addon — shows popular gear, enchants, gems, consumables, talents, and stat priorities from [Archon.gg](https://www.archon.gg) data for Mythic+ and Raid.

> CurseForge description: [CURSE.md](CURSE.md)

## Architecture

```
PopularSlotsAndChants.lua          -- Entry point, saved variables, slash commands
PopularSlotsAndChants_Data.lua     -- Generated Archon data (all 40 specs, M+ & Raid)
Core/
  Localization.lua                 -- Locale framework (L table)
  MinimapButton.lua                -- LibDBIcon minimap launcher
  UI/
    Constants.lua                  -- Tabs, upgrade tracks, slot orders, colors, shared state
    Pools.lua                      -- Row/header pools, item/spell row setup, helpers
    PopulateTabs.lua               -- Gear, enchants, gems, consumables tab content
    Talents.lua                    -- Talent builds tab, copy popup
    Stats.lua                      -- Stat priority tab, BGC export
    MainFrame.lua                  -- Main window, scroll, dropdowns, mode/tab switching
Media/
  icon.tga                        -- Addon icon
Locales/
  enUS.lua, ruRU.lua              -- Translations
```

## Data Generation

All data is scraped from Archon.gg public pages at build time. Scripts live in `scripts/`:

| Script | Purpose |
|--------|---------|
| `archon_common.py` | Shared utilities: URL builder, markup parsers, Lua formatter |
| `fetch_archon_gear.py` | Parse gear slot breakdowns |
| `fetch_archon_enchants.py` | Parse enchants and gems |
| `fetch_archon_consumables.py` | Parse consumables (items + class spell buffs) |
| `fetch_archon_talents.py` | Parse talent builds with export codes |
| `fetch_archon_stats.py` | Parse stat priorities |
| `generate_lua.py` | Orchestrator: fetches all data, writes `PopularSlotsAndChants_Data.lua` |
| `install.py` | Copy addon to local WoW AddOns directory |

### Running generators

```bash
# Generate data for all specs, both modes (~4 minutes)
python3 scripts/generate_lua.py

# Single spec for testing
python3 scripts/generate_lua.py --spec-filter shaman/elemental

# M+ only
python3 scripts/generate_lua.py --mode mythicplus

# Install locally (macOS)
python3 scripts/install.py
```

## Data Structure

Data is nested under game mode keys:

```lua
ns.ArchonData.specs["shaman/restoration"] = {
  specID = 264,
  mythicplus = { gear = {...}, enchants = {...}, gems = {...}, consumables = {...}, talents = {...}, stats = {...} },
  raid       = { gear = {...}, enchants = {...}, ... },
}
```

Consumable entries may include `isSpell = true` for class ability weapon buffs (e.g. Windfury Weapon, Earthliving Weapon) which use `C_Spell.GetSpellInfo` instead of `GetItemInfo`.

## Build & Release

### Local install

```bash
python3 scripts/install.py
```

### Release build

```bash
./build-release.sh 0.4.0
```

### CI

GitHub Actions (`.github/workflows/release.yml`) triggers on `v*` tags:

1. Runs `generate_lua.py` to fetch live Archon data
2. Commits generated data and moves the tag
3. Packages via BigWigsMods/packager
4. Publishes to GitHub Releases and CurseForge

## Slash Commands

| Command | Action |
|---------|--------|
| `/psc` | Toggle main window |
| `/popularslots` | Toggle main window |
