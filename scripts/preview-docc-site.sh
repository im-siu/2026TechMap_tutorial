#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_NAME="${REPOSITORY_NAME:-2026TechMap_tutorial}"
OUTPUT_PATH="${OUTPUT_PATH:-/private/tmp/HandJutsuDocC}"
PORT="${PORT:-8124}"

"$(dirname "$0")/build-docc-site.sh"

PREVIEW_ROOT="$(mktemp -d /private/tmp/HandJutsuDocCPreview.XXXXXX)"
ln -s "$OUTPUT_PATH" "$PREVIEW_ROOT/$REPOSITORY_NAME"

cat <<EOF
Serving DocC preview at http://127.0.0.1:${PORT}/${REPOSITORY_NAME}/documentation/handjutsu/
Getting Started: http://127.0.0.1:${PORT}/${REPOSITORY_NAME}/documentation/hand-jutsu/gettingstarted/
Tutorials: http://127.0.0.1:${PORT}/${REPOSITORY_NAME}/tutorials/hand-jutsu/
Tutorial 2: http://127.0.0.1:${PORT}/${REPOSITORY_NAME}/tutorials/hand-jutsu/02-creating-immersive-space/
Tutorial 2 Immersive View section: http://127.0.0.1:${PORT}/${REPOSITORY_NAME}/tutorials/hand-jutsu/02-creating-immersive-space/#Immersive-View-%EC%A4%80%EB%B9%84%ED%95%98%EA%B8%B0
EOF

python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$PREVIEW_ROOT"
