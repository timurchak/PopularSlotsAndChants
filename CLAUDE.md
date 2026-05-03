# PopularSlotsAndChants

WoW Retail addon showing top-tier gear, enchants, gems, consumables, talents, and stat priorities for all 40 specs. Data scraped from Archon.gg at build time.

## Tech Stack

- **Lua 5.1** (WoW runtime) — no Lua 5.2+ features (no `goto`, no `table.unpack` without compat)
- **WoW API** — Blizzard's frame/widget system, C_ namespaced APIs ("/Users/timurudychak/works/WoW/wow-ui-source")
- **Python 3** — data generation pipeline (scripts/)

## Code Conventions

- **2-space indentation, spaces** (not tabs)
- **PascalCase** for modules: `MainFrame`, `PopulateTabs`
- **camelCase** for functions/variables: `buildRows`, `selectedSpecID`
- **UPPER_CASE** for constants: `SLOT_ORDER`, `COLORS`
- **Namespace pattern**: files use `local addonName, ns = ...` and attach to `ns` (e.g., `ns.UI`, `ns.Data`)
- **Prefix unused args with `_`**: `_self`, `_event`
- **Access WoW globals via `_G.`**: `_G.CreateFrame`, `_G.GetItemInfo` — keeps dependency on globals explicit

## Linting

```bash
# Check (CI-safe) — always use the project script, not bare tool commands
bash scripts/lint.sh

# Auto-format + check
bash scripts/lint.sh --fix
```

Luacheck handles semantics (unused vars, undefined globals, shadowing). StyLua handles formatting (line length, spacing, alignment). Both must pass clean before committing.

When adding new WoW API globals, add them to `.luacheckrc` under `read_globals`.

## Data Generation

```bash
# Generate all specs, both modes (~4 minutes)
python3 scripts/generate_lua.py

# Single spec for quick testing
python3 scripts/generate_lua.py --spec-filter shaman/elemental

# Single mode only
python3 scripts/generate_lua.py --mode mythicplus
```

Output: `PopularSlotsAndChants_Data.lua` (~38K lines). This file is generated — do not edit manually.

## Local Install

```bash
python3 scripts/install.py
```

Copies addon to `/Applications/World of Warcraft/_retail_/Interface/AddOns/PopularSlotsAndChants`.

## Release

```bash
./build-release.sh 0.4.0
```

Runs data generation, stages files, creates versioned zip in `Release/`. CI (`.github/workflows/release.yml`) handles CurseForge publishing on tag push.

## Lua Best Practices

- **Localize everything** — `local` variables and functions are faster than globals. Always `local function` unless exporting on a module table.
- **Localize hot-path API calls** — `local pairs = pairs`, `local tinsert = table.insert` at the top of files that use them in loops.
- **Avoid creating tables in tight loops** — reuse tables or build outside the loop when possible. Table creation triggers GC pressure.
- **Prefer `ipairs` for arrays, `pairs` for dictionaries** — never use `pairs` on sequential arrays; iteration order is not guaranteed.
- **String concatenation** — use `table.concat` for building strings in loops. The `..` operator creates a new string each time.
- **No global leaks** — every variable must be `local`. The only intentional globals are WoW API calls via `_G.`.
- **Early returns over deep nesting** — prefer `if not condition then return end` at the top of a function.
- **Avoid magic numbers** — extract constants into `Constants.lua` or a local `UPPER_CASE` variable at the top of the file.
- **Keep functions small** — if a function exceeds ~40 lines, extract helpers.
- **No `table.getn` or `#` on sparse tables** — `#` is only reliable on proper sequences (no nil holes).

## Project Structure

```
PopularSlotsAndChants.lua     — Entry point, saved variables, slash commands
PopularSlotsAndChants_Data.lua — Generated data (all specs, gear, enchants, etc.)
Core/
  Localization.lua            — Locale framework (metatable-based L table)
  MinimapButton.lua           — LibDataBroker/LibDBIcon minimap integration
  UI/
    Constants.lua             — UI config, shared state, color definitions
    MainFrame.lua             — Main window, scroll area, dropdowns, tab/mode switching
    Pools.lua                 — Row/header object pools, item/spell helpers
    PopulateTabs.lua          — Content rendering for gear/enchants/gems/consumables
    Talents.lua               — Talent builds display with export/open buttons
    Stats.lua                 — Stat priority bars with BGC export integration
Locales/
  Localization.xml            — XML manifest for locale loading
  enUS.lua                    — English translations
  ruRU.lua                    — Russian translations
Libs/                         — Vendored libraries (LibStub, LibDBIcon, etc.)
scripts/                      — Python data generation pipeline
  generate_lua.py             — Orchestrator: fetches all data, generates Data file
  archon_common.py            — Shared utilities (URL builder, HTML parsing, Lua formatter)
  fetch_archon_*.py           — Per-category scrapers (gear, enchants, consumables, talents, stats)
  install.py                  — Local install to WoW AddOns directory
  fetch_libs.sh               — Download/update vendored libraries
```

## Key Architecture Notes

- **Object pooling** — `Pools.lua` reuses UI frames (`rowPool`, `headerPool`, `talentRowPool`, `statRowPool`) to avoid frame creation overhead
- **Async item loading** — `GET_ITEM_INFO_RECEIVED` event triggers re-render when item data arrives; pending items tracked in `UI.pendingItems`
- **Tab-based rendering** — Each `UI.Populate*()` function renders its tab content and returns yOffset for layout
- **BetterGearCompare integration** — Stats tab exports weights via `bgc.ImportWeights(profileName, weights)`
- **Generated data is read-only** — `PopularSlotsAndChants_Data.lua` is produced by Python scripts, never edited by hand
