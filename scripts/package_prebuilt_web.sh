#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

architecture=""
output_dir="$repo_root/dist"

usage() {
  cat <<'USAGE'
Package an existing native macOS Contrail build for GitHub Releases.

Usage: scripts/package_prebuilt_web.sh [options]

Options:
  --architecture <arm64|x64>  Package architecture (default: current machine)
  --output-dir <path>         Destination directory (default: dist)
  -h, --help                  Show this help

Run scripts/build_web.sh first to create build/web and the native
build/contrail-server executable.
USAGE
}

while (($# > 0)); do
  case "$1" in
    --architecture)
      [[ $# -ge 2 ]] || { echo "Missing value for --architecture" >&2; exit 64; }
      architecture="$2"
      shift 2
      ;;
    --output-dir)
      [[ $# -ge 2 ]] || { echo "Missing value for --output-dir" >&2; exit 64; }
      output_dir="$2"
      shift 2
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

if [[ -z "$architecture" ]]; then
  case "$(uname -m)" in
    arm64|aarch64) architecture="arm64" ;;
    x86_64|amd64) architecture="x64" ;;
    *)
      echo "Unsupported macOS architecture: $(uname -m)" >&2
      exit 64
      ;;
  esac
fi
if [[ "$architecture" != "arm64" && "$architecture" != "x64" ]]; then
  echo "Architecture must be arm64 or x64: $architecture" >&2
  exit 64
fi

for command_name in ditto file; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required packaging command is not available: $command_name" >&2
    exit 69
  fi
done

if [[ "$output_dir" != /* ]]; then
  output_dir="$repo_root/$output_dir"
fi

server_binary="$repo_root/build/contrail-server"
web_root="$repo_root/build/web"
if [[ ! -x "$server_binary" ]]; then
  echo "Native Contrail server is missing or not executable: $server_binary" >&2
  exit 66
fi
if [[ ! -f "$web_root/index.html" ]]; then
  echo "Contrail Web build is missing: $web_root/index.html" >&2
  exit 66
fi

binary_description="$(file "$server_binary")"
if [[ "$binary_description" != *"Mach-O"* ]]; then
  echo "Expected a macOS Mach-O executable, got: $binary_description" >&2
  exit 65
fi
if [[ "$architecture" == "arm64" && "$binary_description" != *"arm64"* ]]; then
  echo "Expected an arm64 executable, got: $binary_description" >&2
  exit 65
fi
if [[ "$architecture" == "x64" && "$binary_description" != *"x86_64"* ]]; then
  echo "Expected an x86_64 executable, got: $binary_description" >&2
  exit 65
fi

bundle_name="Contrail-macOS-$architecture"
bundle_dir="$output_dir/$bundle_name"
archive_path="$output_dir/$bundle_name.zip"
if [[ -e "$bundle_dir" || -e "$archive_path" ]]; then
  echo "Release output already exists: $bundle_dir or $archive_path" >&2
  exit 73
fi

mkdir -p "$bundle_dir/build" "$bundle_dir/scripts"
cp -R "$web_root" "$bundle_dir/build/web"
cp "$server_binary" "$bundle_dir/build/contrail-server"
cp "$repo_root/scripts/deploy_web.sh" "$bundle_dir/scripts/deploy_web.sh"
cp "$repo_root/scripts/stop_web.sh" "$bundle_dir/scripts/stop_web.sh"
cp "$repo_root/scripts/release/start_prebuilt_web_macos.command" \
  "$bundle_dir/Start Contrail.command"
cp "$repo_root/scripts/release/stop_prebuilt_web_macos.command" \
  "$bundle_dir/Stop Contrail.command"
cp "$repo_root/scripts/release/PREBUILT_README.txt" "$bundle_dir/README.txt"
cp "$repo_root/LICENSE" "$bundle_dir/LICENSE"
chmod +x \
  "$bundle_dir/build/contrail-server" \
  "$bundle_dir/scripts/deploy_web.sh" \
  "$bundle_dir/scripts/stop_web.sh" \
  "$bundle_dir/Start Contrail.command" \
  "$bundle_dir/Stop Contrail.command"

ditto -c -k --keepParent "$bundle_dir" "$archive_path"
echo "Created prebuilt release bundle: $archive_path"
