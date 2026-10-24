#!/usr/bin/env bash
# Builds piped + the two plugins from pipe-cd/pipecd master for macOS and Linux,
# and publishes them as the "tools" release that scripts/setup.sh downloads.
# (The latest released piped v1 is from Oct 2025, older than the plan preview feature.)
set -euo pipefail

src=/tmp/pipecd-src
[ -d $src ] || git clone -q --depth 1 https://github.com/pipe-cd/pipecd.git $src
git -C $src pull -q
out=/tmp/workshop-tools && rm -rf $out && mkdir -p $out

for p in darwin-arm64 darwin-amd64 linux-amd64 linux-arm64; do
  echo "building $p"
  export GOOS=${p%-*} GOARCH=${p#*-} CGO_ENABLED=0
  mkdir -p $out/$p
  (cd $src && go build -o $out/$p/piped ./cmd/pipedv1)
  (cd $src/pkg/app/pipedv1/plugin/kubernetes_multicluster && go build -o $out/$p/kubernetes_multicluster .)
  (cd $src/pkg/app/pipedv1/plugin/wait && go build -o $out/$p/wait .)
  tar -czf $out/workshop-tools-$p.tar.gz -C $out/$p .
done

gh release create tools $out/workshop-tools-*.tar.gz \
  --repo mohammedfirdouss/pipecd-multicluster-workshop \
  --title "Workshop tools" --notes "piped v1 + plugins built from pipe-cd/pipecd $(git -C $src log -1 --format='%h (%cd)' --date=short)"
