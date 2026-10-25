#!/usr/bin/env bash
# Builds piped + the two plugins for macOS and Linux and publishes them as the
# "tools" release that scripts/setup.sh downloads.
#
# Built from commit 5b41282 (4 Aug 2026) because that's the newest commit with a
# published control plane image (ghcr.io/pipe-cd/pipecd:v0.57.0-73-g5b41282), and
# piped must match the control plane. Newer piped needs a server change (#6727)
# that no published image has yet. The released piped v1 (Oct 2025) is too old
# for the multicluster plan preview.
set -euo pipefail

COMMIT=5b4128201
src=/tmp/pipecd-src
[ -d $src ] || git clone -q https://github.com/pipe-cd/pipecd.git $src
git -C $src checkout -q $COMMIT 2>/dev/null || { git -C $src fetch -q origin && git -C $src checkout -q $COMMIT; }
out=/tmp/workshop-tools && rm -rf $out && mkdir -p $out

for p in darwin-arm64 darwin-amd64 linux-amd64 linux-arm64; do
  echo "building $p"
  export GOOS=${p%-*} GOARCH=${p#*-} CGO_ENABLED=0
  mkdir -p $out/$p
  (cd $src && go build -o $out/$p/piped ./cmd/pipedv1)
  (cd $src && go build -o $out/$p/pipectl ./cmd/pipectl)
  (cd $src/pkg/app/pipedv1/plugin/kubernetes_multicluster && go build -o $out/$p/kubernetes_multicluster .)
  (cd $src/pkg/app/pipedv1/plugin/wait && go build -o $out/$p/wait .)
  tar -czf $out/workshop-tools-$p.tar.gz -C $out/$p .
done

gh release create tools $out/workshop-tools-*.tar.gz \
  --repo mohammedfirdouss/pipecd-multicluster-workshop \
  --title "Workshop tools" --notes "piped v1, pipectl and plugins built from pipe-cd/pipecd $(git -C $src log -1 --format='%h (%cd)' --date=short). Matches control plane image ghcr.io/pipe-cd/pipecd:v0.57.0-73-g5b41282."
