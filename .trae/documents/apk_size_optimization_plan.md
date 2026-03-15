# Contrail APK 安装包大小优化计划

## 问题现状
当前安装包大小接近 100MB，远超常规应用的合理范围（一般应用 10-30MB）。

## 根本原因分析

### 1. **未使用的图片资源占用**（约 6.8MB）
- `assets/icons/icon.png`: 2.1MB - 代码中未使用
- `assets/icons/icon.bk.png`: 2.3MB - 备份文件，不应该打包
- `assets/images/cover.png`: 2.4MB - 代码中未使用（已使用 cover.svg 替代）
- 总计：约 6.8MB

### 2. **不必要的文件被打包**
- `assets/contrail_backup_1767246746157.json`: 备份文件，不应该打包

### 3. **缺少代码混淆和资源压缩**
- `android/app/build.gradle.kts` 中没有启用 `minifyEnabled` 和 `shrinkResources`
- 大量未使用的代码和资源被保留

---

## 优化任务列表

### [ ] 任务 1：删除所有未使用的资源文件
- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 删除 `assets/icons/icon.bk.png` 备份文件
  - 删除 `assets/icons/icon.png`（代码中未使用）
  - 删除 `assets/images/cover.png`（代码中已使用 cover.svg 替代）
  - 删除 `assets/contrail_backup_*.json` 备份文件
  - 保留 `assets/images/cover.svg`（正在使用中）
  - 保留 `assets/icons/` 目录结构（防止 pubspec.yaml 引用路径报错）
- **Success Criteria**:
  - 所有未使用文件被删除
  - 应用可以正常启动和运行
  - splash screen 正常显示 cover.svg
- **Test Requirements**:
  - `programmatic` TR-1.1: 目标文件被成功删除
  - `human-judgment` TR-1.2: 应用可以正常启动，splash screen 显示正常
- **Notes**: 预计减少 6.8MB+

### [ ] 任务 2：启用代码混淆和资源压缩
- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 在 `android/app/build.gradle.kts` 的 release buildType 中启用：
    - `minifyEnabled = true`
    - `shrinkResources = true`
  - 添加必要的 ProGuard/R8 规则（如果需要）
- **Success Criteria**:
  - Release 构建启用了混淆和压缩
  - 应用可以正常构建和运行
- **Test Requirements**:
  - `programmatic` TR-2.1: build.gradle.kts 配置正确
  - `human-judgment` TR-2.2: APK 体积明显减小，应用功能正常
- **Notes**: 预计减少 20-50MB（取决于未使用代码/资源量）

---

## 预期优化效果

| 优化项 | 预计减少体积 | 优先级 |
|--------|-------------|--------|
| 删除未使用资源 | ~6.8MB | P0 |
| 代码混淆+资源压缩 | 20-50MB | P0 |

**保守估计：从 ~100MB 优化到 ~40-70MB**

## 图片使用情况检查结果

✅ **正在使用的图片：**
- `assets/images/cover.svg` - 在 splash_screen.dart 中使用

❌ **未使用的图片（可以安全删除）：**
- `assets/icons/icon.png` - 代码中无引用
- `assets/icons/icon.bk.png` - 备份文件
- `assets/images/cover.png` - 已被 SVG 替代
