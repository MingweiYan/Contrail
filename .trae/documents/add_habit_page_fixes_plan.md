# 新增习惯页面修复 - 实施计划

## [ ] 任务1: 创建新分支
- **Priority**: P0
- **Depends On**: None
- **Description**: 创建一个新的 git 分支用于修复这些问题
- **Success Criteria**: 新分支创建成功并切换到该分支
- **Test Requirements**:
  - `programmatic` TR-1.1: git branch 命令显示新分支已创建
- **Notes**: 分支名称建议为 `fix/add-habit-page-issues`

## [ ] 任务2: 修复周期类型和目标类型选项的布局问题
- **Priority**: P1
- **Depends On**: 任务1
- **Description**: 修复周期类型下三个选项和目标类型下的选项文字显示成两行的问题，确保文字在一行内完整显示，不改变文字大小
- **Success Criteria**: 周期类型和目标类型的选项文字在一行内完整显示
- **Test Requirements**:
  - `human-judgment` TR-2.1: 周期类型选项（每日、每周、每月）在一行内显示
  - `human-judgment` TR-2.2: 目标类型选项（培养好习惯、戒掉坏习惯）在一行内显示
- **Notes**: 需要修改 add_habit_page.dart 中的 RadioListTile 布局，可能需要调整 padding 或使用 Expanded 等布局组件

## [ ] 任务3: 修复目标时间默认值为半小时
- **Priority**: P1
- **Depends On**: 任务1
- **Description**: 将默认目标时间从1小时改为30分钟
- **Success Criteria**: 新增习惯时默认目标时间为30分钟
- **Test Requirements**:
  - `programmatic` TR-3.1: add_habit_page.dart 中 _targetTimeMinutes 初始值为30
- **Notes**: 修改 add_habit_page.dart 第94行的初始值

## [ ] 任务4: 实现点击数字直接输入修改功能
- **Priority**: P1
- **Depends On**: 任务1
- **Description**: 为目标天数和目标时间的显示数字添加点击交互，点击后弹出输入框支持直接输入，同时限制输入值在合理范围内
- **Success Criteria**: 
  - 点击目标天数显示文字可以弹出输入框修改
  - 点击目标时间显示文字可以弹出输入框修改
  - 输入值被限制在合理范围内
- **Test Requirements**:
  - `human-judgment` TR-4.1: 点击目标天数数字可以输入修改
  - `human-judgment` TR-4.2: 点击目标时间数字可以输入修改
  - `programmatic` TR-4.3: 输入的值在最小和最大限制范围内
- **Notes**: 需要创建输入对话框组件，验证输入值

## [ ] 任务5: 修复习惯目标时间无法修改保存的问题
- **Priority**: P1
- **Depends On**: 任务1
- **Description**: 检查并修复目标时间无法正确保存到 Habit 对象的问题
- **Success Criteria**: 目标时间修改后能够正确保存
- **Test Requirements**:
  - `programmatic` TR-5.1: 检查 createHabit 方法是否正确处理目标时间
  - `programmatic` TR-5.2: 保存习惯后目标时间正确存储
- **Notes**: 需要检查 Habit 模型、HabitService 和 AddHabitPage 的保存逻辑

## [ ] 任务6: 实现右上角保存/更新功能
- **Priority**: P1
- **Depends On**: 任务1
- **Description**: 在页面右上角添加可点击的文字按钮，实现保存或更新习惯功能
- **Success Criteria**: 
  - 页面右上角显示「新增习惯」或「编辑习惯」文字
  - 点击文字可以触发保存功能
- **Test Requirements**:
  - `human-judgment` TR-6.1: 页面右上角有可点击的文字按钮
  - `human-judgment` TR-6.2: 点击按钮可以保存习惯
- **Notes**: 修改 AppBar 部分，添加 TextButton

## [ ] 任务7: 验证所有修复
- **Priority**: P0
- **Depends On**: 任务2-6
- **Description**: 全面测试所有修复是否正常工作
- **Success Criteria**: 所有功能正常工作
- **Test Requirements**:
  - `human-judgment` TR-7.1: 所有界面元素正确显示
  - `human-judgment` TR-7.2: 所有交互功能正常工作
  - `programmatic` TR-7.3: 运行应用无错误
