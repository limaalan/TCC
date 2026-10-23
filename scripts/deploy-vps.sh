#!/usr/bin/env bash
set -euo pipefail
: "${VPS_HOST:?Set VPS_HOST}" "${VPS_USER:?Set VPS_USER}"
: "${VPS_SSH_KEY:?Set VPS_SSH_KEY}" "${VPS_KNOWN_HOSTS:?Set VPS_KNOWN_HOSTS}"
: "${SERVER_IMAGE:?Set SERVER_IMAGE to the published digest}"
port="${VPS_PORT:-22}"
directory="${VPS_DEPLOY_DIR:-/opt/jumpnshoot}"
game_port="${VPS_GAME_PORT:-7777}"
bundle="${GITHUB_RUN_ID:?}-${GITHUB_RUN_ATTEMPT:?}"
[[ "$VPS_HOST" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]] || { echo 'Invalid VPS_HOST' >&2; exit 2; }
[[ "$VPS_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo 'Invalid VPS_USER' >&2; exit 2; }
[[ "$directory" =~ ^/[a-zA-Z0-9_/-]+$ && "$directory" != / && "$directory" != *'//'* ]] || { echo 'Invalid deploy directory' >&2; exit 2; }
[[ "$bundle" =~ ^[0-9]+-[0-9]+$ ]] || exit 2
[[ "$SERVER_IMAGE" =~ ^ghcr\.io/[a-z0-9][a-z0-9._/-]*@sha256:[0-9a-f]{64}$ ]] || { echo 'Expected image digest' >&2; exit 2; }
for value in "$port" "$game_port"; do
    [[ "$value" =~ ^[0-9]{1,5}$ ]] && (( 10#$value >= 1 && 10#$value <= 65535 )) || { echo 'Invalid port' >&2; exit 2; }
done
temporary="$(mktemp -d)"
trap 'rm -rf -- "$temporary"' EXIT
umask 077
printf '%s\n' "$VPS_SSH_KEY" > "$temporary/key"
printf '%s\n' "$VPS_KNOWN_HOSTS" > "$temporary/known_hosts"
options=(-i "$temporary/key" -p "$port" -o BatchMode=yes -o IdentitiesOnly=yes
         -o StrictHostKeyChecking=yes -o "UserKnownHostsFile=$temporary/known_hosts" -o ConnectTimeout=15)
incoming="$directory/incoming/$bundle"
# Paths and digest above are restricted before becoming part of a remote shell command.
tar -cf - compose.prod.yaml scripts/deploy_server.py scripts/smoke/enet_probe.gd |
    ssh "${options[@]}" "$VPS_USER@$VPS_HOST" \
    "set -eu; umask 077; mkdir -p '$incoming'; tar -xf - -C '$incoming'; python3 '$incoming/scripts/deploy_server.py' --directory '$directory' --image '$SERVER_IMAGE' --port '$game_port'"
