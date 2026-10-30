#!/usr/bin/env bash
# One-time setup: gets piped + pipectl, creates two clusters, and starts the
# PipeCD control plane at http://localhost:8080
set -euo pipefail
source "$(dirname "$0")/env.sh"

for tool in docker kind kubectl git curl; do
  command -v "$tool" >/dev/null || { echo "Please install $tool first."; exit 1; }
done
docker info >/dev/null 2>&1 || { echo "Docker isn't running. Start it and try again."; exit 1; }

os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
case "$arch" in x86_64) arch=amd64 ;; aarch64) arch=arm64 ;; esac

echo "1/4  piped, pipectl and plugins"
if [ ! -x "$HOME_DIR/bin/piped" ]; then
  rm -f /tmp/workshop-tools.tar.gz
  # Weak Wi-Fi drops connections, so try up to 5 times, carrying on from where it stopped (-C -).
  for try in 1 2 3 4 5; do
    curl -fL --progress-bar -C - -o /tmp/workshop-tools.tar.gz \
      "https://github.com/mohammedfirdouss/pipecd-multicluster-workshop/releases/download/tools/workshop-tools-$os-$arch.tar.gz" && break
    [ "$try" = 5 ] && { echo "Download failed. Check your internet and run ./scripts/setup.sh again."; exit 1; }
    echo "     connection dropped, trying again..."
    sleep 3
  done
  tar -xzf /tmp/workshop-tools.tar.gz -C "$HOME_DIR/bin"
fi

echo "2/4  two Kubernetes clusters"
for c in cluster1 cluster2; do
  kind get clusters | grep -qx "$c" || kind create cluster --name "$c"
  kind export kubeconfig --name "$c" --kubeconfig "$HOME_DIR/kube/$c"
done

echo "3/4  PipeCD control plane (inside cluster1)"
# Two fixes to PipeCD's quickstart manifest:
#  - the control plane image must match the commit piped was built from (see facilitator/build-tools.sh)
#  - its MinIO image was removed from Docker Hub (pipe-cd/pipecd#7380), so use Chainguard's
kubectl --context kind-cluster1 create namespace pipecd 2>/dev/null || true
# Pinned to the same commit as piped, so upstream changes (e.g. a MinIO fix being merged) can't break this.
curl -fsSL https://raw.githubusercontent.com/pipe-cd/pipecd/5b4128201a52d67ddfd11756c5a7dc856c370e32/quickstart/manifests/control-plane.yaml \
  | sed -E -e 's#ghcr.io/pipe-cd/pipecd:v[0-9.]+#ghcr.io/pipe-cd/pipecd:v0.57.0-73-g5b41282#' \
           -e 's#minio/minio:RELEASE[^"[:space:]]*#cgr.dev/chainguard/minio@sha256:73297936408b731668ca0e835ac9add1a35cb6026a125c2f0cd476d9ef48222c#' \
  | kubectl --context kind-cluster1 -n pipecd apply -f - >/dev/null
kubectl --context kind-cluster1 -n pipecd patch deploy pipecd-minio --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"MINIO_ROOT_USER","valueFrom":{"secretKeyRef":{"name":"pipecd","key":"minio-access-key"}}}},
  {"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"MINIO_ROOT_PASSWORD","valueFrom":{"secretKeyRef":{"name":"pipecd","key":"minio-secret-key"}}}},
  {"op":"add","path":"/spec/template/spec/volumes","value":[{"name":"data","emptyDir":{}}]},
  {"op":"add","path":"/spec/template/spec/containers/0/volumeMounts","value":[{"name":"data","mountPath":"/data"}]}
]' >/dev/null 2>&1 || true   # already patched on re-runs
echo "     downloading and starting it. On slow internet this can take 30+ minutes; leave it running..."
kubectl --context kind-cluster1 -n pipecd wait --for=condition=Ready pod --all --timeout=45m \
  || { echo "Still not ready. Run ./scripts/setup.sh again: it keeps what it has downloaded."; exit 1; }

echo "4/4  opening the console on localhost:8080"
pkill -f "port-forward svc/pipecd" 2>/dev/null || true
nohup kubectl --context kind-cluster1 -n pipecd port-forward svc/pipecd 8080 >"$HOME_DIR/port-forward.log" 2>&1 &
sleep 2

echo
echo "Done. Open http://localhost:8080?project=quickstart  (user and password: hello-pipecd)"
