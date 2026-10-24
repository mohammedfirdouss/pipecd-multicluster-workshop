#!/usr/bin/env bash
# Builds the USB offline bundle so laptops don't depend on venue Wi-Fi:
#   bin/<os>-<arch>/      every binary (from facilitator/build-tools.sh)
#   images/kind-node.tar  the Kubernetes node image kind uses
#   images/control-plane.tar, images/app.tar
#   control-plane.yaml    the quickstart manifest, pinned to $CONTROL_PLANE_VERSION
#
# Run after build-tools.sh, on a machine where `kind create cluster` has worked once.
# Usage: ./facilitator/make-offline-bundle.sh /Volumes/USB/pipecd-bundle
set -euo pipefail
source "$(dirname "$0")/../scripts/env.sh"

OUT="${1:?usage: $0 <output dir>}"
DIST="$REPO_DIR/dist"
[ -d "$DIST" ] || { echo "Run facilitator/build-tools.sh first"; exit 1; }
mkdir -p "$OUT/bin" "$OUT/images"

echo "==> binaries"
for p in "$DIST"/*/; do cp -R "$p" "$OUT/bin/"; done
cp "$DIST/VERSIONS.txt" "$OUT/"

echo "==> control plane manifest ($CONTROL_PLANE_VERSION)"
curl -fsSL https://raw.githubusercontent.com/pipe-cd/pipecd/master/quickstart/manifests/control-plane.yaml \
  | sed -E "s#ghcr.io/pipe-cd/pipecd:v[0-9.]+#ghcr.io/pipe-cd/pipecd:${CONTROL_PLANE_VERSION}#g" > "$OUT/control-plane.yaml"

# One image set per CPU type (Intel/AMD = amd64, Apple Silicon/ARM = arm64).
# Pull each image for that platform, then save; the next platform's pull replaces the local tag.
save_images() {  # $1 = arch, $2 = output tar, rest = images
  local a=$1 tar=$2; shift 2
  for img in "$@"; do docker pull -q --platform "linux/$a" "$img" >/dev/null; done
  docker save -o "$tar" "$@"
}

node_image=$(docker inspect cluster1-control-plane --format '{{.Config.Image}}' 2>/dev/null) \
  || { echo "Create the clusters once (scripts/up.sh) so the node image is known"; exit 1; }
cp_images=$(grep -E '^[[:space:]]+image:' "$OUT/control-plane.yaml" | awk '{print $2}' | tr -d '"' | sort -u)
app_images="ghcr.io/pipe-cd/helloworld:v0.47.0 ghcr.io/pipe-cd/helloworld:v0.47.1 ghcr.io/pipe-cd/helloworld:v0.47.2"

for a in amd64 arm64; do
  echo "==> images for $a"
  mkdir -p "$OUT/images/$a"
  save_images "$a" "$OUT/images/$a/kind-node.tar" "$node_image"
  # shellcheck disable=SC2086
  save_images "$a" "$OUT/images/$a/control-plane.tar" $cp_images
  # shellcheck disable=SC2086
  save_images "$a" "$OUT/images/$a/app.tar" $app_images
done

# Put this machine's own architecture back so its clusters keep working.
native=$(docker info --format '{{.Architecture}}'); [ "$native" = aarch64 ] && native=arm64; [ "$native" = x86_64 ] && native=amd64
# shellcheck disable=SC2086
for img in "$node_image" $cp_images $app_images; do docker pull -q --platform "linux/$native" "$img" >/dev/null; done

cp -R "$REPO_DIR/scripts" "$OUT/scripts"
du -sh "$OUT"
echo "Bundle ready: copy $OUT to each USB stick."
