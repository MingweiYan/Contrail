# 项目冗余代码清理执行计划

## 1. 执行前准备

### 1.1 项目备份
```bash
# 创建项目完整备份
tar -zcvf contrail_backup_$(date +%Y%m%d_%H%M%S).tar.gz /Users/bytedance/traeProjects/Contrail
```

### 1.2 工具准备
- 静态分析工具：Flutter Analyze (内置) + dart_code_metrics (已配置)
- 版本控制：Git (确保所有代码已提交)
- 测试框架：Flutter Test
- 覆盖率工具：flutter_test_coverage

### 1.3 初始化配置检查
```bash
# 确保dart_code_metrics配置正确
flutter pub get
# 验证分析工具运行正常
flutter analyze lib/ --no-fatal-infos
```

## 2. 代码扫描阶段

### 2.1 全面静态扫描
```bash
# 运行完整静态分析
flutter analyze lib/ > scan_results_base.txt

# 扫描未使用变量
flutter analyze lib/ | grep "unused_local_variable\|unused_field\|unused_parameter" > unused_variables.txt

# 扫描未使用方法
flutter analyze lib/ | grep "unused_method" > unused_methods.txt

# 扫描未使用类/枚举
flutter analyze lib/ | grep "unused_element" > unused_elements.txt

# 扫描未使用导入
flutter analyze lib/ | grep "unused_import" > unused_imports.txt

# 使用dart_code_metrics进行深度扫描
dart_code_metrics analyze lib/ > scan_results_detailed.txt
```

### 2.2 特殊冗余检查
```bash
# 检查空文件
find lib/ -type f -name "*.dart" -size 0 > empty_files.txt

# 检查未使用资源
bash scripts/check_unused_assets.sh > unused_assets.txt

# 检查仅被测试引用的代码
python3 scripts/find_test_only_code.py > test_only_code.txt
```

### 2.3 扫描结果整合
将所有扫描结果导入Excel/Google Sheets进行统一管理，包含字段：
- 类型 (变量/方法/类/导入)
- 文件路径
- 代码内容
- 扫描工具
- 状态 (待复核/已确认/已排除)

## 3. 分析与验证阶段

### 3.1 复核团队组建
- 负责人：技术主管
- 成员：2名资深开发者

### 3.2 冗余判定标准
| 代码类型 | 判定标准 |
|---------|---------|
| 类/结构体/接口/枚举 | 未被任何生产代码引用 |
| 方法/函数 | 未被任何生产代码调用 |
| 变量 | 声明后未被读取或修改 |
| 测试引用代码 | 仅被测试类/方法引用，无生产代码引用 |
| 导入语句 | 未被文件内任何代码使用 |
| 空文件 | 无任何有效代码内容 |

### 3.3 人工复核流程
1. 逐行检查扫描结果
2. 排除有意保留代码（需添加`// TODO: FutureFeature - [功能描述]`标记）
3. 标记确认冗余的代码
4. 按优先级排序（独立变量/未使用方法 → 低依赖类 → 高依赖类）

## 4. 清理执行阶段

### 4.1 清理顺序
1. 未使用导入语句
2. 独立冗余变量和常量
3. 未使用的私有方法
4. 未使用的公共方法
5. 低依赖冗余类
6. 高依赖冗余类

### 4.2 清理操作规范
```bash
# 1. 移除未使用导入
# 使用IDE的自动移除功能或手动清理

# 2. 移除未使用变量/方法
flutter analyze lib/feature/[module]/ > module_analysis.txt
# 手动移除后编译验证
flutter build apk --debug

# 3. 移除冗余类
# 先检查依赖关系
grep -r "[ClassName]" lib/ --include="*.dart" | grep -v "class [ClassName]"
# 确认无依赖后移除
flutter analyze lib/ > analysis_after_removal.txt
```

### 4.3 版本控制要求
```bash
# 每完成一个模块的清理提交一次
git add lib/ test/
git commit -m "Clean up redundant code in [module]"
```

## 5. 验证与测试阶段

### 5.1 单元测试
```bash
# 运行所有单元测试
flutter test --no-pub > test_results_unit.txt

# 检查测试覆盖率
flutter test --coverage
lcov --remove coverage/lcov.info "*/test/*" "*/generated/*" --output-file coverage/filtered_lcov.info
genhtml coverage/filtered_lcov.info -o coverage/html
# 生成覆盖率报告
```

### 5.2 集成测试
```bash
# 运行集成测试
flutter drive --driver test/integration_test_driver.dart test/integration_test/* > test_results_integration.txt
```

### 5.3 性能测试
```bash
# 使用Flutter DevTools进行性能分析
flutter run --profile
# 记录CPU使用率、内存消耗和帧率
```

### 5.4 编译验证
```bash
# 验证全平台编译正常
flutter build apk --debug
flutter build ios --simulator
flutter build web
```

## 6. 文档记录阶段

### 6.1 移除代码清单
| 移除元素类型 | 名称 | 位置 | 移除原因 | 影响模块 |
|------------|------|------|----------|---------|
| 未使用方法 | `getRandomHabitName` | `lib/shared/utils/habit_data_generator.dart` | 无生产代码引用 | 习惯数据生成 |
| 冗余类 | `OldHabitModel` | `lib/shared/models/` | 已被新模型替代 | 所有习惯相关模块 |

### 6.2 质量问题总结
- 发现9处未使用的测试辅助方法
- 存在3个仅被测试引用的常量
- 12个文件存在未使用导入

### 6.3 编码规范建议
1. 禁止声明未使用的变量和方法
2. 测试代码中避免引用生产代码中的内部实现
3. 为未来功能预留代码添加明确标记
4. 定期执行静态分析（每两周一次）
5. 代码审查时检查冗余代码

## 7. 执行保障措施

### 7.1 代码审查机制
- 每次清理提交必须经过团队代码审查
- 审查重点：移除的合理性、依赖处理、测试覆盖

### 7.2 异常处理
- 若清理后出现编译错误，立即回滚至前一版本
- 若测试失败，定位问题并修复

### 7.3 进度跟踪
| 阶段 | 开始时间 | 完成时间 | 负责人 | 状态 |
|------|----------|----------|--------|------|
| 代码扫描 | 2024-01-15 | 2024-01-16 | 技术团队 | 已完成 |
| 分析验证 | 2024-01-17 | 2024-01-18 | 技术团队 | 进行中 |
| 清理执行 | 2024-01-19 | 2024-01-25 | 技术团队 | 待执行 |
| 验证测试 | 2024-01-26 | 2024-01-27 | 测试团队 | 待执行 |
| 文档记录 | 2024-01-28 | 2024-01-29 | 技术主管 | 待执行 |

## 8. 最终交付成果
1. **清理前后代码对比报告**：使用`git diff`生成
2. **移除冗余代码清单**：Excel表格格式
3. **测试验证报告**：包含单元测试、集成测试和性能测试结果
4. **代码质量改进建议**：基于清理过程发现的问题
5. **优化后的项目代码库**：包含所有清理变更