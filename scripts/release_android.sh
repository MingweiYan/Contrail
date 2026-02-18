#!/usr/bin/env bash
set -euo pipefail

APP_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$APP_DIR"

FLUTTER_BIN=${FLUTTER_BIN:-flutter}

# 基础构建步骤：清理 -> 更新依赖 -> 构建 release APK
$FLUTTER_BIN clean
$FLUTTER_BIN pub get
$FLUTTER_BIN build apk --release --output="$APP_DIR/build/app/outputs/flutter-apk/contrail.apk"

# 输出构建产物路径
echo "Built: $APP_DIR/build/app/outputs/flutter-apk/contrail.apk"

