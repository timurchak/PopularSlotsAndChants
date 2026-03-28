#!/usr/bin/env bash
# Fetch external libraries for local development.
# In CI, BigWigsMods/packager handles this via .pkgmeta.
# Requires: svn (brew install subversion) and git.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIBS_DIR="$SCRIPT_DIR/../Libs"

mkdir -p "$LIBS_DIR"

fetch_svn() {
  local name="$1" url="$2"
  local dest="$LIBS_DIR/$name"
  if [[ -d "$dest" ]]; then
    echo "  $name — already exists, skipping"
    return
  fi
  echo "  $name — svn export..."
  svn export --quiet "$url" "$dest"
}

fetch_git() {
  local name="$1" url="$2"
  local dest="$LIBS_DIR/$name"
  if [[ -d "$dest" ]]; then
    echo "  $name — already exists, skipping"
    return
  fi
  echo "  $name — git clone..."
  local tmp
  tmp=$(mktemp -d)
  git clone --quiet --depth 1 "$url" "$tmp/repo"
  rm -rf "$tmp/repo/.git"
  mv "$tmp/repo" "$dest"
  rm -rf "$tmp"
}

echo "Fetching libs into $LIBS_DIR ..."
fetch_svn "LibStub"              "https://repos.curseforge.com/wow/libstub/trunk"
fetch_svn "CallbackHandler-1.0"  "https://repos.curseforge.com/wow/callbackhandler/trunk/CallbackHandler-1.0"
fetch_git "LibDataBroker-1.1"    "https://github.com/tekkub/libdatabroker-1-1.git"
fetch_svn "LibDBIcon-1.0"        "https://repos.wowace.com/wow/libdbicon-1-0/trunk/LibDBIcon-1.0"

echo "Done."
ls "$LIBS_DIR"
