#!/usr/bin/env bash
# Shows which version of hello-ibadan is running in each cluster.
source "$(dirname "$0")/env.sh"

for c in cluster1 cluster2; do
  echo "--- $c ---"
  kubectl --context "kind-$c" get pods -l app=hello-ibadan \
    -o custom-columns='POD:.metadata.name,VARIANT:.metadata.labels.pipecd\.dev/variant,IMAGE:.spec.containers[0].image,STATUS:.status.phase'
done
