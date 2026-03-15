# Contrail 代码库改进 - The Implementation Plan (Decomposed and Prioritized Task List)

## [ ] Task 1: 修正拼写错误
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 修正injection_container.dart中habitManagemetnService的拼写错误
  - 确保所有相关引用都同步更新
- **Acceptance Criteria Addressed**: [AC-1, AC-4]
- **Test Requirements**:
  - `programmatic` TR-1.1: 编译检查无错误
  - `programmatic` TR-1.2: 运行flutter analyze无警告
- **Notes**: 低风险，立即可以修复

## [ ] Task 2: 消除未使用的导入和变量
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 运行flutter analyze识别未使用的导入
  - 逐一清理所有文件中的未使用导入
  - 清理未使用的局部变量和字段
- **Acceptance Criteria Addressed**: [AC-1, AC-4]
- **Test Requirements**:
  - `programmatic` TR-2.1: flutter analyze零警告
  - `programmatic` TR-2.2: 所有测试通过
- **Notes**: analysis_options.yaml已配置相关规则

## [ ] Task 3: 优化CustomCirclePainter的shouldRepaint方法
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 修改clock_widget.dart中CustomCirclePainter的shouldRepaint方法
  - 只在相关属性变化时才重绘，而不是总是返回true
- **Acceptance Criteria Addressed**: [AC-1, AC-4]
- **Test Requirements**:
  - `programmatic` TR-3.1: 时钟功能正常显示
  - `human-judgement` TR-3.2: 动画流畅无卡顿
- **Notes**: 性能优化，无功能改变

## [ ] Task 4: 按模块组织依赖注入注册
- **Priority**: P1
- **Depends On**: Task 1
- **Description**: 
  - 将injection_container.dart中的依赖注册按模块分组
  - 创建私有辅助方法分别初始化不同层的依赖
  - 保持现有依赖注册顺序不变
- **Acceptance Criteria Addressed**: [AC-2, AC-3, AC-4]
- **Test Requirements**:
  - `programmatic` TR-4.1: 应用正常启动
  - `programmatic` TR-4.2: 所有依赖可以正常解析
  - `programmatic` TR-4.3: 所有功能测试通过
- **Notes**: 提高代码可读性，不改变功能

## [ ] Task 5: 提取重复代码为公共方法
- **Priority**: P1
- **Depends On**: None
- **Description**: 
  - 识别代码库中的重复代码模式
  - 重点关注HabitProvider中的重复模式
  - 提取为私有辅助方法
- **Acceptance Criteria Addressed**: [AC-1, AC-3, AC-4]
- **Test Requirements**:
  - `programmatic` TR-5.1: 所有功能测试通过
  - `programmatic` TR-5.2: dart_code_metrics的duplicate_code规则检查通过
- **Notes**: 消除代码重复，提高可维护性

## [ ] Task 6: 为核心服务创建抽象接口
- **Priority**: P1
- **Depends On**: None
- **Description**: 
  - 为NotificationService创建接口
  - 为HabitStatisticsService创建接口
  - 为Theme相关功能创建接口
  - 更新依赖注入注册使用接口类型
- **Acceptance Criteria Addressed**: [AC-2, AC-3, AC-4]
- **Test Requirements**:
  - `programmatic` TR-6.1: 应用正常编译运行
  - `programmatic` TR-6.2: 所有功能测试通过
  - `human-judgement` TR-6.3: 依赖注入使用接口而非具体类
- **Notes**: 应用依赖倒置原则，提高可测试性

## [ ] Task 7: 统一错误处理机制
- **Priority**: P2
- **Depends On**: None
- **Description**: 
  - 审查现有错误处理代码
  - 确保错误信息一致且用户友好
  - 添加必要的日志记录
- **Acceptance Criteria Addressed**: [AC-2, AC-3, AC-4]
- **Test Requirements**:
  - `programmatic` TR-7.1: 所有功能测试通过
  - `human-judgement` TR-7.2: 错误消息格式一致
- **Notes**: 改善用户体验和调试能力

## [ ] Task 8: 优化长方法，提取辅助函数
- **Priority**: P2
- **Depends On**: None
- **Description**: 
  - 识别超长方法（超过50行）
  - 提取逻辑清晰的辅助函数
  - 使用提前返回模式减少嵌套
- **Acceptance Criteria Addressed**: [AC-1, AC-3, AC-4]
- **Test Requirements**:
  - `programmatic` TR-8.1: 所有功能测试通过
  - `human-judgement` TR-8.2: 方法长度合理，职责单一
- **Notes**: 提高代码可读性和可维护性

## [ ] Task 9: 改善代码注释和文档
- **Priority**: P2
- **Depends On**: None
- **Description**: 
  - 为公共API添加文档注释
  - 清理过时的注释
  - 确保复杂逻辑有清晰的解释
- **Acceptance Criteria Addressed**: [AC-1, AC-3]
- **Test Requirements**:
  - `programmatic` TR-9.1: 所有功能测试通过
  - `human-judgement` TR-9.2: 关键API有文档注释
- **Notes**: 提高代码可理解性

## [ ] Task 10: 代码格式化和样式统一
- **Priority**: P3
- **Depends On**: None
- **Description**: 
  - 运行dart format格式化所有代码
  - 确保代码风格一致
- **Acceptance Criteria Addressed**: [AC-1, AC-4]
- **Test Requirements**:
  - `programmatic` TR-10.1: dart format无修改提示
  - `programmatic` TR-10.2: 所有功能测试通过
- **Notes**: 纯格式化，不改变逻辑
