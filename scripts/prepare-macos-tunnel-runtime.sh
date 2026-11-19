#!/usr/bin/env bash
set -euo pipefail

destination=${1:?Expected the Tauri tunnel resources directory}
version=v0.0.14
# Stage both distributions if invoked outside the release workflow without a target.
case "${NEXUS_MACOS_TARGET:-${TAURI_ENV_TARGET_TRIPLE:-universal-apple-darwin}}" in
  aarch64-apple-darwin) architectures=(arm64) ;;
  x86_64-apple-darwin) architectures=(amd64) ;;
  universal-apple-darwin) architectures=(arm64 amd64) ;;
  *) echo "Unsupported macOS tunnel target" >&2; exit 1 ;;
esac

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for arch in "${architectures[@]}"; do
  case "$arch" in
    arm64) sha=c52bd95f8018b7b2903bebb45a47a1695b2c6e146b0672e2b11c38461ce729c1 ;;
    amd64) sha=9edcf0beebf257a765c32146d906ff2abe9a2a11013e222727593d863f1414fa ;;
  esac
  asset="tunnel-client-runtime-cloudflared-$version-darwin-$arch"
  curl --fail --silent --show-error --location --retry 3 \
    "https://github.com/openai/tunnel-client/releases/download/$version/$asset.zip" -o "$tmp/$asset.zip"
  (cd "$tmp" && printf '%s  %s\n' "$sha" "$asset.zip" | shasum -a 256 --check)
  unzip -q "$tmp/$asset.zip" -d "$tmp/$arch"
  target="$destination/darwin-$arch"
  mkdir -p "$target"
  install -m 755 "$tmp/$arch/tunnel-client-runtime-cloudflared" "$tmp/$arch/cloudflared" "$target/"
  install -m 644 "$tmp/$arch/cloudflared-manifest.json" "$tmp/$arch/LICENSE" "$tmp/$arch/NOTICE" \
    "$tmp/$arch/$asset-licenses.txt" "$tmp/$arch/$asset.spdx.json" "$target/"
done
