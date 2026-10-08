#!/usr/bin/env bash

set -euo pipefail

base_ref="${1:-origin/main}"
repo_root="$(git rev-parse --show-toplevel)"
baseline_file="$repo_root/scripts/ci/analyzer_baseline.txt"

cd "$repo_root"

if ! git rev-parse --verify --quiet "$base_ref^{commit}" >/dev/null; then
  echo "Unable to resolve analyzer base ref: $base_ref" >&2
  exit 1
fi

mapfile -t changed_dart_files < <(
  {
    git diff --name-only --diff-filter=ACMR "$base_ref...HEAD" -- '*.dart'
    git diff --name-only --diff-filter=ACMR HEAD -- '*.dart'
    git ls-files --others --exclude-standard -- '*.dart'
  } | sort -u
)

if ((${#changed_dart_files[@]} > 0)); then
  echo "Checking formatting for changed Dart files:"
  printf '  %s\n' "${changed_dart_files[@]}"
  dart format --output=none --set-exit-if-changed "${changed_dart_files[@]}"
else
  echo "No changed Dart files to format-check."
fi

analyzer_output="$(mktemp)"
trap 'rm -f "$analyzer_output"' EXIT

set +e
dart analyze --format machine >"$analyzer_output"
analyzer_status=$?
set -e

# dart analyze exits 2 when it reports diagnostics. Other non-zero statuses
# mean the analyzer itself failed and must not be treated as baseline debt.
if [[ "$analyzer_status" -ne 0 && "$analyzer_status" -ne 2 ]]; then
  cat "$analyzer_output" >&2
  exit "$analyzer_status"
fi

if grep -Ev '^(ERROR|WARNING|INFO)\|' "$analyzer_output" | grep -q .; then
  echo "Analyzer returned output in an unexpected format:" >&2
  cat "$analyzer_output" >&2
  exit 1
fi

diagnostic_count="$(grep -Ec '^(ERROR|WARNING|INFO)\|' "$analyzer_output" || true)"
baseline_count="$(tr -d '[:space:]' <"$baseline_file")"

if [[ ! "$baseline_count" =~ ^[0-9]+$ ]]; then
  echo "Invalid analyzer baseline: $baseline_count" >&2
  exit 1
fi

echo "Analyzer diagnostics: $diagnostic_count (baseline maximum: $baseline_count)"
if ((diagnostic_count > baseline_count)); then
  echo "Analyzer debt increased. Fix the new diagnostics before merging." >&2
  cat "$analyzer_output" >&2
  exit 1
fi

if ((${#changed_dart_files[@]} == 0)); then
  exit 0
fi

declare -A changed_paths=()
for path in "${changed_dart_files[@]}"; do
  changed_paths["$repo_root/$path"]=1
done

changed_diagnostics="$(
  while IFS='|' read -r severity category code path line column length message; do
    if [[ -n "${changed_paths[$path]:-}" ]]; then
      printf '%s|%s|%s|%s|%s|%s|%s|%s\n' \
        "$severity" "$category" "$code" "$path" \
        "$line" "$column" "$length" "$message"
    fi
  done <"$analyzer_output"
)"

if [[ -n "$changed_diagnostics" ]]; then
  echo "Changed Dart files must have zero analyzer diagnostics:" >&2
  printf '%s\n' "$changed_diagnostics" >&2
  exit 1
fi

echo "Changed Dart files are analyzer-clean."
