# Shared settings for the facilitator scripts. Source it, don't run it.
# Override any of these by exporting them before running a script.

FACILITATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${WORK_DIR:-$FACILITATOR_DIR/.work}"

# The workshop repo on GitHub (owner/name). Attendees fork this and open PRs against it.
WORKSHOP_REPO="${WORKSHOP_REPO:-mohammedfirdouss/pipecd-multicluster-workshop}"
WORKSHOP_REPO_URL="https://github.com/${WORKSHOP_REPO}.git"
BASE_BRANCH="${BASE_BRANCH:-main}"

# A checkout of pipe-cd/pipecd master. piped v1 runs from source because the
# latest released pipedv1 build (v1.0.0-alpha1, Oct 2025) predates the
# multicluster plugin's plan preview support.
PIPECD_SRC="${PIPECD_SRC:-$HOME/Desktop/Git-projects/pipecd-master}"

# Control plane image version used by the quickstart manifest.
CONTROL_PLANE_VERSION="${CONTROL_PLANE_VERSION:-v0.58.0}"
PIPECTL_VERSION="${PIPECTL_VERSION:-v0.58.0}"

CONTROL_PLANE_ADDR="${CONTROL_PLANE_ADDR:-localhost:8080}"
API_KEY_FILE="${API_KEY_FILE:-$WORK_DIR/api-key}"

KIND_CLUSTERS=(pipecd cluster1 cluster2)
APP_IMAGES=(ghcr.io/pipe-cd/helloworld:v0.47.0 ghcr.io/pipe-cd/helloworld:v0.47.1 ghcr.io/pipe-cd/helloworld:v0.47.2)

mkdir -p "$WORK_DIR/kube" "$WORK_DIR/bin"
