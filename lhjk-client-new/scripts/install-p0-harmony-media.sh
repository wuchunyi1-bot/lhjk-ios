#!/bin/bash
# Install P0 visual assets into Harmony media folders.
# Run in macOS Terminal (needs write access to ~/lhjk):
#   bash /Users/chunyi/Desktop/lhjk/lhjk-ios/lhjk-client-new/scripts/install-p0-harmony-media.sh

set -euo pipefail
STAGE="$(cd "$(dirname "$0")" && pwd)/p0-harmony-media"
TARGETS=(
  "/Users/chunyi/lhjk/lhjk-client-clean/entry/src/main/resources/base/media"
  "/Users/chunyi/lhjk/lhjk-harmony/lhjk-client-new/entry/src/main/resources/base/media"
)

if [[ ! -d "$STAGE" ]]; then
  echo "Missing staged assets: $STAGE"
  exit 1
fi

for dest in "${TARGETS[@]}"; do
  if [[ ! -d "$dest" ]]; then
    echo "Skip missing: $dest"
    continue
  fi
  mkdir -p "$dest"
  cp -f "$STAGE"/* "$dest/"
  # Drop quarantine/provenance when possible
  xattr -cr "$dest" 2>/dev/null || true
  echo "Installed -> $dest ($(ls "$STAGE" | wc -l | tr -d ' ') files)"
done

echo "Done. Rebuild the Harmony app in DevEco."
