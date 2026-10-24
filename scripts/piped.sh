#!/usr/bin/env bash
# Starts piped. Leave it running in its own terminal.
#   first time:  ./scripts/piped.sh <PIPED_ID> <BASE64_PIPED_KEY>
#   after that:  ./scripts/piped.sh
set -euo pipefail
source "$(dirname "$0")/env.sh"

if [ $# -eq 2 ]; then
  cat > "$HOME_DIR/piped.yaml" <<EOF
apiVersion: pipecd.dev/v1beta1
kind: Piped
spec:
  projectID: quickstart
  pipedID: $1
  pipedKeyData: $2
  apiAddress: localhost:8080
  syncInterval: 30s
  repositories:
    - repoId: workshop
      remote: $REPO_URL
      branch: main
  plugins:
    - name: kubernetes_multicluster
      port: 7002
      url: file://$HOME_DIR/bin/kubernetes_multicluster
      deployTargets:
        - name: cluster1
          config:
            kubeConfigPath: $HOME_DIR/kube/cluster1
        - name: cluster2
          config:
            kubeConfigPath: $HOME_DIR/kube/cluster2
    - name: wait
      port: 7004
      url: file://$HOME_DIR/bin/wait
EOF
fi
[ -f "$HOME_DIR/piped.yaml" ] || { echo "Usage: $0 <PIPED_ID> <BASE64_PIPED_KEY>"; exit 1; }

echo "piped is watching $REPO_URL (main). Leave this running."
exec piped run --config-file="$HOME_DIR/piped.yaml" --tools-dir="$HOME_DIR/tools" --insecure=true --log-encoding=humanize
