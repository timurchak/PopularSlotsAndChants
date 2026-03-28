#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"

SOURCE="$(cd "$(dirname "$0")" && pwd)"
RELEASE_ROOT="$SOURCE/Release"
STAGING_ROOT="$RELEASE_ROOT/staging"
ADDON_NAME="PopularSlotsAndChants"
ADDON_ROOT="$STAGING_ROOT/$ADDON_NAME"

GENERATOR="$SOURCE/scripts/generate_lua.py"
DATA_LUA="$SOURCE/PopularSlotsAndChants_Data.lua"
TOC_PATH="$SOURCE/PopularSlotsAndChants.toc"

if [[ ! -f "$TOC_PATH" ]]; then
  echo "Error: TOC file not found: $TOC_PATH" >&2; exit 1
fi
if [[ ! -f "$GENERATOR" ]]; then
  echo "Error: Generator script not found: $GENERATOR" >&2; exit 1
fi

echo "Generating Archon data Lua file..."
python3 "$GENERATOR"
if [[ ! -f "$DATA_LUA" ]]; then
  echo "Error: Generated data Lua not found: $DATA_LUA" >&2; exit 1
fi

if [[ -z "$VERSION" ]]; then
  VERSION=$(sed -n 's/^## Version:[[:space:]]*//p' "$TOC_PATH" | tr -d '[:space:]')
  VERSION="${VERSION:-dev}"
fi

rm -rf "$RELEASE_ROOT"
mkdir -p "$ADDON_ROOT"

FILES=(
  PopularSlotsAndChants.toc
  PopularSlotsAndChants.lua
  PopularSlotsAndChants_Localization.lua
  PopularSlotsAndChants_Data.lua
  PopularSlotsAndChants_UI.lua
)

for file in "${FILES[@]}"; do
  cp "$SOURCE/$file" "$ADDON_ROOT/$file"
done

cp -r "$SOURCE/Locales" "$ADDON_ROOT/Locales"

ZIP_NAME="${ADDON_NAME}-${VERSION}.zip"
ZIP_PATH="$RELEASE_ROOT/$ZIP_NAME"
(cd "$STAGING_ROOT" && zip -r "$ZIP_PATH" "$ADDON_NAME")

echo "Created release archive: $ZIP_PATH"
