#!/usr/bin/env bash
# Publish a Skycaster Weather Player build.
#
#   ./publish.sh drop/Skycaster-Weather-Player-Setup-1.0.0.exe 1.0.0
#
# Generates latest.yml (electron-updater feed), creates the GitHub release
# tagged v<version>, and uploads both assets. Afterwards the installer is live
# at https://downloads.skycaster.tv/weather-player/windows/latest
#
# Auth: `gh auth login`, or export GH_TOKEN=<classic PAT with repo scope>.

set -euo pipefail

OWNER=VeliborSimonovic
REPO=skycaster-weather-player-releases

EXE=${1:-}
VERSION=${2:-}

if [[ -z $EXE || -z $VERSION ]]; then
  echo "usage: ./publish.sh <path-to-.exe> <version>   e.g. ./publish.sh drop/Setup-1.0.0.exe 1.0.0" >&2
  exit 1
fi
[[ -f $EXE ]] || { echo "no such file: $EXE" >&2; exit 1; }

VERSION=${VERSION#v}
TAG="v$VERSION"
NAME=$(basename "$EXE")
SIZE=$(wc -c < "$EXE" | tr -d ' ')
SHA512=$(openssl dgst -sha512 -binary "$EXE" | openssl base64 -A)
DATE=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
YML="$WORK/latest.yml"

# electron-updater feed. `url` is relative, so the updater resolves it against
# its feed base (.../weather-player/) and the worker serves it by asset name.
cat > "$YML" <<EOF
version: $VERSION
files:
  - url: $NAME
    sha512: $SHA512
    size: $SIZE
path: $NAME
sha512: $SHA512
releaseDate: '$DATE'
EOF

echo "→ $NAME  ($(printf '%.1f' "$(echo "$SIZE/1048576" | bc -l)") MB)"
echo "→ tag $TAG"

if command -v gh >/dev/null 2>&1; then
  gh release create "$TAG" "$EXE" "$YML" \
    --repo "$OWNER/$REPO" \
    --title "Skycaster Weather Player $VERSION" \
    --notes "Windows installer for Skycaster Weather Player $VERSION."
else
  : "${GH_TOKEN:?gh CLI not found — export GH_TOKEN=<PAT with repo scope> instead}"
  API=https://api.github.com
  UP=https://uploads.github.com

  echo "→ creating release via API"
  REL=$(curl -sS -X POST "$API/repos/$OWNER/$REPO/releases" \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -d "$(printf '{"tag_name":"%s","name":"Skycaster Weather Player %s","body":"Windows installer for Skycaster Weather Player %s."}' "$TAG" "$VERSION" "$VERSION")")

  ID=$(echo "$REL" | sed -n 's/.*"id": *\([0-9]*\).*/\1/p' | head -1)
  [[ -n $ID ]] || { echo "release create failed:"; echo "$REL"; exit 1; }

  for f in "$EXE" "$YML"; do
    n=$(basename "$f")
    echo "→ uploading $n"
    curl -sS -X POST "$UP/repos/$OWNER/$REPO/releases/$ID/assets?name=$n" \
      -H "Authorization: Bearer $GH_TOKEN" \
      -H "Content-Type: application/octet-stream" \
      --data-binary @"$f" -o /dev/null
  done
fi

echo
echo "done — https://downloads.skycaster.tv/weather-player"
echo "direct: https://downloads.skycaster.tv/weather-player/windows/latest"
