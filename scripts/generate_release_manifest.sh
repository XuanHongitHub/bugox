#!/usr/bin/env bash
set -euo pipefail

BROWSER_NAME="${1:-bugox}"
VERSION="${2:-}"
CHANNEL="${3:-stable}"
ASSET_URL="${4:-}"
SHA256="${5:-}"
OUT="${6:-release-manifest.json}"

if [[ -z "$VERSION" ]]; then
  echo "usage: $0 <browser_name> <version> [channel] [asset_url] [sha256] [out]" >&2
  exit 1
fi

NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -n \
  --arg browser "$BROWSER_NAME" \
  --arg version "$VERSION" \
  --arg channel "$CHANNEL" \
  --arg asset_url "$ASSET_URL" \
  --arg sha256 "$SHA256" \
  --arg released_at "$NOW_UTC" \
  '{
    schema: "buglogin.browser.release.v1",
    browser: $browser,
    channel: $channel,
    version: $version,
    platform: "win-x64",
    artifact: {
      url: $asset_url,
      sha256: $sha256
    },
    released_at: $released_at
  }' > "$OUT"

echo "manifest written to $OUT"
