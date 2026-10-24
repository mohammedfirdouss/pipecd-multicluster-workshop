#!/usr/bin/env bash
# Plan preview: what would PipeCD do if this branch were merged into main?
# Run it from a branch with your changes committed.
set -euo pipefail
source "$(dirname "$0")/env.sh"

[ -s "$HOME_DIR/api-key" ] || { echo "Save your API key first:  echo '<key>' > $HOME_DIR/api-key"; exit 1; }
branch=$(git -C "$REPO_DIR" branch --show-current)
[ "$branch" != main ] || { echo "Make a branch first:  git switch -c my-change"; exit 1; }

git -C "$REPO_DIR" push -q -u origin "$branch"
pipectl plan-preview \
  --address=localhost:8080 --insecure \
  --api-key-file="$HOME_DIR/api-key" \
  --repo-remote-url="$REPO_URL" \
  --head-branch="$branch" --head-commit="$(git -C "$REPO_DIR" rev-parse HEAD)" \
  --base-branch=main
