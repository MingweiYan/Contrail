GitHub Actions 方案：自动构建并发布 Android APK 到 GitHub Releases

目标
- 在每次触发时自动构建 Flutter Android APK（release）
- 基于代码中的当前版本号生成发行版本（新建 GitHub Release）
- 将已签名的 APK 上传为 Release 资产，命名中包含版本信息

关键假设与约束
- 项目为 Flutter 应用（仓库已存在 scripts/release_android.sh）
- Android release 构建需要签名；我们在 CI 中用 GitHub Secrets 提供签名信息
- 版本号来源于 pubspec.yaml 的 version 字段（形如 1.2.3+45）
- 不在 CI 中修改版本号；而是“根据当前版本创建对应 Release”

版本与发布策略
- 解析 pubspec.yaml 中的 version，拆分为：
  - VERSION_NAME = 主版本（例如 1.2.3）
  - BUILD_NUMBER = 构建号（例如 45）
- Git tag 使用 v{VERSION_NAME}（例如 v1.2.3）
- Release 名称使用 v{VERSION_NAME}+{BUILD_NUMBER}（例如 v1.2.3+45）
- 若同名 tag 已存在：在 CI 内附加 .${{ github.run_number }} 以避免冲突（例如 v1.2.3.123）

仓库配置与密钥
- 在仓库 Settings → Secrets and variables → Actions 中新增以下 Secrets：
  - ANDROID_KEYSTORE_BASE64：将 release keystore 文件 base64 编码后的字符串
  - ANDROID_KEYSTORE_PASSWORD：keystore 密码
  - ANDROID_KEY_ALIAS：密钥别名
  - ANDROID_KEY_PASSWORD：密钥密码
- Workflow 需要 contents: write 权限以创建 Release

将新增的工作流文件
- .github/workflows/android-release.yml

Workflow 设计（概要）
1) 触发条件
   - 手动触发：workflow_dispatch
   - 推送到 main 分支触发：push.branches = [main]

2) 运行环境
   - ubuntu-latest
   - 设置 Java 17、Android SDK、Flutter（使用官方/业界通用 Actions）
   - 缓存 pub 与 Gradle

3) 版本解析
   - 从 pubspec.yaml 读取 version 行
   - 计算 TAG_NAME 与 RELEASE_NAME 并写入 GITHUB_ENV

4) 签名配置
   - 将 ANDROID_KEYSTORE_BASE64 解码为 android/app/release.keystore
   - 生成 android/key.properties（或等效环境变量）以供 Gradle 读取

5) 构建
   - flutter pub get
   - flutter build apk --release
   - 产物路径：build/app/outputs/flutter-apk/app-release.apk

6) 创建 Release 并上传资产
   - 使用 softprops/action-gh-release 创建或更新 Release
   - 指定 tag_name 与 name
   - 上传 APK 并重命名为 app-${RELEASE_NAME}.apk

参考工作流 YAML（示例）
（后续实现阶段将按此骨架落地到 .github/workflows/android-release.yml）

name: Android Release
on:
  workflow_dispatch:
  push:
    branches: [ "main" ]

permissions:
  contents: write

jobs:
  build-and-release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"

      - name: Setup Android SDK
        uses: android-actions/setup-android@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: "stable"
          cache: true

      - name: Cache Gradle
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: |
            ${{ runner.os }}-gradle-

      - name: Cache Pub
        uses: actions/cache@v4
        with:
          path: ~/.pub-cache
          key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
          restore-keys: |
            ${{ runner.os }}-pub-

      - name: Derive version from pubspec.yaml
        id: version
        run: |
          RAW=$(grep '^version:' pubspec.yaml | awk '{print $2}')
          if [ -z "$RAW" ]; then
            echo "version not found in pubspec.yaml"
            exit 1
          fi
          VERSION_NAME="${RAW%%+*}"
          BUILD_NUMBER="${RAW#*+}"
          TAG_NAME="v${VERSION_NAME}"
          RELEASE_NAME="v${VERSION_NAME}+${BUILD_NUMBER}"
          # 若 tag 已存在，则附加运行号避免冲突
          if git rev-parse -q --verify "refs/tags/${TAG_NAME}" >/dev/null; then
            TAG_NAME="${TAG_NAME}.${GITHUB_RUN_NUMBER}"
            RELEASE_NAME="${RELEASE_NAME}.${GITHUB_RUN_NUMBER}"
          fi
          echo "VERSION_NAME=$VERSION_NAME" >> $GITHUB_ENV
          echo "BUILD_NUMBER=$BUILD_NUMBER" >> $GITHUB_ENV
          echo "TAG_NAME=$TAG_NAME" >> $GITHUB_ENV
          echo "RELEASE_NAME=$RELEASE_NAME" >> $GITHUB_ENV

      - name: Prepare keystore
        env:
          ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          ANDROID_KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
          ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
        run: |
          mkdir -p android/app
          echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > android/app/release.keystore
          cat > android/key.properties <<EOF
          storePassword=$ANDROID_KEYSTORE_PASSWORD
          keyPassword=$ANDROID_KEY_PASSWORD
          keyAlias=$ANDROID_KEY_ALIAS
          storeFile=release.keystore
          EOF

      - name: Flutter pub get
        run: flutter pub get

      - name: Build APK (release)
        run: flutter build apk --release

      - name: Create Release and Upload APK
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ env.TAG_NAME }}
          name: ${{ env.RELEASE_NAME }}
          files: |
            build/app/outputs/flutter-apk/app-release.apk
          fail_on_unmatched_files: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

与现有脚本的关系
- 当前有 scripts/release_android.sh（包含 flutter pub get 等）。为减少耦合与对 Runner 环境的额外依赖，工作流采用“内联命令”执行构建；后续可视需要改为直接调用该脚本。

验证与验收
- 手动触发 workflow_dispatch，查看 Job 输出：
  - 版本解析步骤是否得到 TAG_NAME 与 RELEASE_NAME
  - 构建是否成功生成 app-release.apk
  - Release 是否在仓库的 Releases 页面生成，名称与 tag 符合约定
  - 资产是否签名（可下载后用 apksigner 或 jarsigner 验证）

失败场景与对策
- 未配置 Secrets：准备 keystore 步骤失败 → 在仓库 Secrets 中补齐
- pubspec.yaml 未包含 version：工作流失败并给出错误 → 补充版本字段
- tag 已存在：自动追加运行号避免冲突
- Gradle/SDK 版本不兼容：调整 Java 版本或 Android SDK 平台版本

后续可选增强
- 自动生成变更日志（如使用 release-please）
- 同时构建并上传 AAB
- 多风味（flavor）与多渠道包
- 产物校验与 VirusTotal 扫描

交付标准
- 合并工作流文件后，触发一次构建，成功生成新的 Release，并包含命名为 app-{RELEASE_NAME}.apk 的资产
