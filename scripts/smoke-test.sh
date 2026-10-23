#!/usr/bin/env bash
set -euo pipefail
host="${1:-server}"
port="${2:-7777}"
seconds="${3:-10}"
if [[ ! "$port" =~ ^[0-9]{1,5}$ ]] || (( 10#$port < 1 || 10#$port > 65535 )); then
    echo 'Invalid port: expected 1..65535' >&2
    exit 2
fi
if [[ ! "$seconds" =~ ^[0-9]{1,3}$ ]] || (( 10#$seconds < 1 || 10#$seconds > 120 )); then
    echo 'Invalid timeout: expected 1..120 seconds' >&2
    exit 2
fi
log="$(mktemp)"
trap 'rm -f "$log"' EXIT
if ! timeout --kill-after=2 "$((10#$seconds + 5))" "${GODOT:-godot}" \
    --headless --path /tmp --script "$(dirname "$0")/smoke/enet_probe.gd" -- \
    "--host=$host" "--port=$port" "--timeout=$seconds" >"$log" 2>&1; then
    cat "$log" >&2
    echo "ENet smoke failed: $host:$port" >&2
    exit 1
fi
cat "$log"
if grep -Eq '(^ERROR:|^SCRIPT ERROR:)' "$log" || ! grep -q '^ENET_PROBE_CONNECTED' "$log"; then
    echo 'ENet smoke did not confirm a healthy connection' >&2
    exit 1
fi
