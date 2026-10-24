#!/usr/bin/env bash
# After the workshop: deletes the preview/* branches and, with --clusters, the kind clusters.
set -euo pipefail
source "$(dirname "$0")/env.sh"

if [ -d "$WORK_DIR/mirror/.git" ]; then
  branches=$(git -C "$WORK_DIR/mirror" ls-remote --heads origin 'preview/*' | awk '{print $2}')
  for b in $branches; do
    git -C "$WORK_DIR/mirror" push -q origin --delete "${b#refs/heads/}" && echo "deleted ${b#refs/heads/}"
  done
fi

if [ "${1:-}" = "--clusters" ]; then
  for c in "${KIND_CLUSTERS[@]}"; do kind delete cluster --name "$c"; done
fi
