#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
布局参数迁移辅助工具

该脚本用于辅助将Flutter页面中的ScreenUtil调用迁移到统一的常量类中。
功能：
1. 分析文件中的ScreenUtil调用
2. 生成迁移建议和替换方案
3. 创建迁移日志文件
4. 更新迁移跟踪表
"""

import os
import re
import sys
import json
from datetime import datetime

# 支持的ScreenUtil调用模式
SCREENUTIL_PATTERNS = {
    'width': re.compile(r'ScreenUtil\(\)\.setWidth\(([^)]+)\)'),
    'height': re.compile(r'ScreenUtil\(\)\.setHeight\(([^)]+)\)'),
    'sp': re.compile(r'ScreenUtil\(\)\.setSp\(([^)]+)\)')
}

# 页面到常量类的映射关系
PAGE_TO_CONSTANT_CLASS = {
    # 习惯模块页面
    'add_habit_page.dart': 'AddHabitPageConstants',
    'habit_management_page.dart': 'HabitManagementPageConstants',
    'fullscreen_clock_page.dart': 'FullscreenClockPageConstants',
    'icon_selector_page.dart': 'IconSelectorPageConstants',
    'habit_tracking_page.dart': 'HabitTrackingPageConstants',
    'full_editor_page.dart': 'FullEditorPageConstants',
    
    # 统计模块页面
    'statistics_page.dart': 'StatisticsPageConstants',
    'habit_detail_statistics_page.dart': 'HabitDetailStatisticsPageConstants',
    'stats_share_result_page.dart': 'StatsShareResultPageConstants',
    
    # 个人资料模块页面
    'profile_page.dart': 'ProfilePageConstants',
    'data_backup_page.dart': 'DataBackupPageConstants',
    'theme_selection_page.dart': 'ThemeSelectionPageConstants',
    'personalization_settings_page.dart': 'PersonalizationSettingsPageConstants',
    
    # 共享页面
    'json_editor_page.dart': 'JsonEditorPageConstants',
    
    # 组件
    'habit_item_widget.dart': 'HabitItemWidgetConstants',
    'pomodoro_settings_dialog.dart': 'PomodoroSettingsDialogConstants',
    'supplement_check_in_dialog.dart': 'SupplementCheckInDialogConstants',
    'statistics_chart_widget.dart': 'StatisticsChartWidgetConstants',
    'statistics_detail_view.dart': 'StatisticsDetailViewConstants',
    'timeline_view_widget.dart': 'TimelineViewWidgetConstants',
    'backup_restore_confirmation_dialog.dart': 'BackupRestoreConfirmationDialogConstants',
    'backup_delete_confirmation_dialog.dart': 'BackupDeleteConfirmationDialogConstants',
    'header_card_widget.dart': 'HeaderCardWidgetConstants',
    'clock_widget.dart': 'ClockWidgetConstants'
}

def analyze_file(file_path):
    """
    分析文件中的ScreenUtil调用
    返回包含调用次数和参数值的字典
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"错误：无法读取文件 {file_path}: {e}")
        return None
    
    results = {
        'width': [],
        'height': [],
        'sp': []
    }
    
    # 搜索所有ScreenUtil调用
    for param_type, pattern in SCREENUTIL_PATTERNS.items():
        matches = pattern.findall(content)
        for match in matches:
            # 清理数值
            value = match.strip()
            # 检查是否是数字
            if value.isdigit() or (value.startswith('-') and value[1:].isdigit()) or re.match(r'^\d+\.\d+$', value):
                results[param_type].append(float(value))
    
    # 统计唯一值
    unique_values = {
        'width': list(set(results['width'])),
        'height': list(set(results['height'])),
        'sp': list(set(results['sp']))
    }
    
    return {
        'file_path': file_path,
        'file_name': os.path.basename(file_path),
        'total_calls': sum(len(v) for v in results.values()),
        'unique_values': unique_values,
        'constant_class': PAGE_TO_CONSTANT_CLASS.get(os.path.basename(file_path), 'BaseLayoutConstants')
    }

def generate_constant_definitions(analysis_result):
    """
    根据分析结果生成常量定义代码
    """
    if not analysis_result:
        return None
    
    file_name = analysis_result['file_name']
    constant_class = analysis_result['constant_class']
    unique_values = analysis_result['unique_values']
    
    # 生成常量类定义
    definitions = []
    definitions.append(f"/// {file_name} 专用布局常量类")
    definitions.append(f"class {constant_class} extends BaseLayoutConstants {{")
    
    # 按类型分组生成常量定义
    
    # 1. 宽度相关
    if unique_values['width']:
        definitions.append("  // 宽度相关参数")
        for value in sorted(unique_values['width']):
            constant_name = f"width_{int(value)}" if value.is_integer() else f"width_{value}"
            definitions.append(f"  static final double {constant_name} = ScreenUtil().setWidth({value});")
        definitions.append("")
    
    # 2. 高度相关
    if unique_values['height']:
        definitions.append("  // 高度相关参数")
        for value in sorted(unique_values['height']):
            constant_name = f"height_{int(value)}" if value.is_integer() else f"height_{value}"
            definitions.append(f"  static final double {constant_name} = ScreenUtil().setHeight({value});")
        definitions.append("")
    
    # 3. 字体大小相关
    if unique_values['sp']:
        definitions.append("  // 字体大小相关参数")
        for value in sorted(unique_values['sp']):
            constant_name = f"fontSize_{int(value)}" if value.is_integer() else f"fontSize_{value}"
            definitions.append(f"  static final double {constant_name} = ScreenUtil().setSp({value});")
        definitions.append("")
    
    definitions.append("}")
    
    return '\n'.join(definitions)

def generate_migration_suggestions(analysis_result):
    """
    生成迁移建议，包括导入语句和替换方案
    """
    if not analysis_result:
        return None
    
    file_name = analysis_result['file_name']
    constant_class = analysis_result['constant_class']
    unique_values = analysis_result['unique_values']
    
    suggestions = []
    suggestions.append("// ========== 迁移建议 ==========")
    suggestions.append("// 1. 导入常量类")
    suggestions.append("import 'package:contrail/shared/utils/page_layout_constants.dart';")
    suggestions.append("")
    
    # 生成替换建议
    for param_type, values in unique_values.items():
        if values:
            suggestions.append(f"// 2. {param_type.upper()} 替换建议:")
            for value in sorted(values):
                original = f"ScreenUtil().set{param_type.capitalize()}({value})"
                constant_name = f"{param_type}_{int(value)}" if value.is_integer() else f"{param_type}_{value}"
                replaced = f"{constant_class}.{constant_name}"
                suggestions.append(f"// 将 `{original}` 替换为 `{replaced}`")
            suggestions.append("")
    
    suggestions.append(f"// 3. 移除不再需要的导入")
    suggestions.append("// import 'package:flutter_screenutil/flutter_screenutil.dart';")
    suggestions.append("")
    suggestions.append(f"// 4. 总共有 {analysis_result['total_calls']} 处需要替换")
    suggestions.append("// ============================")
    
    return '\n'.join(suggestions)

def create_migration_log(analysis_result):
    """
    创建迁移日志文件
    """
    if not analysis_result:
        return None
    
    file_name = analysis_result['file_name']
    file_path = analysis_result['file_path']
    constant_class = analysis_result['constant_class']
    unique_values = analysis_result['unique_values']
    
    # 创建日志目录
    log_dir = '/Users/bytedance/traeProjects/Contrail/docs/迁移日志'
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
    
    log_file = os.path.join(log_dir, f"{os.path.splitext(file_name)[0]}迁移日志.md")
    
    # 生成日志内容
    content = [
        f"# {file_name} 布局参数迁移日志",
        f"\n## 迁移信息",
        f"- **文件路径**: {file_path}",
        f"- **常量类**: {constant_class}",
        f"- **迁移日期**: {datetime.now().strftime('%Y-%m-%d')}",
        f"- **迁移状态**: 未开始",
        
        f"\n## 原始参数统计",
        f"- **总调用次数**: {analysis_result['total_calls']}",
        f"\n### 唯一参数值",
    ]
    
    for param_type, values in unique_values.items():
        content.append(f"- **{param_type.upper()}**: {sorted(values)}")
    
    content.extend([
        f"\n## 常量类定义",
        f"```dart",
        generate_constant_definitions(analysis_result),
        f"```",
        
        f"\n## 迁移步骤",
        f"1. 导入常量类",
        f"2. 替换所有ScreenUtil调用",
        f"3. 验证布局一致性",
        
        f"\n## 迁移记录",
        f"| 替换项 | 原始代码 | 替换后代码 | 状态 |",
        f"|-------|---------|-----------|------|",
    ])
    
    # 生成替换记录表格
    for param_type, values in unique_values.items():
        for value in sorted(values):
            original = f"ScreenUtil().set{param_type.capitalize()}({value})"
            constant_name = f"{param_type}_{int(value)}" if value.is_integer() else f"{param_type}_{value}"
            replaced = f"{constant_class}.{constant_name}"
            content.append(f"| {param_type}: {value} | `{original}` | `{replaced}` | 未替换 |")
    
    content.extend([
        f"\n## 迁移建议",
        f"```dart",
        generate_migration_suggestions(analysis_result),
        f"```",
        
        f"\n## 遇到的问题及解决方案",
        f"|",
        f"|",
        f"|",
        f"|-------|----------------|",
    ])
    
    try:
        with open(log_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(content))
        print(f"已创建迁移日志: {log_file}")
        return log_file
    except Exception as e:
        print(f"错误：无法创建迁移日志 {log_file}: {e}")
        return None

def update_tracking_table(file_path, status="进行中"):
    """
    更新迁移跟踪表（简化版本）
    实际项目中可以实现更复杂的Markdown表格解析和更新
    """
    tracking_file = '/Users/bytedance/traeProjects/Contrail/docs/页面布局参数迁移跟踪表.md'
    file_name = os.path.basename(file_path)
    constant_class = PAGE_TO_CONSTANT_CLASS.get(file_name, 'BaseLayoutConstants')
    date = datetime.now().strftime('%Y-%m-%d')
    
    print(f"\n请手动更新迁移跟踪表:")
    print(f"文件: {file_name}")
    print(f"常量类: {constant_class}")
    print(f"状态: {status}")
    print(f"日期: {date}")
    print(f"跟踪表路径: {tracking_file}")

def main():
    """
    主函数
    """
    print("=== 布局参数迁移辅助工具 ===")
    print("用途: 分析Flutter文件中的ScreenUtil调用，生成迁移建议和日志")
    print("\n")
    
    if len(sys.argv) > 1:
        # 处理单个文件
        file_path = sys.argv[1]
        if os.path.exists(file_path) and file_path.endswith('.dart'):
            print(f"分析文件: {file_path}")
            analysis = analyze_file(file_path)
            if analysis:
                print(f"发现 {analysis['total_calls']} 处ScreenUtil调用")
                print(f"常量类: {analysis['constant_class']}")
                
                # 打印迁移建议
                print("\n迁移建议:")
                print(generate_migration_suggestions(analysis))
                
                # 打印常量定义
                print("\n常量类定义:")
                print(generate_constant_definitions(analysis))
                
                # 创建迁移日志
                log_file = create_migration_log(analysis)
                
                # 更新跟踪表
                update_tracking_table(file_path)
        else:
            print(f"错误：文件不存在或不是Dart文件: {file_path}")
    else:
        # 扫描目录中的所有Dart文件
        project_root = '/Users/bytedance/traeProjects/Contrail'
        print(f"扫描项目目录: {project_root}")
        
        dart_files = []
        for root, dirs, files in os.walk(project_root):
            # 跳过测试目录和构建目录
            if 'test' in dirs:
                dirs.remove('test')
            if 'build' in dirs:
                dirs.remove('build')
                
            for file in files:
                if file.endswith('.dart') and file in PAGE_TO_CONSTANT_CLASS:
                    dart_files.append(os.path.join(root, file))
        
        print(f"找到 {len(dart_files)} 个需要分析的文件")
        
        # 统计汇总
        summary = []
        for file_path in dart_files:
            print(f"分析: {file_path}")
            analysis = analyze_file(file_path)
            if analysis:
                summary.append({
                    'file': analysis['file_name'],
                    'calls': analysis['total_calls'],
                    'width': len(analysis['unique_values']['width']),
                    'height': len(analysis['unique_values']['height']),
                    'sp': len(analysis['unique_values']['sp'])
                })
                
                # 创建迁移日志
                create_migration_log(analysis)
        
        # 打印汇总信息
        print("\n=== 分析汇总 ===")
        print(f"总计文件数: {len(summary)}")
        print(f"总计调用数: {sum(s['calls'] for s in summary)}")
        
        print("\n按调用次数排序:")
        for s in sorted(summary, key=lambda x: x['calls'], reverse=True):
            print(f"{s['file']}: {s['calls']}次调用 (width:{s['width']}, height:{s['height']}, sp:{s['sp']})")
        
        print("\n所有文件的迁移日志已创建在 docs/迁移日志/ 目录下")
        print("请根据日志进行迁移工作，并更新迁移跟踪表")

if __name__ == "__main__":
    main()