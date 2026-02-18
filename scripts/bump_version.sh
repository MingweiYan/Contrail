#!/bin/bash

# 脚本功能：自动递增 pubspec.yaml 中的版本号

# 读取当前版本号
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
if [ -z "$CURRENT_VERSION" ]; then
  echo "Error: Could not find version in pubspec.yaml"
  exit 1
fi

# 解析版本号和构建号
VERSION_PART=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_PART=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# 解析主版本、次版本、补丁版本
IFS='.' read -r -a VERSION_PARTS <<< "$VERSION_PART"
MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

# 递增补丁版本
NEW_PATCH=$((PATCH + 1))
NEW_VERSION_PART="$MAJOR.$MINOR.$NEW_PATCH"
NEW_BUILD_PART=$((BUILD_PART + 1))
NEW_VERSION="$NEW_VERSION_PART+$NEW_BUILD_PART"

# 更新 pubspec.yaml
sed -i '' "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml

# 输出结果
echo "Version bumped from $CURRENT_VERSION to $NEW_VERSION"
echo "New version: $NEW_VERSION"

# 返回新版本号
echo "$NEW_VERSION"
