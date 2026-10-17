#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

bind_address="${CONTRAIL_BIND_ADDRESS:-127.0.0.1}"
service_port="${PORT:-27831}"
allowed_hosts="${WEBDAV_GATEWAY_ALLOWED_HOSTS:-dav.jianguoyun.com}"
runtime_dir="${CONTRAIL_RUNTIME_DIR:-$repo_root/runtime}"
log_level="${CONTRAIL_LOG_LEVEL:-info}"
log_file="${CONTRAIL_LOG_FILE:-}"
log_max_bytes="${CONTRAIL_LOG_MAX_BYTES:-10485760}"
log_backups="${CONTRAIL_LOG_BACKUP_COUNT:-3}"
open_browser=true
open_log=false
smoke_test=false
skip_build=false
rebuild=false

usage() {
  cat <<'USAGE'
Start Contrail's integrated Web application and WebDAV gateway in the background.

Usage: scripts/deploy_web.sh [options]

Options:
  --bind <address>          Bind address (default: 127.0.0.1)
  --port <port>             Service port (default: 27831)
  --allowed-hosts <hosts>   Comma-separated WebDAV host allowlist
  --runtime-dir <path>      PID, state, and launch diagnostics directory
  --log-file <path>         Rotating service log (default: runtime/contrail.log)
  --log-level <level>       debug, info, warn, error, or off (default: info)
  --log-max-mb <size>       Maximum size of each log file (default: 10)
  --log-backups <count>     Rotated log files to retain (default: 3)
  --open-log                Open the service log after startup
  --no-open                 Do not open the application in a browser
  --rebuild                 Rebuild even when compiled artifacts already exist
  --skip-build              Require an existing build; never invoke build tools
  --smoke-test              Health-check a temporary process, then stop it
  -h, --help                Show this help

When build/web/index.html or the native server is missing, this script invokes
scripts/build_web.sh automatically unless --skip-build is supplied. Use the
same names as environment variables for non-interactive configuration.
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
      [[ $# -ge 2 ]] || { echo "Missing value for --allowed-hosts" >&2; exit 64; }
      allowed_hosts="$2"
      shift 2
      ;;
    --runtime-dir)
      [[ $# -ge 2 ]] || { echo "Missing value for --runtime-dir" >&2; exit 64; }
      runtime_dir="$2"
      shift 2
      ;;
    --log-file)
      [[ $# -ge 2 ]] || { echo "Missing value for --log-file" >&2; exit 64; }
      log_file="$2"
      shift 2
      ;;
    --log-level)
      [[ $# -ge 2 ]] || { echo "Missing value for --log-level" >&2; exit 64; }
      log_level="$2"
      shift 2
      ;;
    --log-max-mb)
      [[ $# -ge 2 ]] || { echo "Missing value for --log-max-mb" >&2; exit 64; }
      [[ "$2" =~ ^[0-9]+$ ]] || { echo "Log size must be an integer: $2" >&2; exit 64; }
      log_max_bytes=$((10#$2 * 1024 * 1024))
      shift 2
      ;;
    --log-backups)
      [[ $# -ge 2 ]] || { echo "Missing value for --log-backups" >&2; exit 64; }
      log_backups="$2"
      shift 2
      ;;
    --open-log)
      open_log=true
      shift
      ;;
    --no-open)
      open_browser=false
      shift
      ;;
    --rebuild)
      rebuild=true
      shift
      ;;
    --skip-build)
      skip_build=true
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
  ((10#$service_port < 1 || 10#$service_port > 65535)); then
  echo "Port must be an integer from 1 to 65535: $service_port" >&2
  exit 64
fi
if [[ -z "${allowed_hosts//[[:space:],]/}" ]]; then
  echo "At least one WebDAV host must be allowed." >&2
  exit 64
fi
normalized_log_level="$(printf '%s' "$log_level" | tr '[:upper:]' '[:lower:]')"
case "$normalized_log_level" in
  debug|info|warn|warning|error|off) ;;
  *) echo "Log level must be debug, info, warn, error, or off: $log_level" >&2; exit 64 ;;
esac
log_level="$normalized_log_level"
if [[ ! "$log_max_bytes" =~ ^[0-9]+$ ]] || ((10#$log_max_bytes < 1024)); then
  echo "Log size must be at least 1024 bytes: $log_max_bytes" >&2
  exit 64
fi
if [[ ! "$log_backups" =~ ^[0-9]+$ ]] || ((10#$log_backups > 100)); then
  echo "Log backup count must be from 0 to 100: $log_backups" >&2
  exit 64
fi
if [[ "$skip_build" == true && "$rebuild" == true ]]; then
  echo "--skip-build and --rebuild cannot be used together." >&2
  exit 64
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "Required command is not available: curl" >&2
  exit 69
fi

cd "$repo_root"
server_binary="$repo_root/build/contrail-server"
web_root="$repo_root/build/web"
artifacts_ready=true
[[ -x "$server_binary" ]] || artifacts_ready=false
[[ -f "$web_root/index.html" ]] || artifacts_ready=false

if [[ "$skip_build" == true ]]; then
  if [[ "$artifacts_ready" != true ]]; then
    echo "Compiled Contrail artifacts are missing; --skip-build forbids rebuilding." >&2
    exit 66
  fi
elif [[ "$rebuild" == true || "$artifacts_ready" != true ]]; then
  "$script_dir/build_web.sh"
fi

if [[ "$runtime_dir" != /* ]]; then
  runtime_dir="$repo_root/$runtime_dir"
fi
mkdir -p "$runtime_dir"
if [[ -z "$log_file" ]]; then
  log_file="$runtime_dir/contrail.log"
elif [[ "$log_file" != /* ]]; then
  log_file="$repo_root/$log_file"
fi
mkdir -p "$(dirname "$log_file")"

pid_file="$runtime_dir/contrail.pid"
url_file="$runtime_dir/contrail.url"
launch_log="$runtime_dir/contrail-launch.log"

is_expected_process() {
  local process_id="$1"
  local command_line
  command_line="$(ps -p "$process_id" -o command= 2>/dev/null || true)"
  [[ "$command_line" == *"$server_binary"* ]]
}

if [[ -f "$pid_file" ]]; then
  existing_pid="$(tr -d '[:space:]' <"$pid_file")"
  if [[ "$existing_pid" =~ ^[0-9]+$ ]] && kill -0 "$existing_pid" 2>/dev/null; then
    if is_expected_process "$existing_pid"; then
      existing_url="$(cat "$url_file" 2>/dev/null || true)"
      echo "Contrail is already running (PID $existing_pid${existing_url:+, $existing_url})."
      echo "Stop it with: $script_dir/stop_web.sh"
      exit 0
    fi
    echo "Refusing to reuse PID $existing_pid because it belongs to another process." >&2
    exit 73
  fi
  rm -f "$pid_file" "$url_file"
fi

connect_host="$bind_address"
case "$connect_host" in
  0.0.0.0|::|'[::]') connect_host="127.0.0.1" ;;
esac
url_host="$connect_host"
if [[ "$url_host" == *:* && "$url_host" != \[*\] ]]; then
  url_host="[$url_host]"
fi
service_url="http://$url_host:$service_port"

: >"$launch_log"
echo "==> Starting Contrail in the background on $service_url"
CONTRAIL_BIND_ADDRESS="$bind_address" \
CONTRAIL_WEB_ROOT="$web_root" \
PORT="$service_port" \
WEBDAV_GATEWAY_ALLOWED_HOSTS="$allowed_hosts" \
CONTRAIL_LOG_LEVEL="$log_level" \
CONTRAIL_LOG_FILE="$log_file" \
CONTRAIL_LOG_MAX_BYTES="$log_max_bytes" \
CONTRAIL_LOG_BACKUP_COUNT="$log_backups" \
  nohup "$server_binary" </dev/null >"$launch_log" 2>&1 &
server_pid=$!
printf '%s\n' "$server_pid" >"$pid_file"
printf '%s\n' "$service_url" >"$url_file"

cleanup_started_process=true
cleanup() {
  if [[ "$cleanup_started_process" == true ]]; then
    if kill -0 "$server_pid" 2>/dev/null && is_expected_process "$server_pid"; then
      kill "$server_pid" 2>/dev/null || true
      for _ in {1..50}; do
        kill -0 "$server_pid" 2>/dev/null || break
        sleep 0.1
      done
    fi
    rm -f "$pid_file" "$url_file"
  fi
}
trap cleanup EXIT INT TERM

health_url="$service_url/healthz"
ready=false
for ((attempt = 0; attempt < 100; attempt++)); do
  if ! kill -0 "$server_pid" 2>/dev/null; then
    echo "Contrail exited before becoming healthy." >&2
    tail -n 100 "$launch_log" "$log_file" 2>/dev/null >&2 || true
    exit 1
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
  tail -n 100 "$launch_log" "$log_file" 2>/dev/null >&2 || true
  exit 1
fi

echo "Contrail is ready: $service_url/"
echo "Service log: $log_file"

if [[ "$smoke_test" == true ]]; then
  echo "Cross-platform deployment smoke test passed."
  exit 0
fi

cleanup_started_process=false
trap - EXIT INT TERM

if [[ "$open_browser" == true ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    open "$service_url/"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$service_url/" >/dev/null 2>&1 || true
  fi
fi
if [[ "$open_log" == true ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    open "$log_file"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$log_file" >/dev/null 2>&1 || true
  fi
fi

echo "Contrail continues running in the background (PID $server_pid)."
echo "Stop it with: $script_dir/stop_web.sh"
