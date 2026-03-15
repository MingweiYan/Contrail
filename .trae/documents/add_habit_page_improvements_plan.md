# 新增习惯页面改进 - 实现计划

## [x] 任务 1: 修复周期类型和目标类型选项的布局问题
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 修复周期类型选项（每日、每周、每月）和目标类型选项（培养好习惯、戒掉坏习惯）的文字换行问题
  - 确保文字可以在一行内完整显示，不改变文字大小
  - 调整 RadioListTile 的布局或约束，确保水平空间足够
- **Success Criteria**:
  - 所有选项文字在一行内完整显示
  - 没有文字换行问题
  - 布局美观且符合设计规范
- **Test Requirements**:
  - `programmatic` TR-1.1: 在设备上运行应用，打开新增习惯页面，验证周期类型和目标类型的选项文字是否在一行内显示
  - `human-judgement` TR-1.2: 检查布局是否美观，文字大小是否保持不变
- **Notes**: 可能需要使用 Wrap、Flexible、Expanded 或调整 padding/margin 来解决布局问题

## [x] 任务 2: 目标天数和目标时间支持点击数字输入修改
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 为目标天数的显示文本添加点击事件，点击后弹出输入框允许直接输入数字
  - 为目标时间的显示文本添加点击事件，点击后弹出输入框允许直接输入数字
  - 限制输入的数字在合理范围内（天数根据周期类型，时间在5分钟到最大限制之间）
- **Success Criteria**:
  - 点击目标天数文本可以打开输入对话框
  - 点击目标时间文本可以打开输入对话框
  - 输入值会被限制在合理范围内
- **Test Requirements**:
  - `programmatic` TR-2.1: 点击目标天数文本，验证是否弹出输入对话框
  - `programmatic` TR-2.2: 输入超出范围的值，验证是否被正确限制
  - `human-judgement` TR-2.3: 检查用户体验是否流畅自然

## [x] 任务 3: 修复默认目标时间为半小时并正确保存
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 修改默认目标时间从 60 分钟改为 30 分钟
  - 确保目标时间能够正确保存到 Habit 对象中
  - 确保在编辑习惯时能够正确加载已保存的目标时间
- **Success Criteria**:
  - 新建习惯时，默认目标时间为 30 分钟
  - 修改后的目标时间能够正确保存
  - 编辑习惯时能够正确加载已保存的目标时间
- **Test Requirements**:
  - `programmatic` TR-3.1: 新建一个习惯，验证默认目标时间是否为 30 分钟
  - `programmatic` TR-3.2: 修改目标时间后保存，然后编辑该习惯，验证目标时间是否正确加载
  - `human-judgement` TR-3.3: 检查保存和加载的流程是否正常

## [x] 任务 4: 右上角标题文字支持点击保存
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 将右上角的「添加习惯」/「编辑习惯」文字改为可点击的 TextButton
  - 点击后调用保存功能，与底部保存按钮功能相同
- **Success Criteria**:
  - 右上角的文字是可点击的按钮
  - 点击后能够正确保存或更新习惯
- **Test Requirements**:
  - `programmatic` TR-4.1: 点击右上角的保存按钮，验证是否正常保存习惯
  - `programmatic` TR-4.2: 编辑习惯时，点击右上角按钮，验证是否正常更新习惯
  - `human-judgement` TR-4.3: 检查按钮样式是否与设计一致
