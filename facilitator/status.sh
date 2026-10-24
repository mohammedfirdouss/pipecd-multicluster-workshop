#!/usr/bin/env bash
# Shows the hello-ibadan pods and which image each cluster is running.
# Keep it on screen during the live rollout: watch -n2 ./facilitator/status.sh
set -uo pipefail
source "$(dirname "$0")/env.sh"

for c in cluster1 cluster2; do
  echo "── $c ──────────────────────────────"
  kubectl --kubeconfig "$WORK_DIR/kube/$c" get pods -l app=hello-ibadan \
    -o custom-columns='POD:.metadata.name,VARIANT:.metadata.labels.pipecd\.dev/variant,IMAGE:.spec.containers[0].image,STATUS:.status.phase' 2>/dev/null
  echo "service → $(kubectl --kubeconfig "$WORK_DIR/kube/$c" get svc hello-ibadan -o jsonpath='{.spec.selector}' 2>/dev/null)"
done
