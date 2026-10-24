#!/usr/bin/env bash
# Plan preview: what would PipeCD do if your current branch were merged into main?
# Pushes your branch to your fork first, because piped reads changes from GitHub.
# Usage: ./scripts/preview.sh   (run it from a branch, not main)
set -euo pipefail
source "$(dirname "$0")/env.sh"

[ -s "$API_KEY_FILE" ] || { echo "No API key yet. Console: Settings > API Key > +ADD (READ_WRITE), then:"; echo "  echo '<the key>' > $API_KEY_FILE"; exit 1; }

branch=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD)
[ "$branch" != "$BASE_BRANCH" ] || { echo "You're on $BASE_BRANCH. Create a branch first: git switch -c my-change"; exit 1; }
git -C "$REPO_DIR" diff --quiet && git -C "$REPO_DIR" diff --cached --quiet \
  || { echo "You have uncommitted changes. Commit them first."; exit 1; }

git -C "$REPO_DIR" push -q -u origin "$branch"
sha=$(git -C "$REPO_DIR" rev-parse HEAD)

echo "==> plan preview of $branch (${sha:0:7}) against $BASE_BRANCH"
pipectl plan-preview \
  --address="$CONTROL_PLANE_ADDR" --insecure \
  --api-key-file="$API_KEY_FILE" \
  --repo-remote-url="$WORKSHOP_REPO_URL" \
  --head-branch="$branch" --head-commit="$sha" \
  --base-branch="$BASE_BRANCH" \
  --piped-handle-timeout=3m --timeout=5m
