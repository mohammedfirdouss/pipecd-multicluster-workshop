#!/usr/bin/env bash
# Starts piped, connected to your control plane and your two clusters, watching your fork.
# Usage: ./scripts/run-piped.sh <PIPED_ID> <BASE64_PIPED_KEY>   (first time)
#        ./scripts/run-piped.sh                                 (after that)
# Both values come from the console: Settings > Piped > +ADD.
set -euo pipefail
source "$(dirname "$0")/env.sh"

if [ $# -eq 2 ]; then
  printf '%s\n%s\n' "$1" "$2" > "$PIPED_CREDENTIALS"
fi
[ -f "$PIPED_CREDENTIALS" ] || { echo "usage: $0 <PIPED_ID> <BASE64_PIPED_KEY>"; exit 1; }

sed -e "s#__PIPED_ID__#$(sed -n 1p "$PIPED_CREDENTIALS")#" \
    -e "s#__PIPED_KEY_DATA__#$(sed -n 2p "$PIPED_CREDENTIALS")#" \
    -e "s#__CONTROL_PLANE_ADDR__#${CONTROL_PLANE_ADDR}#" \
    -e "s#__WORKSHOP_REPO_URL__#${WORKSHOP_REPO_URL}#" \
    -e "s#__BASE_BRANCH__#${BASE_BRANCH}#" \
    -e "s#__PLUGINS_DIR__#${PLUGINS_DIR}#g" \
    -e "s#__KUBE_DIR__#${KUBE_DIR}#g" \
    "$SCRIPTS_DIR/piped-config.yaml.tmpl" > "$WORKSHOP_HOME/piped-config.yaml"

echo "==> piped watching ${WORKSHOP_REPO_URL} (${BASE_BRANCH}). Leave this terminal open."
exec "$BIN_DIR/piped" run \
  --config-file="$WORKSHOP_HOME/piped-config.yaml" \
  --tools-dir="$WORKSHOP_HOME/piped-tools" \
  --insecure=true \
  --log-encoding=humanize
