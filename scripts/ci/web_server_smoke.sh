#!/usr/bin/env bash
set -euo pipefail

server_binary="${CONTRAIL_SERVER_BINARY:-build/contrail-server}"
web_root="${CONTRAIL_WEB_ROOT:-build/web}"
port="${CONTRAIL_SERVER_SMOKE_PORT:-4180}"
log_file="${CONTRAIL_SERVER_SMOKE_LOG:-build/contrail-server-smoke.log}"

if [[ ! -x "$server_binary" ]]; then
  echo "Server binary is missing or not executable: $server_binary" >&2
  exit 1
fi

WEBDAV_GATEWAY_ALLOWED_HOSTS="dav.example.com" \
CONTRAIL_WEB_ROOT="$web_root" \
CONTRAIL_BIND_ADDRESS="127.0.0.1" \
PORT="$port" \
  "$server_binary" >"$log_file" 2>&1 &
server_pid=$!

cleanup() {
  kill "$server_pid" 2>/dev/null || true
  wait "$server_pid" 2>/dev/null || true
}
trap cleanup EXIT

for _ in {1..50}; do
  if curl --fail --silent "http://127.0.0.1:$port/healthz" \
    | grep --quiet '"status":"ok"'; then
    break
  fi
  if ! kill -0 "$server_pid" 2>/dev/null; then
    sed -n '1,200p' "$log_file" >&2
    exit 1
  fi
  sleep 0.2
done

curl --fail --silent "http://127.0.0.1:$port/" \
  | grep --quiet 'flutter_bootstrap.js'

headers_file="$(mktemp)"
trap 'rm -f "$headers_file"; cleanup' EXIT
curl --silent --output /dev/null --dump-header "$headers_file" \
  --request OPTIONS \
  --header "Origin: http://127.0.0.1:$port" \
  "http://127.0.0.1:$port/api/webdav"
grep --ignore-case --quiet '^HTTP/.* 204' "$headers_file"
grep --ignore-case --quiet '^access-control-allow-origin:' "$headers_file"

echo "Integrated Contrail server smoke test passed"
