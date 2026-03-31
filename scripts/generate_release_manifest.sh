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

python3 - "$BROWSER_NAME" "$VERSION" "$CHANNEL" "$ASSET_URL" "$SHA256" "$NOW_UTC" "$OUT" <<'PY'
import json
import sys

browser, version, channel, asset_url, sha256, released_at, out = sys.argv[1:]
payload = {
    "schema": "buglogin.browser.release.v1",
    "browser": browser,
    "channel": channel,
    "version": version,
    "platform": "win-x64",
    "artifact": {
        "url": asset_url,
        "sha256": sha256,
    },
    "released_at": released_at,
}
with open(out, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

echo "manifest written to $OUT"
