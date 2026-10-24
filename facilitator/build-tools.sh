#!/usr/bin/env bash
# Builds every binary attendees need, for macOS and Linux (amd64 + arm64; Windows
# users run the Linux build inside WSL2), into dist/<os>-<arch>/ and one tarball
# per platform. piped and the plugins are built from pipe-cd/pipecd master.
#
#   ./facilitator/build-tools.sh            build only
#   ./facilitator/build-tools.sh --release  also publish the tarballs as GitHub release $TOOLS_RELEASE
set -euo pipefail
source "$(dirname "$0")/../scripts/env.sh"

DIST="$REPO_DIR/dist"
SRC="$WORKSHOP_HOME/pipecd-src"
KUBECTL_VERSION="${KUBECTL_VERSION:-$(curl -fsSL https://dl.k8s.io/release/stable.txt)}"
platforms=(darwin-arm64 darwin-amd64 linux-amd64 linux-arm64)

command -v go >/dev/null || { echo "needs Go 1.26+"; exit 1; }
if [ -d "$SRC/.git" ]; then
  git -C "$SRC" fetch -q --depth 1 origin "$PIPECD_REF" && git -C "$SRC" checkout -q FETCH_HEAD
else
  git clone -q --depth 1 --branch "$PIPECD_REF" https://github.com/pipe-cd/pipecd.git "$SRC"
fi
commit=$(git -C "$SRC" log -1 --format='%h %cd' --date=short)
echo "==> pipe-cd/pipecd $PIPECD_REF at $commit"

rm -rf "$DIST" && mkdir -p "$DIST"
for p in "${platforms[@]}"; do
  goos=${p%-*}; goarch=${p#*-}; out="$DIST/$p"; mkdir -p "$out"
  echo "==> $p"
  (cd "$SRC" && CGO_ENABLED=0 GOOS=$goos GOARCH=$goarch go build -trimpath -ldflags '-s -w' -o "$out/piped" ./cmd/pipedv1)
  for plugin in kubernetes_multicluster wait; do
    (cd "$SRC/pkg/app/pipedv1/plugin/$plugin" && CGO_ENABLED=0 GOOS=$goos GOARCH=$goarch go build -trimpath -ldflags '-s -w' -o "$out/$plugin" .)
  done
  curl -fsSL -o "$out/kind" "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-${goos}-${goarch}"
  curl -fsSL -o "$out/kubectl" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${goos}/${goarch}/kubectl"
  curl -fsSL -o "$out/pipectl" \
    "https://github.com/pipe-cd/pipecd/releases/download/${PIPECTL_VERSION}/pipectl_${PIPECTL_VERSION}_${goos}_${goarch}"
  chmod +x "$out"/*
  tar -czf "$DIST/workshop-tools-$p.tar.gz" -C "$DIST" "$p"
done

cat > "$DIST/VERSIONS.txt" <<EOF
piped v1 + plugins: pipe-cd/pipecd $PIPECD_REF at $commit
pipectl: $PIPECTL_VERSION
kind: $KIND_VERSION
kubectl: $KUBECTL_VERSION
EOF
cat "$DIST/VERSIONS.txt"

if [ "${1:-}" = "--release" ]; then
  gh release create "$TOOLS_RELEASE" --repo "$UPSTREAM_REPO" \
    --title "Workshop tools ($commit)" --notes-file "$DIST/VERSIONS.txt" \
    "$DIST"/workshop-tools-*.tar.gz
fi
