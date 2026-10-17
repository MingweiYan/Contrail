#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

bind_address="${CONTRAIL_BIND_ADDRESS:-127.0.0.1}"
service_port="${PORT:-8080}"
allowed_hosts="${WEBDAV_GATEWAY_ALLOWED_HOSTS:-dav.jianguoyun.com}"
open_browser=true
smoke_test=false

usage() {
  cat <<'USAGE'
Build and run Contrail's integrated Web application and WebDAV gateway.

Usage: scripts/deploy_web.sh [options]

Options:
  --bind <address>         Bind address (default: 127.0.0.1)
  --port <port>            Service port (default: 8080)
  --allowed-hosts <hosts>  Comma-separated WebDAV host allowlist
                           (default: dav.jianguoyun.com)
  --no-open                Do not open the application in a browser
  --smoke-test             Stop after the service health check succeeds
  -h, --help               Show this help

The same defaults can be overridden with CONTRAIL_BIND_ADDRESS, PORT, and
WEBDAV_GATEWAY_ALLOWED_HOSTS environment variables.
USAGE
}

while (($# > 0)); do
  case "$1" in
    --bind)
      [[ $# -ge 2 ]] || { echo "Missing value for --bind" >&2; exit 64; }
      bind_address="$2"
      shift 2
      ;;
    --port)
      [[ $# -ge 2 ]] || { echo "Missing value for --port" >&2; exit 64; }
      service_port="$2"
      shift 2
      ;;
    --allowed-hosts)
      [[ $# -ge 2 ]] || {
        echo "Missing value for --allowed-hosts" >&2
        exit 64
      }
      allowed_hosts="$2"
      shift 2
      ;;
    --no-open)
      open_browser=false
      shift
      ;;
    --smoke-test)
      smoke_test=true
      open_browser=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ ! "$service_port" =~ ^[0-9]+$ ]] ||
  ((service_port < 1 || service_port > 65535)); then
  echo "Port must be an integer from 1 to 65535: $service_port" >&2
  exit 64
fi
if [[ -z "${allowed_hosts//[[:space:],]/}" ]]; then
  echo "At least one WebDAV host must be allowed." >&2
  exit 64
fi

for command_name in flutter dart curl; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command is not available: $command_name" >&2
    exit 69
  fi
done

cd "$repo_root"

echo "==> Installing locked Flutter dependencies"
flutter pub get --enforce-lockfile

echo "==> Building the integrated Web application"
flutter build web --release --no-wasm-dry-run \
  --dart-define=WEBDAV_GATEWAY_URL=/api/webdav

server_binary="$repo_root/build/contrail-server"
web_root="$repo_root/build/web"

echo "==> Compiling the integrated Web server"
dart compile exe server/bin/contrail_server.dart -o "$server_binary"

export CONTRAIL_BIND_ADDRESS="$bind_address"
export CONTRAIL_WEB_ROOT="$web_root"
export PORT="$service_port"
export WEBDAV_GATEWAY_ALLOWED_HOSTS="$allowed_hosts"

connect_host="$bind_address"
case "$connect_host" in
  0.0.0.0|::|'[::]') connect_host="127.0.0.1" ;;
esac
url_host="$connect_host"
if [[ "$url_host" == *:* && "$url_host" != \[*\] ]]; then
  url_host="[$url_host]"
fi
service_url="http://$url_host:$service_port"

server_pid=""
cleanup() {
  if [[ -n "$server_pid" ]] && kill -0 "$server_pid" 2>/dev/null; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

echo "==> Starting Contrail on $service_url"
"$server_binary" &
server_pid=$!

health_url="$service_url/healthz"
ready=false
for ((attempt = 0; attempt < 100; attempt++)); do
  if ! kill -0 "$server_pid" 2>/dev/null; then
    set +e
    wait "$server_pid"
    server_status=$?
    set -e
    echo "Contrail exited before becoming healthy (status $server_status)." >&2
    if ((server_status == 0)); then
      exit 1
    fi
    exit "$server_status"
  fi
  if health_body="$(curl --fail --silent --max-time 2 "$health_url" 2>/dev/null)" &&
    [[ "$health_body" == *'"status":"ok"'* ]]; then
    ready=true
    break
  fi
  sleep 0.2
done

if [[ "$ready" != true ]]; then
  echo "Contrail did not become healthy at $health_url." >&2
  exit 1
fi

app_url="$service_url/"
echo "Contrail is ready: $app_url"

if [[ "$smoke_test" == true ]]; then
  echo "Cross-platform deployment smoke test passed."
  exit 0
fi

if [[ "$open_browser" == true ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    open "$app_url"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$app_url" >/dev/null 2>&1 || true
  fi
fi

echo "Press Ctrl+C to stop Contrail."
set +e
wait "$server_pid"
server_status=$?
set -e
server_pid=""
exit "$server_status"
