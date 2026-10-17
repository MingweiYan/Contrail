#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
runtime_dir="${CONTRAIL_RUNTIME_DIR:-$repo_root/runtime}"
open_log=false

usage() {
  cat <<'USAGE'
Stop the background Contrail Web service started by deploy_web.sh.

Usage: scripts/stop_web.sh [options]

Options:
  --runtime-dir <path>  Runtime directory used at startup
  --open-log            Open the service log after stopping
  -h, --help            Show this help
USAGE
}

while (($# > 0)); do
  case "$1" in
    --runtime-dir)
      [[ $# -ge 2 ]] || { echo "Missing value for --runtime-dir" >&2; exit 64; }
      runtime_dir="$2"
      shift 2
      ;;
    --open-log)
      open_log=true
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

if [[ "$runtime_dir" != /* ]]; then
  runtime_dir="$repo_root/$runtime_dir"
fi
pid_file="$runtime_dir/contrail.pid"
url_file="$runtime_dir/contrail.url"
log_file="${CONTRAIL_LOG_FILE:-$runtime_dir/contrail.log}"
if [[ "$log_file" != /* ]]; then
  log_file="$repo_root/$log_file"
fi
server_binary="$repo_root/build/contrail-server"

if [[ ! -f "$pid_file" ]]; then
  echo "Contrail is not running (no PID file at $pid_file)."
  exit 0
fi
server_pid="$(tr -d '[:space:]' <"$pid_file")"
if [[ ! "$server_pid" =~ ^[0-9]+$ ]]; then
  echo "Removing invalid Contrail PID file: $pid_file" >&2
  rm -f "$pid_file" "$url_file"
  exit 1
fi
if ! kill -0 "$server_pid" 2>/dev/null; then
  echo "Contrail is already stopped; removing stale runtime state."
  rm -f "$pid_file" "$url_file"
  exit 0
fi

command_line="$(ps -p "$server_pid" -o command= 2>/dev/null || true)"
if [[ "$command_line" != *"$server_binary"* ]]; then
  echo "PID $server_pid does not belong to this Contrail server; it was not stopped." >&2
  rm -f "$pid_file" "$url_file"
  exit 1
fi

echo "==> Stopping Contrail (PID $server_pid)"
kill "$server_pid"
for _ in {1..100}; do
  if ! kill -0 "$server_pid" 2>/dev/null; then
    rm -f "$pid_file" "$url_file"
    echo "Contrail stopped."
    if [[ "$open_log" == true && -f "$log_file" ]]; then
      if [[ "$(uname -s)" == "Darwin" ]]; then
        open "$log_file"
      elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$log_file" >/dev/null 2>&1 || true
      fi
    fi
    exit 0
  fi
  sleep 0.1
done

echo "Contrail did not stop within 10 seconds; forcing termination." >&2
kill -KILL "$server_pid" 2>/dev/null || true
rm -f "$pid_file" "$url_file"
