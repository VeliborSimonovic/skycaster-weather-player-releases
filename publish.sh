#!/usr/bin/env bash
# Publish a Skycaster Weather Player build.
#
#   ./publish.sh drop/Skycaster-Weather-Player-win-x64.zip 1.0.0
#
# Creates the GitHub release tagged v<version> and uploads the portable zip.
# Afterwards it is live at:
#   https://downloads.skycaster.tv/weather-player/windows/latest
#
# The app has no auto-updater, so no latest.yml is generated — new versions are
# a manual re-download from the page.
#
# Auth: `gh auth login`, or export GH_TOKEN=<classic PAT with repo scope>.

set -euo pipefail

OWNER=VeliborSimonovic
REPO=skycaster-weather-player-releases

PKG=${1:-}
VERSION=${2:-}

if [[ -z $PKG || -z $VERSION ]]; then
  echo "usage: ./publish.sh <path-to-.zip> <version>   e.g. ./publish.sh drop/Skycaster-Weather-Player-win-x64.zip 1.0.0" >&2
  exit 1
fi
[[ -f $PKG ]] || { echo "no such file: $PKG" >&2; exit 1; }

VERSION=${VERSION#v}
TAG="v$VERSION"
NAME=$(basename "$PKG")
SIZE=$(wc -c < "$PKG" | tr -d ' ')

echo "→ $NAME  ($((SIZE / 1048576)) MB)"
echo "→ tag $TAG"

if command -v gh >/dev/null 2>&1; then
  gh release create "$TAG" "$PKG" \
    --repo "$OWNER/$REPO" \
    --title "Skycaster Weather Player $VERSION" \
    --notes "Portable Windows build of Skycaster Weather Player $VERSION."
else
  : "${GH_TOKEN:?gh CLI not found — export GH_TOKEN=<PAT with repo scope> instead}"
  API=https://api.github.com
  UP=https://uploads.github.com

  echo "→ creating release via API"
  REL=$(curl -sS -X POST "$API/repos/$OWNER/$REPO/releases" \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -d "$(printf '{"tag_name":"%s","name":"Skycaster Weather Player %s","body":"Portable Windows build of Skycaster Weather Player %s."}' "$TAG" "$VERSION" "$VERSION")")

  ID=$(echo "$REL" | sed -n 's/.*"id": *\([0-9]*\).*/\1/p' | head -1)
  [[ -n $ID ]] || { echo "release create failed:"; echo "$REL"; exit 1; }

  echo "→ uploading $NAME"
  curl -sS -X POST "$UP/repos/$OWNER/$REPO/releases/$ID/assets?name=$NAME" \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @"$PKG" -o /dev/null
fi

echo
echo "done — https://downloads.skycaster.tv/weather-player"
echo "direct: https://downloads.skycaster.tv/weather-player/windows/latest"
echo
echo "NOTE: the download page stays in 'Not available yet' mode until you set"
echo "      released: true for weather-player in workers/downloads/worker.js"
echo "      and redeploy (npx wrangler deploy)."
