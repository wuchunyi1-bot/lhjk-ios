#!/bin/bash
set -euo pipefail
SRC="/Users/chunyi/lhjk/lhjk-client-clean/entry/src/main/ets"
DST="/Users/chunyi/lhjk/lhjk-harmony/lhjk-client-new/entry/src/main/ets"
FILES=(
  "other/tokens/FdTokens.ets"
  "pages/RootTab.ets"
  "pages/LoginPage.ets"
  "bll/home/HomeModels.ets"
  "pl/home/HomeContent.ets"
)
for f in "${FILES[@]}"; do
  mkdir -p "$(dirname "$DST/$f")"
  cp -f "$SRC/$f" "$DST/$f"
  echo "synced $f"
done
