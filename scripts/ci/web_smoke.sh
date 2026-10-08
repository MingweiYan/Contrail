#!/usr/bin/env bash

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
web_root="$repo_root/build/web"
artifact_dir="${WEB_SMOKE_ARTIFACT_DIR:-$repo_root/build/web-smoke}"
port="${WEB_SMOKE_PORT:-4173}"
base_path="${WEB_SMOKE_BASE_PATH:-/}"

if [[ "$base_path" != /* || "$base_path" != */ ]]; then
  echo "WEB_SMOKE_BASE_PATH must start and end with '/': $base_path" >&2
  exit 1
fi

if [[ ! -f "$web_root/index.html" ]]; then
  echo "Missing Web build output at $web_root" >&2
  exit 1
fi

if [[ -n "${CHROME_EXECUTABLE:-}" ]]; then
  chrome="$CHROME_EXECUTABLE"
else
  chrome="$(
    command -v google-chrome ||
      command -v google-chrome-stable ||
      command -v chromium ||
      command -v chromium-browser ||
      true
  )"
fi

if [[ -z "$chrome" || ! -x "$chrome" ]]; then
  echo "Chrome/Chromium executable not found." >&2
  exit 1
fi

mkdir -p "$artifact_dir"
server_log="$artifact_dir/server.log"
browser_log="$artifact_dir/browser.log"
dom_file="$artifact_dir/dom.html"
screenshot_file="$artifact_dir/screenshot.png"

serve_root="$web_root"
temporary_serve_root=""
if [[ "$base_path" != "/" ]]; then
  temporary_serve_root="$(mktemp -d)"
  relative_base="${base_path#/}"
  relative_base="${relative_base%/}"
  mkdir -p "$temporary_serve_root/$(dirname "$relative_base")"
  ln -s "$web_root" "$temporary_serve_root/$relative_base"
  serve_root="$temporary_serve_root"
fi

python3 -m http.server "$port" --bind 127.0.0.1 --directory "$serve_root" \
  >"$server_log" 2>&1 &
server_pid=$!
cleanup() {
  kill "$server_pid" 2>/dev/null || true
  if [[ -n "$temporary_serve_root" ]]; then
    rm -rf "$temporary_serve_root"
  fi
}
trap cleanup EXIT

url="http://127.0.0.1:$port$base_path"
for _ in $(seq 1 40); do
  if curl --fail --silent "$url" >/dev/null; then
    break
  fi
  sleep 0.25
done

if ! curl --fail --silent "$url" >/dev/null; then
  echo "Web server did not become ready." >&2
  cat "$server_log" >&2
  exit 1
fi

common_args=(
  --headless
  --no-sandbox
  --disable-gpu
  --hide-scrollbars
  --window-size=1280,800
  --virtual-time-budget=10000
)

routes=("" "#/statistics" "#/profile" "#/route-that-does-not-exist")
for route in "${routes[@]}"; do
  route_name="${route//#/hash-}"
  route_name="${route_name//\//_}"
  route_dom="$artifact_dir/dom-${route_name:-root}.html"
  if ! "$chrome" "${common_args[@]}" --dump-dom "$url$route" \
    >"$route_dom" 2>>"$browser_log"; then
    echo "Browser failed to load Web route: $route" >&2
    cat "$browser_log" >&2
    exit 1
  fi

  if ! grep -Eq '<flutter-view|flt-glass-pane' "$route_dom"; then
    echo "Flutter did not mount its root view for route: $route" >&2
    cat "$route_dom" >&2
    cat "$browser_log" >&2
    exit 1
  fi
done
cp "$artifact_dir/dom-root.html" "$dom_file"

"$chrome" "${common_args[@]}" --screenshot="$screenshot_file" "$url" \
  >>"$browser_log" 2>&1

if grep -Eq ' (404|500) ' "$server_log"; then
  echo "Web server reported failed static asset requests." >&2
  cat "$server_log" >&2
  exit 1
fi

echo "Web smoke test passed. Artifacts: $artifact_dir"
