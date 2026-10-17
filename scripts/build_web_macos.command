#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v flutter >/dev/null 2>&1; then
  login_shell="${SHELL:-/bin/zsh}"
  if [[ -x "$login_shell" ]]; then
    flutter_path="$($login_shell -lic 'command -v flutter' 2>/dev/null | tail -n 1 || true)"
    if [[ -n "$flutter_path" && -x "$flutter_path" ]]; then
      export PATH="$(dirname "$flutter_path"):$PATH"
    fi
  fi
fi

exec "$script_dir/build_web.sh" "$@"
