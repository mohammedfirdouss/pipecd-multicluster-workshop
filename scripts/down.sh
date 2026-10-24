#!/usr/bin/env bash
# Deletes the kind clusters and stops the port-forward. Installed tools stay.
set -uo pipefail
source "$(dirname "$0")/env.sh"

pkill -f "port-forward svc/pipecd 8080" || true
for c in "${KIND_CLUSTERS[@]}"; do kind delete cluster --name "$c"; done
