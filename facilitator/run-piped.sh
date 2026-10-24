#!/usr/bin/env bash
# Renders piped-config.yaml and runs piped v1 from the pipecd source checkout.
# Usage: ./run-piped.sh <PIPED_ID> <BASE64_PIPED_KEY>
#   (both values come from Settings > Piped > +ADD in the control plane UI)
set -euo pipefail
source "$(dirname "$0")/env.sh"

if [ $# -eq 2 ]; then
  printf '%s\n%s\n' "$1" "$2" > "$WORK_DIR/piped-credentials"
fi
[ -f "$WORK_DIR/piped-credentials" ] || { echo "usage: $0 <PIPED_ID> <BASE64_PIPED_KEY>"; exit 1; }
PIPED_ID=$(sed -n 1p "$WORK_DIR/piped-credentials")
PIPED_KEY_DATA=$(sed -n 2p "$WORK_DIR/piped-credentials")

sed -e "s#__PIPED_ID__#${PIPED_ID}#" \
    -e "s#__PIPED_KEY_DATA__#${PIPED_KEY_DATA}#" \
    -e "s#__CONTROL_PLANE_ADDR__#${CONTROL_PLANE_ADDR}#" \
    -e "s#__WORKSHOP_REPO_URL__#${WORKSHOP_REPO_URL}#" \
    -e "s#__BASE_BRANCH__#${BASE_BRANCH}#" \
    -e "s#__HOME__#${HOME}#g" \
    -e "s#__WORK_DIR__#${WORK_DIR}#g" \
    "$FACILITATOR_DIR/piped-config.yaml.tmpl" > "$WORK_DIR/piped-config.yaml"

echo "==> piped v1 from $PIPECD_SRC ($(git -C "$PIPECD_SRC" log -1 --format='%h %cd' --date=short))"
make -C "$PIPECD_SRC" run/piped CONFIG_FILE="$WORK_DIR/piped-config.yaml" INSECURE=true EXPERIMENTAL=true
