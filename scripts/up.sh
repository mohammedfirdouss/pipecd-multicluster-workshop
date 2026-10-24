#!/usr/bin/env bash
# Creates two kind clusters, installs the PipeCD control plane in cluster1 and
# exposes it on localhost:8080. Safe to re-run.
#
#   ./scripts/up.sh /path/to/bundle   loads container images from the USB bundle first
#   ./scripts/up.sh                   pulls images from the internet
set -euo pipefail
source "$(dirname "$0")/env.sh"

BUNDLE_DIR="${1:-}"

for tool in docker kind kubectl curl; do
  command -v "$tool" >/dev/null || { echo "missing: $tool (run scripts/install-tools.sh first)"; exit 1; }
done
docker info >/dev/null 2>&1 || { echo "Docker isn't running. Start Docker Desktop / OrbStack / Rancher Desktop first."; exit 1; }

if [ -n "$BUNDLE_DIR" ]; then
  darch=$(docker info --format '{{.Architecture}}'); [ "$darch" = aarch64 ] && darch=arm64; [ "$darch" = x86_64 ] && darch=amd64
  IMAGES="$BUNDLE_DIR/images/$darch"
  echo "==> loading the Kubernetes node image from the bundle ($darch)"
  docker load -i "$IMAGES/kind-node.tar"
fi

echo "==> kind clusters: ${KIND_CLUSTERS[*]}"
for c in "${KIND_CLUSTERS[@]}"; do
  kind get clusters 2>/dev/null | grep -qx "$c" || kind create cluster --name "$c" --wait 2m
  kind export kubeconfig --name "$c" --kubeconfig "$KUBE_DIR/$c"
done

if [ -n "$BUNDLE_DIR" ]; then
  echo "==> loading control plane and app images into the clusters"
  kind load image-archive "$IMAGES/control-plane.tar" --name cluster1
  for c in "${KIND_CLUSTERS[@]}"; do
    kind load image-archive "$IMAGES/app.tar" --name "$c"
  done
fi

echo "==> PipeCD control plane $CONTROL_PLANE_VERSION (in cluster1, namespace pipecd)"
if [ -n "$BUNDLE_DIR" ]; then
  manifest=$(cat "$BUNDLE_DIR/control-plane.yaml")
else
  manifest=$(curl -fsSL https://raw.githubusercontent.com/pipe-cd/pipecd/master/quickstart/manifests/control-plane.yaml \
    | sed -E "s#ghcr.io/pipe-cd/pipecd:v[0-9.]+#ghcr.io/pipe-cd/pipecd:${CONTROL_PLANE_VERSION}#g")
fi
kubectl --context "$CP_CONTEXT" create namespace pipecd --dry-run=client -o yaml | kubectl --context "$CP_CONTEXT" apply -f - >/dev/null
echo "$manifest" | kubectl --context "$CP_CONTEXT" -n pipecd apply -f - >/dev/null
echo "    waiting for control plane pods..."
kubectl --context "$CP_CONTEXT" -n pipecd wait --for=condition=Ready pod --all --timeout=15m

echo "==> exposing the control plane on localhost:8080"
if ! pgrep -f "port-forward svc/pipecd 8080" >/dev/null; then
  nohup bash -c "while true; do kubectl --context $CP_CONTEXT -n pipecd port-forward svc/pipecd 8080; sleep 2; done" \
    >"$WORKSHOP_HOME/port-forward.log" 2>&1 &
fi

cat <<EOF

Ready. Open http://localhost:8080?project=quickstart
Log in with hello-pipecd / hello-pipecd, then carry on with the guide.
EOF
