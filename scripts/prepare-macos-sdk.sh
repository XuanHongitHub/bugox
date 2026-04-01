#!/usr/bin/env bash
set -euo pipefail

SDK_URL="${BUGLOGIN_MACOS_SDK_URL:-}"
SDK_SHA256="${BUGLOGIN_MACOS_SDK_SHA256:-}"
SDK_AUTH_HEADER="${BUGLOGIN_MACOS_SDK_AUTH_HEADER:-}"
MOZBUILD_DIR="${MOZBUILD_DIR:-$HOME/.mozbuild}"

if [[ -z "${SDK_URL}" ]]; then
  echo "No BUGLOGIN_MACOS_SDK_URL provided; falling back to upstream SDK fetch."
  exit 0
fi

mkdir -p "${MOZBUILD_DIR}"
tmpdir="$(mktemp -d)"
archive_path="${tmpdir}/macos-sdk-archive"

cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

echo "Downloading macOS SDK from configured mirror..."
curl_args=(--fail --location --retry 5 --retry-delay 3 --retry-all-errors "${SDK_URL}" -o "${archive_path}")
if [[ -n "${SDK_AUTH_HEADER}" ]]; then
  curl_args=(--header "${SDK_AUTH_HEADER}" "${curl_args[@]}")
fi
curl "${curl_args[@]}"

if [[ -n "${SDK_SHA256}" ]]; then
  echo "${SDK_SHA256}  ${archive_path}" | sha256sum -c -
fi

unpack_dir="${tmpdir}/unpacked"
mkdir -p "${unpack_dir}"

case "${SDK_URL}" in
  *.tar.xz|*.txz)
    tar -xJf "${archive_path}" -C "${unpack_dir}"
    ;;
  *.tar.gz|*.tgz)
    tar -xzf "${archive_path}" -C "${unpack_dir}"
    ;;
  *.zip)
    unzip -q "${archive_path}" -d "${unpack_dir}"
    ;;
  *)
    if tar -xf "${archive_path}" -C "${unpack_dir}" >/dev/null 2>&1; then
      :
    elif unzip -q "${archive_path}" -d "${unpack_dir}" >/dev/null 2>&1; then
      :
    else
      echo "Unsupported SDK archive format from URL: ${SDK_URL}" >&2
      exit 1
    fi
    ;;
esac

sdk_dir="$(find "${unpack_dir}" -maxdepth 6 -type d -name 'MacOSX*.sdk' | head -n 1 || true)"
if [[ -z "${sdk_dir}" ]]; then
  echo "Could not find a MacOSX*.sdk directory inside downloaded archive." >&2
  exit 1
fi

target_sdk_path="${MOZBUILD_DIR}/$(basename "${sdk_dir}")"
rm -rf "${target_sdk_path}"
cp -a "${sdk_dir}" "${target_sdk_path}"

echo "Prepared macOS SDK at ${target_sdk_path}"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "BUGOX_MACOS_SDK_PATH=${target_sdk_path}" >> "${GITHUB_ENV}"
else
  echo "export BUGOX_MACOS_SDK_PATH=${target_sdk_path}"
fi
