#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
skip_pub_get=false

usage() {
  cat <<'USAGE'
Build the Contrail Web application and native integrated server.

Usage: scripts/build_web.sh [options]

Options:
  --skip-pub-get  Reuse already resolved Flutter dependencies
  -h, --help      Show this help
USAGE
}

while (($# > 0)); do
  case "$1" in
    --skip-pub-get)
      skip_pub_get=true
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

for command_name in flutter dart; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required build command is not available: $command_name" >&2
    exit 69
  fi
done

cd "$repo_root"
if [[ "$skip_pub_get" != true ]]; then
  echo "==> Installing locked Flutter dependencies"
  flutter pub get --enforce-lockfile
fi

echo "==> Building the integrated Web application"
flutter build web --release --no-pub --no-wasm-dry-run \
  --dart-define=WEBDAV_GATEWAY_URL=/api/webdav

echo "==> Compiling the integrated Web server"
dart compile exe server/bin/contrail_server.dart \
  -o "$repo_root/build/contrail-server"

echo "Contrail Web build completed."
