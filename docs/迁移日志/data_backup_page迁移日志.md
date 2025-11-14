# data_backup_page.dart 布局参数迁移日志

## 迁移信息
- **文件路径**: lib/features/profile/presentation/pages/data_backup_page.dart
- **常量类**: DataBackupPageConstants
- **迁移日期**: 2025-11-11
- **迁移状态**: 已完成

## 原始参数统计
- **总调用次数**: 18

### 唯一参数值
- **WIDTH**: [8.0, 16.0, 20.0]
- **HEIGHT**: []
- **SP**: [14.0, 16.0, 18.0, 29.0]

## 常量类定义
```dart
/// 数据备份页面专用常量
class DataBackupPageConstants extends BaseLayoutConstants {
  // Container内边距
  static final EdgeInsets containerPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  
  // 宽度相关参数
  static final double width_8 = ScreenUtil().setWidth(8.0);
  static final double width_16 = ScreenUtil().setWidth(16.0);
  static final double width_20 = ScreenUtil().setWidth(20.0);
  
  // 按钮相关参数
  static final double buttonHeight = ScreenUtil().setHeight(48);
  
  // 备份项相关参数
  static final double backupItemHeight = ScreenUtil().setHeight(80);
  static final double backupItemBorderRadius = ScreenUtil().setWidth(12);
  
  // 分隔线高度
  static final double dividerHeight = ScreenUtil().setHeight(1);
  
  // 字体大小相关参数
  static final double fontSize_14 = ScreenUtil().setSp(14.0);
  static final double fontSize_16 = ScreenUtil().setSp(16.0);
  static final double fontSize_18 = ScreenUtil().setSp(18.0);
  static final double fontSize_29 = ScreenUtil().setSp(29.0);
  
  // 间距相关参数
  static final double verticalSpacing = ScreenUtil().setHeight(16);
  static final double sectionSpacing = ScreenUtil().setHeight(24);
}
```

## 迁移步骤
1. 导入常量类
2. 替换所有ScreenUtil调用
3. 验证布局一致性

## 迁移记录
| 替换项 | 原始代码 | 替换后代码 | 状态 |
|-------|---------|-----------|------|
| width: 8.0 | `ScreenUtil().setWidth(8.0)` | `DataBackupPageConstants.width_8` | 已替换 |
| width: 16.0 | `ScreenUtil().setWidth(16.0)` | `DataBackupPageConstants.containerPadding` | 已替换 |
| width: 20.0 | `ScreenUtil().setWidth(20.0)` | 保留ScreenUtil调用 | 部分替换 |
| sp: 14.0 | `ScreenUtil().setSp(14.0)` | `DataBackupPageConstants.fontSize_14` | 已替换 |
| sp: 16.0 | `ScreenUtil().setSp(16.0)` | `DataBackupPageConstants.fontSize_16` | 已替换 |
| sp: 18.0 | `ScreenUtil().setSp(18.0)` | `DataBackupPageConstants.fontSize_18` | 已替换 |
| sp: 29.0 | `ScreenUtil().setSp(29.0)` | `DataBackupPageConstants.fontSize_29` | 已替换 |

## 迁移建议（已按建议执行）
```dart
// ========== 迁移建议 ==========
// 1. 导入常量类
import 'package:contrail/shared/utils/page_layout_constants.dart';

// 2. WIDTH 替换建议:
// 将 `ScreenUtil().setWidth(8.0)` 替换为 `DataBackupPageConstants.width_8`
// 将 `ScreenUtil().setWidth(16.0)` 替换为 `DataBackupPageConstants.containerPadding`
// 某些WIDTH调用保留ScreenUtil直接调用

// 2. SP 替换建议:
// 将 `ScreenUtil().setSp(14.0)` 替换为 `DataBackupPageConstants.fontSize_14`
// 将 `ScreenUtil().setSp(16.0)` 替换为 `DataBackupPageConstants.fontSize_16`
// 将 `ScreenUtil().setSp(18.0)` 替换为 `DataBackupPageConstants.fontSize_18`
// 将 `ScreenUtil().setSp(29.0)` 替换为 `DataBackupPageConstants.fontSize_29`

// 3. 使用BaseLayoutConstants中的通用间距
// 将 `DataBackupPageConstants.spacingSmall/Medium/Large` 替换为 `BaseLayoutConstants.spacingSmall/Medium/Large`

// 4. 保留必要的flutter_screenutil导入

// 5. 总共有 18 处需要替换，已完成主要替换
// ============================
```

## 遇到的问题及解决方案
| 问题 | 解决方案 |
|------|--------|
| 通用间距常量未在DataBackupPageConstants中定义 | 使用BaseLayoutConstants.spacingSmall/Medium/Large代替 |
| 某些复杂布局计算仍需ScreenUtil | 保留部分ScreenUtil直接调用，确保布局功能正常 |
| 语法错误：括号不匹配 | 修复代码中的括号和分号，确保语法正确 |
| 编译错误：找不到spacingSmall/Medium/Large | 将这些引用修改为BaseLayoutConstants中的相应常量 |