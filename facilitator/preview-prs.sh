#!/usr/bin/env bash
# Runs PipeCD plan preview on every open PR and posts the result as a PR comment.
#
# Attendees open PRs from their forks. piped can only preview branches that live
# in the repo it watches, so each PR head is mirrored to a `preview/pr-<N>`
# branch on the workshop repo first. A PR is previewed again only when its head
# commit changes.
#
# Usage: ./preview-prs.sh          one pass over all open PRs
#        ./preview-prs.sh --watch  keep polling every 20s
set -euo pipefail
source "$(dirname "$0")/env.sh"

PIPECTL="$WORK_DIR/bin/pipectl"
MIRROR="$WORK_DIR/mirror"
SEEN="$WORK_DIR/previewed"
touch "$SEEN"
[ -s "$API_KEY_FILE" ] || { echo "Put a READ_WRITE API key in $API_KEY_FILE (Settings > API Key)"; exit 1; }

if [ ! -d "$MIRROR/.git" ]; then
  git clone -q "git@github.com:${WORKSHOP_REPO}.git" "$MIRROR"
fi

preview_one() {
  local n=$1 sha=$2 author=$3
  local branch="preview/pr-$n" out="$WORK_DIR/preview-pr-$n.txt"
  echo "==> PR #$n by @$author at ${sha:0:7}"

  git -C "$MIRROR" fetch -q origin "pull/$n/head"
  git -C "$MIRROR" push -q -f origin "FETCH_HEAD:refs/heads/$branch"

  if "$PIPECTL" plan-preview \
      --address="$CONTROL_PLANE_ADDR" --insecure \
      --api-key-file="$API_KEY_FILE" \
      --repo-remote-url="$WORKSHOP_REPO_URL" \
      --head-branch="$branch" --head-commit="$sha" \
      --base-branch="$BASE_BRANCH" \
      --piped-handle-timeout=3m --timeout=5m \
      --out="$out" 2>"$out.err"; then
    status="Plan preview for \`${sha:0:7}\`"
  else
    status="Plan preview **failed** for \`${sha:0:7}\` (check your YAML indentation, then push again)"
    [ -s "$out" ] || cp "$out.err" "$out"
  fi

  {
    echo "$status"
    echo
    echo '```'
    cat "$out"
    echo '```'
  } | gh pr comment "$n" --repo "$WORKSHOP_REPO" --body-file -

  echo "$n $sha" >> "$SEEN"
}

pass() {
  gh pr list --repo "$WORKSHOP_REPO" --state open --limit 200 \
    --json number,headRefOid,author \
    --jq '.[] | "\(.number) \(.headRefOid) \(.author.login)"' |
  while read -r n sha author; do
    grep -qx "$n $sha" "$SEEN" || preview_one "$n" "$sha" "$author" || echo "   (PR #$n errored, will retry)"
  done
}

if [ "${1:-}" = "--watch" ]; then
  while true; do pass; sleep 20; done
else
  pass
fi
