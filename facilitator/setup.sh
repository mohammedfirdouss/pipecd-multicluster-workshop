#!/usr/bin/env bash
# Creates the three kind clusters, installs the PipeCD control plane, builds the
# plugins and downloads pipectl. Safe to re-run: it skips what already exists.
set -euo pipefail
source "$(dirname "$0")/env.sh"

for tool in docker kind kubectl go gh git make curl; do
  command -v "$tool" >/dev/null || { echo "missing: $tool"; exit 1; }
done
docker info >/dev/null 2>&1 || { echo "Docker isn't running. Start OrbStack/Docker Desktop first."; exit 1; }
[ -d "$PIPECD_SRC/.git" ] || { echo "PIPECD_SRC not found: $PIPECD_SRC (see RUNBOOK.md step 1)"; exit 1; }

echo "==> kind clusters"
for c in "${KIND_CLUSTERS[@]}"; do
  kind get clusters | grep -qx "$c" || kind create cluster --name "$c"
done
for c in cluster1 cluster2; do
  kind export kubeconfig --name "$c" --kubeconfig "$WORK_DIR/kube/$c"
done

echo "==> pre-loading app images (so the venue Wi-Fi isn't needed for pulls)"
for img in "${APP_IMAGES[@]}"; do
  docker image inspect "$img" >/dev/null 2>&1 || docker pull "$img"
  kind load docker-image "$img" --name cluster1
  kind load docker-image "$img" --name cluster2
done

echo "==> PipeCD control plane $CONTROL_PLANE_VERSION in kind-pipecd"
kubectl --context kind-pipecd create namespace pipecd --dry-run=client -o yaml | kubectl --context kind-pipecd apply -f -
curl -fsSL https://raw.githubusercontent.com/pipe-cd/pipecd/master/quickstart/manifests/control-plane.yaml \
  | sed -E "s#ghcr.io/pipe-cd/pipecd:v[0-9.]+#ghcr.io/pipe-cd/pipecd:${CONTROL_PLANE_VERSION}#g" \
  | kubectl --context kind-pipecd -n pipecd apply -f -
echo "    waiting for control plane pods (first run pulls images, can take minutes)..."
kubectl --context kind-pipecd -n pipecd wait --for=condition=Ready pod --all --timeout=15m

echo "==> pipectl $PIPECTL_VERSION"
if [ ! -x "$WORK_DIR/bin/pipectl" ]; then
  os=$(uname -s | tr '[:upper:]' '[:lower:]'); arch=$(uname -m); [ "$arch" = x86_64 ] && arch=amd64; [ "$arch" = aarch64 ] && arch=arm64
  curl -fsSL -o "$WORK_DIR/bin/pipectl" \
    "https://github.com/pipe-cd/pipecd/releases/download/${PIPECTL_VERSION}/pipectl_${PIPECTL_VERSION}_${os}_${arch}"
  chmod +x "$WORK_DIR/bin/pipectl"
fi

echo "==> plugins from $PIPECD_SRC ($(git -C "$PIPECD_SRC" log -1 --format='%h %cd' --date=short))"
make -C "$PIPECD_SRC" build/plugin PLUGINS=kubernetes_multicluster,wait

cat <<EOF

Done. Next (see RUNBOOK.md):
  1. ./facilitator/port-forward.sh            (leave running)
  2. Open http://localhost:8080?project=quickstart  (hello-pipecd / hello-pipecd)
  3. Settings > Piped > +ADD, then run ./facilitator/run-piped.sh <PIPED_ID> <BASE64_PIPED_KEY>
EOF
