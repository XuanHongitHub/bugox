#!/usr/bin/env bash
set -euo pipefail

BROWSER_NAME="${1:-bugox}"
VERSION="${2:-}"
CHANNEL="${3:-stable}"
ASSET_URL="${4:-}"
SHA256="${5:-}"
OUT="${6:-release-manifest.json}"
PLATFORM="${7:-windows-x64}"
UPDATE_MODE="${8:-optional}"
UPDATE_REQUIRED="${9:-false}"
MIN_SUPPORTED_VERSION="${10:-}"
UPDATE_MESSAGE="${11:-}"

if [[ -z "$VERSION" ]]; then
  echo "usage: $0 <browser_name> <version> [channel] [asset_url] [sha256] [out] [platform] [update_mode] [update_required] [min_supported_version] [update_message]" >&2
  exit 1
fi

NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

python3 - "$BROWSER_NAME" "$VERSION" "$CHANNEL" "$ASSET_URL" "$SHA256" "$NOW_UTC" "$OUT" "$PLATFORM" "$UPDATE_MODE" "$UPDATE_REQUIRED" "$MIN_SUPPORTED_VERSION" "$UPDATE_MESSAGE" <<'PY'
import json
import sys

browser, version, channel, asset_url, sha256, released_at, out, platform, update_mode, update_required, min_supported_version, update_message = sys.argv[1:]
platforms = [
    "windows-x64",
    "windows-arm64",
    "linux-x64",
    "linux-arm64",
    "macos-x64",
    "macos-arm64",
]
downloads = {p: None for p in platforms}
if platform in downloads and asset_url:
    downloads[platform] = asset_url

required = str(update_required).strip().lower() in ("1", "true", "yes")
policy = {
    "mode": update_mode or "optional",
    "required": required,
}
if min_supported_version:
    policy["min_supported_version"] = min_supported_version
if update_message:
    policy["message"] = update_message

payload = {
    "schema": "buglogin.browser.release.v1",
    "browser": browser,
    "channel": channel,
    "version": version,
    "platform": platform,
    "artifact": {
        "url": asset_url,
        "sha256": sha256,
    },
    "downloads": downloads,
    "update_policy": policy,
    "released_at": released_at,
}
with open(out, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

echo "manifest written to $OUT"
