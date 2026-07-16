#!/bin/bash
set -euo pipefail

REGISTRY_PATH="${JADEITE_REGISTRY:-ghcr.io/nothingneko/jadeite}"
CHANNEL="${JADEITE_CHANNEL:-latest}"

case "$(uname -m)" in
  x86_64)  DEFAULT_ARCH_TAG="amd64" ;;
  aarch64) DEFAULT_ARCH_TAG="rpi4" ;;
  *) echo "can't recognize your arch $(uname -m), some fucky shit is happening" >&2; exit 1 ;;
esac
ARCH_TAG="${JADEITE_ARCH_TAG:-$DEFAULT_ARCH_TAG}"

IMAGE="${REGISTRY_PATH}:${CHANNEL}-${ARCH_TAG}"
STATE_FILE="/usr/local/lib/jadeite/last-digest"
mkdir -p "$(dirname "$STATE_FILE")"

echo "checking for system updates ${IMAGE}"
podman pull "docker://${IMAGE}"
NEW_DIGEST="$(podman image inspect "${IMAGE}" --format '{{.Digest}}')"

OLD_DIGEST=""
[ -f "$STATE_FILE" ] && OLD_DIGEST="$(cat "$STATE_FILE")"

if [ "$NEW_DIGEST" != "$OLD_DIGEST" ]; then
  echo "new image found (${NEW_DIGEST}), switching"
  kairos-agent upgrade --source "docker://${IMAGE}"
  echo "$NEW_DIGEST" > "$STATE_FILE"
else
  echo "system up to date (${NEW_DIGEST})"
fi
