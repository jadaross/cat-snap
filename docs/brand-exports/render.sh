#!/usr/bin/env bash
# Regenerate the brand PNGs in this folder from the live SwiftUI source.
#
# The mark is defined once, in the app, at Core/UI/CatWindowMark.swift. This
# script copies that file (plus BrandColors.swift) into a throwaway macOS
# SwiftPM target, renders it through ImageRenderer, and deletes the copies —
# so the PNGs can never drift from what the app actually draws.
#
# Usage:  ./docs/brand-exports/render.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
ui="$repo/CatSnap/CatSnap/Core/UI"
target="$here/render/Sources/MarkRender"

cleanup() { rm -f "$target/CatWindowMark.swift" "$target/BrandColors.swift"; }
trap cleanup EXIT

cp "$ui/BrandColors.swift" "$target/"
# Strip the trailing #Preview block — it needs the app's Xcode context, and the
# renderer has no use for it.
python3 - "$ui/CatWindowMark.swift" "$target/CatWindowMark.swift" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src).read()
i = text.find('#Preview')
if i != -1:
    text = text[:i].rstrip() + '\n'
open(dst, 'w').write(text)
PY

swift build -c release --package-path "$here/render"
"$here/render/.build/release/MarkRender" "$here"

echo
echo "Done. PNGs written to docs/brand-exports/"
