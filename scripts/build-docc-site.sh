#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_NAME="${REPOSITORY_NAME:-2026TechMap_tutorial}"
OUTPUT_PATH="${OUTPUT_PATH:-/private/tmp/HandJutsuDocC}"
DOCC="${DOCC:-/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/docc}"

"$DOCC" convert docs/HandJutsu.docc \
  --fallback-display-name "Hand Jutsu" \
  --fallback-bundle-identifier "com.siu.HandJutsu.docs" \
  --fallback-bundle-version "1" \
  --hosting-base-path "/${REPOSITORY_NAME}" \
  --warnings-as-errors \
  --output-path "$OUTPUT_PATH"

node scripts/normalize-docc-section-links.mjs "$OUTPUT_PATH"

touch "$OUTPUT_PATH/.nojekyll"

echo "Built DocC site at ${OUTPUT_PATH}"
