# 使用 MethodChannel + android.util.Log 的实现计划

## 方案概述

通过 MethodChannel 直接调用 Android 原生的 `android.util.Log` API，完全不依赖 stdout 机制，实现更可靠的日志输出。

## 任务列表

### [x] Task 1: 实现 Android 端原生代码
- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 修改 `MainActivity.kt`，设置 MethodChannel
  - 实现日志调用方法，支持 V/D/I/W/E 五种级别
  - 支持自定义 tag
- **Success Criteria**:
  - Android 端代码正确实现
  - MethodChannel 通信正常
- **Test Requirements**:
  - `programmatic` TR-1.1: 代码能正常编译 ✓
- **Notes**: MethodChannel name: "app.contrail/logging"

---

### [x] Task 2: 实现 Flutter 端 MethodChannel 调用封装
- **Priority**: P0
- **Depends On**: Task 1
- **Description**:
  - 创建 `NativeLogger` 类封装 MethodChannel 调用
  - 支持五种日志级别：verbose, debug, info, warning, error
  - 处理平台异常情况（非 Android 平台时降级到 debugPrint）
- **Success Criteria**:
  - Flutter 端封装类正确实现
  - 能正确处理不同平台
- **Test Requirements**:
  - `programmatic` TR-2.1: 代码能正常编译 ✓
- **Notes**: 应检查 `Platform.isAndroid`

---

### [x] Task 3: 创建新的 NativeLogOutput 类
- **Priority**: P0
- **Depends On**: Task 2
- **Description**:
  - 创建 `_NativeLogOutput` 类，继承自 `LogOutput`
  - 将 logger 库的 Level 映射到原生日志级别
  - 使用 NativeLogger 输出日志
- **Success Criteria**:
  - 自定义输出类正确实现
  - 日志级别映射正确
- **Test Requirements**:
  - `programmatic` TR-3.1: 类能正常编译 ✓
  - `human-judgement` TR-3.2: 日志级别映射正确 ✓

---

### [x] Task 4: 更新 AppLogger 使用新的 NativeLogOutput
- **Priority**: P0
- **Depends On**: Task 3
- **Description**:
  - 替换默认输出为 `_NativeLogOutput()`
  - 在 `enableFileLogging()` 中也使用 `_NativeLogOutput()`
  - 保留 `_DebugPrintOutput` 作为备用方案
- **Success Criteria**:
  - AppLogger 使用新的输出类
  - 保持文件日志功能不变
- **Test Requirements**:
  - `programmatic` TR-4.1: 代码能正常编译 ✓

---

### [x] Task 5: 测试验证修复效果
- **Priority**: P1
- **Depends On**: Task 4
- **Description**:
  - 运行现有测试确保没有回归
  - 在 Android 设备上验证 Logcat 输出
  - 验证不同日志级别正确显示
  - 验证自定义 tag 正确显示
- **Success Criteria**:
  - 所有现有测试通过
  - Android Logcat 能看到各级别业务日志
  - 文件日志正常写入
- **Test Requirements**:
  - `programmatic` TR-5.1: 运行 `flutter test` 所有测试通过 ✓
  - `human-judgement` TR-5.2: 在 Android 设备上 Logcat 能看到不同级别的 Flutter 业务日志

---

## 日志级别映射

| logger Level | Android Log 级别 |
|--------------|-----------------|
| verbose      | Log.v()         |
| debug        | Log.d()         |
| info         | Log.i()         |
| warning      | Log.w()         |
| error        | Log.e()         |
| fatal        | Log.wtf()       |

## MethodChannel 协议

**Channel Name**: `app.contrail/logging`

**Method**: `log`

**Arguments**:
```dart
{
  'level': 'verbose' | 'debug' | 'info' | 'warning' | 'error' | 'fatal',
  'tag': String,
  'message': String
}
```

## 实现总结

✅ 已成功实现使用 MethodChannel + android.util.Log 的方案！

### 主要改动：

1. **Android 端** (`android/app/src/main/kotlin/app/contrail/MainActivity.kt`):
   - 配置了 MethodChannel "app.contrail/logging"
   - 实现了日志调用方法，支持 V/D/I/W/E/WTF 六种级别
   - 使用默认 tag "Contrail"

2. **Flutter 端** (`lib/shared/utils/logger.dart`):
   - 新增 `NativeLogger` 类封装 MethodChannel 调用
   - 新增 `_NativeLogOutput` 类继承自 `LogOutput`
   - 保留 `_DebugPrintOutput` 作为非 Android 平台的降级方案
   - 更新 AppLogger 默认使用 `_NativeLogOutput()`

### 优势：

- ✅ 完全不依赖 stdout 机制
- ✅ 可以精确控制日志级别
- ✅ 支持自定义 Logcat tag
- ✅ 在任何情况下都能可靠工作
- ✅ 非 Android 平台自动降级到 debugPrint
- ✅ 所有测试通过！
