#!/usr/bin/env bash
# Exposes the control plane (web UI + gRPC for piped and pipectl) on localhost:8080.
# Restarts automatically if the port-forward drops.
set -uo pipefail
source "$(dirname "$0")/env.sh"

while true; do
  kubectl --context kind-pipecd -n pipecd port-forward svc/pipecd 8080
  echo "port-forward exited, restarting in 2s..."
  sleep 2
done
