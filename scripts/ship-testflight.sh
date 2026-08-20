#!/usr/bin/env bash
#
# Bump the build number, archive, sign for distribution, and upload to
# TestFlight. Everything here runs headless — the Xcode GUI is not needed.
#
# Usage:  ./scripts/ship-testflight.sh  [--dry-run]
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJ="$REPO_ROOT/CatSnap/CatSnap.xcodeproj"
PBX="$PROJ/project.pbxproj"
XCCONFIG="$REPO_ROOT/CatSnap/CatSnap/CatSnap.xcconfig"
TEAM_ID="DFFRB59G23"
WORK="${TMPDIR:-/tmp}/catsnap-ship-$$"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
fail() { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }
ok()   { printf '\033[32m✓ %s\033[0m\n' "$1"; }

# ── preflight ─────────────────────────────────────────────────────────────
[[ -f "$XCCONFIG" ]] || fail "CatSnap.xcconfig missing — Supabase keys won't be baked in."
grep -q '^SENTRY_DSN' "$XCCONFIG" || printf '\033[33m⚠ SENTRY_DSN not set — this build will have no crash reporting.\033[0m\n'

# A dry run must never block on input, so only prompt for a real ship.
if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
  printf '\033[33m⚠ Working tree is dirty. You are about to ship uncommitted changes.\033[0m\n'
  git -C "$REPO_ROOT" status --short
  if ! $DRY_RUN; then
    read -r -p "  Continue anyway? [y/N] " reply
    [[ "$reply" =~ ^[Yy] ]] || exit 1
  fi
fi

# ── bump build number ─────────────────────────────────────────────────────
CURRENT=$(grep -m1 -oE 'CURRENT_PROJECT_VERSION = [0-9]+' "$PBX" | grep -oE '[0-9]+')
[[ -n "$CURRENT" ]] || fail "Could not read CURRENT_PROJECT_VERSION from the project."
NEXT=$((CURRENT + 1))
MARKETING=$(grep -m1 -oE 'MARKETING_VERSION = [0-9.]+' "$PBX" | grep -oE '[0-9.]+')

bold "CatSnap $MARKETING — build $CURRENT → $NEXT"

if $DRY_RUN; then
  echo "(dry run: no changes written, nothing uploaded)"
  exit 0
fi

# Apple rejects a build number that has already been used, so this must
# increment on every upload.
LC_ALL=C sed -i '' "s/CURRENT_PROJECT_VERSION = ${CURRENT};/CURRENT_PROJECT_VERSION = ${NEXT};/g" "$PBX"
ok "build number bumped to $NEXT"

mkdir -p "$WORK"
# Keep the work dir when something fails: the fail() messages below point at
# logs inside it, and wiping them unconditionally leaves nothing to diagnose.
trap '[[ $? -eq 0 ]] && rm -rf "$WORK" || printf "\033[33m  logs kept: %s\033[0m\n" "$WORK"' EXIT

# ── archive ───────────────────────────────────────────────────────────────
bold "Archiving…"
archive_once() {
  rm -rf "$WORK/CatSnap.xcarchive"
  xcodebuild -project "$PROJ" -scheme CatSnap -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$WORK/CatSnap.xcarchive" \
    -allowProvisioningUpdates archive > "$WORK/archive.log" 2>&1
}

# codesign intermittently returns errSecInternalComponent on a framework even
# with an unlocked keychain and a reachable private key. It signs fine on a
# second pass, so retry once rather than burning the build number we just
# bumped — Apple will not let us reuse it.
if ! archive_once; then
  if grep -q "errSecInternalComponent" "$WORK/archive.log"; then
    printf '\033[33m⚠ transient codesign failure — retrying once\033[0m\n'
    archive_once || {
      grep -E "error:|errSec" "$WORK/archive.log" | sort -u | head
      fail "archive failed twice — full log: $WORK/archive.log"
    }
  else
    grep -E "error:" "$WORK/archive.log" | sort -u | head
    fail "archive failed — full log: $WORK/archive.log"
  fi
fi
ok "archived"

# Fail loudly if the runtime config did not make it into the binary. A build
# that ships with an empty SUPABASE_URL looks fine until it is launched.
APP_PLIST="$WORK/CatSnap.xcarchive/Products/Applications/CatSnap.app/Info.plist"
for key in SUPABASE_URL SUPABASE_ANON_KEY; do
  value=$(/usr/libexec/PlistBuddy -c "Print :$key" "$APP_PLIST" 2>/dev/null || true)
  [[ -n "$value" ]] || fail "$key is empty in the archived binary — check CatSnap.xcconfig."
done
ok "runtime config baked in"

# ── upload ────────────────────────────────────────────────────────────────
cat > "$WORK/opts.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>app-store-connect</string>
	<key>destination</key><string>upload</string>
	<key>teamID</key><string>$TEAM_ID</string>
	<key>signingStyle</key><string>automatic</string>
	<key>uploadSymbols</key><true/>
	<key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
PLIST

bold "Uploading to App Store Connect…"
xcodebuild -exportArchive -archivePath "$WORK/CatSnap.xcarchive" \
  -exportOptionsPlist "$WORK/opts.plist" -exportPath "$WORK/out" \
  -allowProvisioningUpdates > "$WORK/upload.log" 2>&1 \
  || { grep -E "error:" "$WORK/upload.log" | sort -u | head; fail "upload failed — full log: $WORK/upload.log"; }

grep -q "Upload succeeded" "$WORK/upload.log" || fail "upload did not report success — see $WORK/upload.log"
ok "uploaded build $NEXT"

printf '\n'
bold "Done. Build $MARKETING ($NEXT) is processing."
echo "  Processing takes 5–15 min, then it auto-distributes to 'Internal Testers'."
echo "  https://appstoreconnect.apple.com/apps/6802691867/testflight/ios"
printf '\n'
echo "  Commit the build bump:"
echo "    git commit -am 'Bump build to $NEXT'"
