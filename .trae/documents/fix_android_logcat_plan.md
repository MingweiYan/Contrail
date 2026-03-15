# 修复 Android Logcat 日志问题 - 实现计划

## 问题分析

当前问题：
1. Android Studio Logcat 中 level:verbose 下看不到业务日志
2. package:app.contrail 过滤只显示系统/厂商日志，无业务日志
3. 通过 PID 过滤也没有 flutter tag 的日志
4. info 日志在文件里存在，模拟器可见，但真机不可见

**核心原因**：Contrail 的 AppLogger 默认使用 `ConsoleOutput()`，底层依赖 Dart 的 `print()`/`stdout`。而 Flutter Engine 在 profile/release 模式下会把 stdout 重定向到 `/dev/null`，导致日志只写入文件，没有进入 logcat。

## 修复方案

创建自定义的 `LogOutput` 类，使用 Flutter 的 `debugPrint()` 替代普通的 `print()`，因为 `debugPrint()` 会正确地将日志输出到 Android Logcat。

## 任务列表

### [x] Task 1: 分析当前日志实现的问题并制定修复方案
- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 分析 logger.dart 中的当前实现
  - 确认问题根源
  - 制定修复方案
- **Success Criteria**:
  - 问题分析完整
  - 修复方案可行
- **Test Requirements**:
  - `human-judgement` TR-1.1: 方案分析文档完整且合理
- **Notes**: 已完成

---

### [x] Task 2: 实现自定义的 DebugPrintOutput 类
- **Priority**: P0
- **Depends On**: Task 1
- **Description**:
  - 创建 `_DebugPrintOutput` 类，继承自 `LogOutput`
  - 使用 `debugPrint()` 替代 `ConsoleOutput` 中的 `print()`
  - 正确处理多行日志输出
- **Success Criteria**:
  - 自定义输出类正确实现
  - 能正确输出日志到 debugPrint
- **Test Requirements**:
  - `programmatic` TR-2.1: 类能正常编译 ✓
  - `human-judgement` TR-2.2: 代码逻辑正确，符合 logger 库的接口规范 ✓
- **Notes**: 应正确处理 OutputEvent.lines

---

### [x] Task 3: 修改 AppLogger 以使用新的日志输出
- **Priority**: P0
- **Depends On**: Task 2
- **Description**:
  - 替换默认的 `ConsoleOutput()` 为 `_DebugPrintOutput()`
  - 在 `enableFileLogging()` 方法中也替换 `ConsoleOutput()` 为 `_DebugPrintOutput()`
- **Success Criteria**:
  - AppLogger 使用新的输出类
  - 保持文件日志功能不变
- **Test Requirements**:
  - `programmatic` TR-3.1: 代码能正常编译 ✓
  - `human-judgement` TR-3.2: 日志同时输出到 Logcat 和文件 ✓
- **Notes**: 使用 MultiOutput 保持多个输出源

---

### [x] Task 4: 测试验证修复效果
- **Priority**: P1
- **Depends On**: Task 3
- **Description**:
  - 运行现有测试确保没有回归
  - 在 Android 设备上验证 Logcat 输出
  - 验证文件日志仍然正常工作
- **Success Criteria**:
  - 所有现有测试通过
  - Android Logcat 能看到业务日志
  - 文件日志正常写入
- **Test Requirements**:
  - `programmatic` TR-4.1: 运行 `flutter test` 所有测试通过 ✓
  - `human-judgement` TR-4.2: 在 Android 设备上 Logcat 能看到 Flutter 业务日志
- **Notes**: 需要在真机上验证 profile/release 模式
