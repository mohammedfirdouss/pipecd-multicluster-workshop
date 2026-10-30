#!/usr/bin/env bash
# For attendees who can't run the setup: they open a PR, this runs plan preview
# on it with your PipeCD and posts the result as a comment.
# Run it every few minutes during the exercises:  ./facilitator/preview-prs.sh
set -euo pipefail
source "$(dirname "$0")/../scripts/env.sh"
REPO=mohammedfirdouss/pipecd-multicluster-workshop

[ -s "$HOME_DIR/api-key" ] || { echo "Save your API key first:  echo '<key>' > $HOME_DIR/api-key"; exit 1; }

# Only PRs that change the app; others (like docs PRs) are skipped.
gh pr list --repo $REPO --state open --json number,headRefOid,files \
  --jq '.[] | select(any(.files[]; .path | startswith("app/"))) | "\(.number) \(.headRefOid)"' |
while read -r n sha; do
  grep -qx "$n $sha" "$HOME_DIR/previewed" 2>/dev/null && continue   # already done
  echo "previewing PR #$n"
  # piped only reads branches from its own repo (this folder's origin), so copy the PR there first
  git -C "$REPO_DIR" fetch -q "https://github.com/$REPO.git" "pull/$n/head"
  git -C "$REPO_DIR" push -q -f origin "FETCH_HEAD:refs/heads/preview/pr-$n"
  if ! result=$(pipectl plan-preview --address=localhost:8080 --insecure \
      --api-key-file="$HOME_DIR/api-key" --repo-remote-url="$REPO_URL" \
      --head-branch="preview/pr-$n" --head-commit="$sha" --base-branch=main 2>&1); then
    echo "  failed, not commenting (it will retry next run):"; echo "$result"; continue
  fi
  printf 'Plan preview:\n\n```\n%s\n```\n' "$result" | gh pr comment "$n" --repo $REPO --body-file -
  echo "$n $sha" >> "$HOME_DIR/previewed"
done
