#!/usr/bin/env bash
# Installs kind, kubectl, pipectl, piped v1 and the two plugins into ~/.pipecd-workshop.
#
#   ./scripts/install-tools.sh /path/to/bundle   from the USB offline bundle (no internet)
#   ./scripts/install-tools.sh                   downloads ready-built binaries
#   BUILD_FROM_SOURCE=1 ./scripts/install-tools.sh   builds piped from pipe-cd/pipecd master (needs Go)
#
# piped v1 comes from master because the latest released pipedv1 build
# (v1.0.0-alpha1, Oct 2025) predates the multicluster plugin's plan preview.
set -euo pipefail
source "$(dirname "$0")/env.sh"

BUNDLE_DIR="${1:-}"
platform="${os}-${arch}"
case "$platform" in
  darwin-amd64|darwin-arm64|linux-amd64|linux-arm64) ;;
  *) echo "Unsupported platform: $platform. On Windows, run this inside WSL2 (Ubuntu)."; exit 1 ;;
esac

want=(kind kubectl pipectl piped kubernetes_multicluster wait)

install_from_dir() {  # $1 = dir holding all six binaries
  for b in "${want[@]}"; do
    case "$b" in
      kubernetes_multicluster|wait) install -m 0755 "$1/$b" "$PLUGINS_DIR/$b" ;;
      *) install -m 0755 "$1/$b" "$BIN_DIR/$b" ;;
    esac
  done
}

if [ -n "$BUNDLE_DIR" ]; then
  echo "==> installing from offline bundle: $BUNDLE_DIR/bin/$platform"
  install_from_dir "$BUNDLE_DIR/bin/$platform"

elif [ -z "${BUILD_FROM_SOURCE:-}" ]; then
  echo "==> downloading ready-built binaries ($UPSTREAM_REPO release $TOOLS_RELEASE, $platform)"
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/tools.tar.gz" \
    "https://github.com/${UPSTREAM_REPO}/releases/download/${TOOLS_RELEASE}/workshop-tools-${platform}.tar.gz"
  tar -xzf "$tmp/tools.tar.gz" -C "$tmp"
  install_from_dir "$tmp/$platform"
  rm -rf "$tmp"

else
  command -v go >/dev/null || { echo "BUILD_FROM_SOURCE needs Go 1.26+"; exit 1; }
  [ -x "$BIN_DIR/kind" ] || curl -fsSL -o "$BIN_DIR/kind" "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-${os}-${arch}"
  [ -x "$BIN_DIR/kubectl" ] || curl -fsSL -o "$BIN_DIR/kubectl" "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/${os}/${arch}/kubectl"
  [ -x "$BIN_DIR/pipectl" ] || curl -fsSL -o "$BIN_DIR/pipectl" \
    "https://github.com/pipe-cd/pipecd/releases/download/${PIPECTL_VERSION}/pipectl_${PIPECTL_VERSION}_${os}_${arch}"
  chmod +x "$BIN_DIR/kind" "$BIN_DIR/kubectl" "$BIN_DIR/pipectl"
  [ -d "$PIPECD_SRC/.git" ] || git clone -q --depth 1 --branch "$PIPECD_REF" https://github.com/pipe-cd/pipecd.git "$PIPECD_SRC"
  echo "==> building piped v1 from $(git -C "$PIPECD_SRC" log -1 --format='%h %cd' --date=short)"
  (cd "$PIPECD_SRC" && CGO_ENABLED=0 go build -o "$BIN_DIR/piped" ./cmd/pipedv1)
  make -C "$PIPECD_SRC" build/plugin PLUGINS=kubernetes_multicluster,wait PLUGINS_BIN_DIR="$PLUGINS_DIR"
fi

echo "Tools ready:"
for b in kind kubectl pipectl piped; do printf '  %-8s %s\n' "$b" "$BIN_DIR/$b"; done
echo "  plugins  $PLUGINS_DIR"
echo "Add them to your PATH for this terminal:  export PATH=\"$BIN_DIR:\$PATH\""
