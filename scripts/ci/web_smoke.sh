#!/usr/bin/env bash

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
web_root="$repo_root/build/web"
artifact_dir="${WEB_SMOKE_ARTIFACT_DIR:-$repo_root/build/web-smoke}"
port="${WEB_SMOKE_PORT:-4173}"

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

python3 -m http.server "$port" --bind 127.0.0.1 --directory "$web_root" \
  >"$server_log" 2>&1 &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true' EXIT

url="http://127.0.0.1:$port/"
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

if ! "$chrome" "${common_args[@]}" --dump-dom "$url" \
  >"$dom_file" 2>"$browser_log"; then
  echo "Browser failed to load the Web build." >&2
  cat "$browser_log" >&2
  exit 1
fi

if ! grep -Eq '<flutter-view|flt-glass-pane' "$dom_file"; then
  echo "Flutter did not mount its root view." >&2
  cat "$dom_file" >&2
  cat "$browser_log" >&2
  exit 1
fi

"$chrome" "${common_args[@]}" --screenshot="$screenshot_file" "$url" \
  >>"$browser_log" 2>&1

echo "Web smoke test passed. Artifacts: $artifact_dir"
