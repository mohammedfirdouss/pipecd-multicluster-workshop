# Shared settings. Source it, don't run it. Works in a Codespace and on a laptop.

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"

# Everything generated (tools, kubeconfigs, keys) lives outside the repo.
WORKSHOP_HOME="${WORKSHOP_HOME:-$HOME/.pipecd-workshop}"
BIN_DIR="$WORKSHOP_HOME/bin"
PLUGINS_DIR="$WORKSHOP_HOME/plugins"
KUBE_DIR="$WORKSHOP_HOME/kube"
PIPECD_SRC="$WORKSHOP_HOME/pipecd-src"
mkdir -p "$BIN_DIR" "$PLUGINS_DIR" "$KUBE_DIR"
export PATH="$BIN_DIR:$PATH"

# The repo piped watches: your fork, read from the git remote.
if [ -z "${WORKSHOP_REPO:-}" ]; then
  WORKSHOP_REPO="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##' || true)"
  [ -n "$WORKSHOP_REPO" ] || { echo "No 'origin' remote. Clone your fork, or set WORKSHOP_REPO=<you>/pipecd-multicluster-workshop"; exit 1; }
fi
# The original repo, where ready-built binaries are published as a release.
UPSTREAM_REPO="${UPSTREAM_REPO:-mohammedfirdouss/pipecd-multicluster-workshop}"
TOOLS_RELEASE="${TOOLS_RELEASE:-tools-2026-10}"
WORKSHOP_REPO_URL="https://github.com/${WORKSHOP_REPO}.git"
BASE_BRANCH="${BASE_BRANCH:-main}"

# piped v1 is built from pipe-cd/pipecd master: the latest released pipedv1
# build (v1.0.0-alpha1, Oct 2025) predates the multicluster plugin's plan preview.
PIPECD_REF="${PIPECD_REF:-master}"
CONTROL_PLANE_VERSION="${CONTROL_PLANE_VERSION:-v0.58.0}"
PIPECTL_VERSION="${PIPECTL_VERSION:-v0.58.0}"
KIND_VERSION="${KIND_VERSION:-v0.33.0}"

CONTROL_PLANE_ADDR="${CONTROL_PLANE_ADDR:-localhost:8080}"
API_KEY_FILE="$WORKSHOP_HOME/api-key"
PIPED_CREDENTIALS="$WORKSHOP_HOME/piped-credentials"

# Two clusters keep memory down: the control plane runs in cluster1, namespace pipecd.
KIND_CLUSTERS=(cluster1 cluster2)
CP_CONTEXT=kind-cluster1

os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m); [ "$arch" = x86_64 ] && arch=amd64; [ "$arch" = aarch64 ] && arch=arm64
