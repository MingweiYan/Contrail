#!/usr/bin/env bash

set -euo pipefail

bundle_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$bundle_root/scripts/deploy_web.sh" --skip-build "$@"
