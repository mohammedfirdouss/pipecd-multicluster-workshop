#!/usr/bin/env bash
# Which version is running where? Keep it on screen during a rollout:
#   watch -n2 ./scripts/status.sh
set -uo pipefail
source "$(dirname "$0")/env.sh"

for c in cluster1 cluster2; do
  echo "── $c ──────────────────────────────"
  kubectl --kubeconfig "$KUBE_DIR/$c" get pods -l app=hello-ibadan \
    -o custom-columns='POD:.metadata.name,VARIANT:.metadata.labels.pipecd\.dev/variant,IMAGE:.spec.containers[0].image,STATUS:.status.phase' 2>/dev/null
  echo "service → $(kubectl --kubeconfig "$KUBE_DIR/$c" get svc hello-ibadan -o jsonpath='{.spec.selector}' 2>/dev/null)"
done
