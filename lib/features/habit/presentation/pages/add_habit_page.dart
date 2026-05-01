import 'package:contrail/shared/utils/constants.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'package:contrail/features/habit/presentation/pages/full_editor_page.dart';

import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/features/habit/presentation/pages/icon_selector_page.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/icon_helper.dart';
import 'package:contrail/shared/utils/color_helper.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

class AddHabitPage extends StatefulWidget {
  final Habit? habitToEdit;

  const AddHabitPage({super.key, this.habitToEdit});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String? _descriptionJson =
      AppConstants.defaultHabitRichTextContent; // 存储富文本JSON
  late GoalType _goalType;
  late String? _selectedIcon;
  late Color _selectedColor; // 添加颜色变量定义
  late HabitService _habitService;

  // 新增的目标设置和时间追踪相关变量
  late bool _isSetGoal;
  late CycleType? _cycleType;
  late int _targetDays;
  late bool _trackTime;
  late int _targetTimeMinutes;

  // 存储所有颜色选项（预定义颜色 + 自定义颜色）
  List<Color> _colorOptions = [];

  @override
  void initState() {
    super.initState();
    _habitService = sl<HabitService>();

    // 初始化表单数据
    if (widget.habitToEdit != null) {
      // 编辑模式
      _nameController = TextEditingController(text: widget.habitToEdit!.name);

      // 存储富文本JSON
      _descriptionJson =
          widget.habitToEdit!.descriptionJson ??
          AppConstants.defaultHabitRichTextContent;

      // 不再需要_descriptionController
      _goalType = widget.habitToEdit!.goalType;
      _selectedIcon = widget.habitToEdit!.icon;
      _isSetGoal = widget.habitToEdit!.cycleType != null;
      _cycleType = widget.habitToEdit!.cycleType;
      // 初始化_targetDays，并确保它在当前周期类型的最大天数范围内
      _targetDays = widget.habitToEdit!.targetDays ?? 1;
      final maxDays = _getMaxDaysForCycleType();
      if (_targetDays > maxDays) {
        _targetDays = maxDays;
      }
      _trackTime = widget.habitToEdit!.trackTime;
      // 从保存的习惯中加载目标时间，如果没有则使用默认值
      _targetTimeMinutes = widget.habitToEdit!.targetTimeMinutes ??
          _habitService.calculateDefaultTargetTimeMinutes(_targetDays);
      _selectedColor = widget.habitToEdit!.color; // 从现有习惯加载颜色
    } else {
      // 添加模式
      _nameController = TextEditingController();
      // 使用预定义的常量初始化富文本JSON，避免每次都重新构建
      _descriptionJson = AppConstants.defaultHabitRichTextContent;
      _goalType = GoalType.positive;
      _selectedIcon = 'book'; // 默认图标
      _isSetGoal = false; // 默认不设置目标
      _cycleType = CycleType.monthly; // 默认无周期类型
      _targetDays = 1;
      _trackTime = false; // 默认不追踪目标
      _targetTimeMinutes = 30; // 默认值为30分钟
      _selectedColor = Colors.blue; // 默认蓝色
    }

    // 加载所有颜色
    _loadAllColors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 打开完整编辑页面
  Future<void> _openFullEditor() async {
    logger.debug('打开完整编辑页面，当前JSON: $_descriptionJson');

    // 跳转到完整编辑页面
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullEditorPage(
          initialContent: _descriptionJson,
          placeholder: '写一句专注时提醒自己的话吧',
        ),
      ),
    );

    // 处理返回结果
    if (result != null && result is String) {
      logger.debug('从完整编辑页面返回，结果: $result');
      _descriptionJson = result;
      setState(() {}); // 刷新UI以显示新的富文本内容
    }
  }

  // 加载所有颜色
  Future<void> _loadAllColors() async {
    try {
      final colors = await ColorHelper.getAllColors();
      setState(() {
        _colorOptions = colors;
      });
    } catch (e) {
      // Fallback to default colors if there's an error
      setState(() {
        _colorOptions = [
          Colors.blue,
          Colors.red,
          Colors.green,
          Colors.purple,
          Colors.orange,
          Colors.teal,
          Colors.pink,
          Colors.amber,
        ];
      });
    }
  }

  // 选择颜色
  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  // 打开自定义颜色选择器
  Future<void> _openCustomColorPicker() async {
    Color tempColor = _selectedColor;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择自定义颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false, // 不启用透明度选择
            ),
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () async {
                // 添加到自定义颜色列表
                await ColorHelper.addCustomColor(tempColor);

                // 重新加载所有颜色
                await _loadAllColors();

                // 更新选中的颜色
                setState(() {
                  _selectedColor = tempColor;
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 删除自定义颜色
  void _deleteCustomColor(Color color) async {
    // 检查是否是预定义颜色
    if (ColorHelper.isPredefinedColor(color)) {
      // 不能删除预定义颜色，显示提示
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('不能删除预定义颜色')));
      return;
    }

    // 显示确认对话框
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('确认删除'),
              content: const Text('确定要删除这个自定义颜色吗？'),
              actions: [
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('删除'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldDelete) {
      // 删除自定义颜色
      await ColorHelper.removeCustomColor(color);

      // 重新加载所有颜色
      await _loadAllColors();

      // 如果删除的是当前选中的颜色，选择第一个颜色
      if (_selectedColor.toARGB32() == color.toARGB32() &&
          _colorOptions.isNotEmpty) {
        setState(() {
          _selectedColor = _colorOptions[0];
        });
      }
    }
  }

  // 打开图标选择器
  Future<void> _openIconSelector() async {
    logger.debug('打开图标选择器，当前选中图标: $_selectedIcon');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IconSelectorPage(selectedIcon: _selectedIcon),
      ),
    );

    logger.debug('图标选择器返回结果: $result');
    if (result is String) {
      logger.debug('更新选中图标为: $result');
      setState(() {
        _selectedIcon = result;
      });
    } else {
      logger.debug('未选择任何图标或返回结果类型错误');
    }
  }

  // 查找图标数据
  IconData _getIconData(String? iconName) {
    // 使用IconHelper类获取图标数据
    return IconHelper.getIconData(iconName ?? '');
  }

  // 根据周期类型获取最大天数限制
  int _getMaxDaysForCycleType() {
    return _habitService.getMaxDaysForCycleType(_cycleType);
  }

  // 根据目标天数获取最大时间值（天数*8小时，单位为分钟）
  int _getMaxTimeMinutes() {
    return _habitService.getMaxTimeMinutes(_targetDays);
  }

  // 根据目标天数更新目标时间（按照次数乘半小时的结果作为默认值，单位为分钟）
  void _updateTargetTimeMinutes() {
    setState(() {
      _targetTimeMinutes = _habitService.calculateDefaultTargetTimeMinutes(
        _targetDays,
      );
    });
  }

  // 显示目标天数输入对话框
  Future<void> _showTargetDaysInputDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _targetDays.toString(),
    );
    final maxDays = _getMaxDaysForCycleType();

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置目标天数'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '请输入 1 到 $maxDays 之间的数字',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('确定'),
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                int clampedValue = value.clamp(1, maxDays);
                Navigator.pop(context, clampedValue);
              }
            },
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _targetDays = result;
        _updateTargetTimeMinutes();
      });
    }
  }

  // 显示目标时间输入对话框
  Future<void> _showTargetTimeInputDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _targetTimeMinutes.toString(),
    );
    final maxMinutes = _getMaxTimeMinutes();

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置目标时长'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '请输入 5 到 $maxMinutes 之间的数字（分钟）',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('确定'),
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                int clampedValue = value.clamp(5, maxMinutes);
                Navigator.pop(context, clampedValue);
              }
            },
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _targetTimeMinutes = result;
      });
    }
  }

  // 保存习惯
  void _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 显示加载状态
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final habitProvider = Provider.of<HabitProvider>(
          context,
          listen: false,
        );

        // 使用已有的富文本JSON数据
        final descriptionJson = _descriptionJson;
        logger.debug('保存习惯描述JSON: $descriptionJson');

        // 使用服务创建习惯对象
        final habit = _habitService.createHabit(
          id: widget.habitToEdit?.id ?? const Uuid().v4(),
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          descriptionJson: descriptionJson,
          targetDays: _targetDays,
          cycleType: _isSetGoal ? _cycleType : null,
          goalType: _goalType,
          trackTime: _trackTime,
          colorValue: _selectedColor.toARGB32(),
          targetTimeMinutes: _trackTime ? _targetTimeMinutes : null,
        );

        // 保留现有习惯的数据
        habit.currentDays = widget.habitToEdit?.currentDays ?? 0;
        habit.totalDuration =
            widget.habitToEdit?.totalDuration ?? Duration.zero;
        habit.trackingDurations = widget.habitToEdit?.trackingDurations ?? {};
        habit.dailyCompletionStatus =
            widget.habitToEdit?.dailyCompletionStatus ?? {};

        // 使用服务保存习惯
        await _habitService.saveHabit(
          habitProvider,
          habit,
          widget.habitToEdit != null,
        );

        // 关闭加载对话框
        Navigator.pop(context);

        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.habitToEdit != null ? '习惯更新成功' : '习惯添加成功'),
            backgroundColor: Colors.green,
          ),
        );

        // 返回上一页并带回结果
        Navigator.pop(context, habit);
      } catch (e) {
        // 关闭加载对话框
        Navigator.pop(context);

        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = ThemeHelper.generateBackgroundDecoration(context);
    final isEditing = widget.habitToEdit != null;
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    final heroSecondary =
        ThemeHelper.visualTheme(context).heroSecondaryForeground;

    return Scaffold(
      body: Container(
        decoration: decoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: ThemeHelper.heroDecoration(context, radius: 28),
                  padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildHeaderButton(
                            context,
                            icon: Icons.arrow_back_rounded,
                            label: '返回',
                            onTap: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          _buildHeaderButton(
                            context,
                            icon: isEditing
                                ? Icons.save_rounded
                                : Icons.add_rounded,
                            label: isEditing ? '保存' : '创建',
                            onTap: _saveHabit,
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Container(
                            width: 68.w,
                            height: 68.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _selectedColor,
                                  _selectedColor.withValues(alpha: 0.76),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _selectedColor.withValues(alpha: 0.28),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getIconData(_selectedIcon),
                              size: 28.sp,
                              color: ThemeHelper.onPrimary(context),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? '编辑习惯' : '新增习惯',
                                  style: TextStyle(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.w800,
                                    color: heroForeground,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  '统一管理图标、颜色、目标与周期设置',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    height: 1.5,
                                    color: heroSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionPanel(
                          context,
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _openIconSelector,
                                child: Container(
                                  width:
                                      AddHabitPageConstants.iconContainerSize,
                                  height:
                                      AddHabitPageConstants.iconContainerSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        _selectedColor,
                                        _selectedColor.withValues(alpha: 0.78),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getIconData(_selectedIcon),
                                      size: AddHabitPageConstants.iconSize,
                                      color: ThemeHelper.onPrimary(context),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Text(
                                '图标与视觉标识',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeHelper.onBackground(context),
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                '点击图标可快速更换当前习惯的视觉符号',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: ThemeHelper.onBackground(
                                    context,
                                  ).withValues(alpha: 0.68),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 14.h),
                              TextButton.icon(
                                onPressed: _openIconSelector,
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('更换图标'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildSectionLabel(context, '习惯名称'),
                        SizedBox(height: 10.h),
                        _buildSectionPanel(
                          context,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: '习惯名称',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                fontSize: AddHabitPageConstants.subtitleFontSize,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            style: TextStyle(
                              fontSize: AddHabitPageConstants.inputFontSize,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '请输入习惯名称';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildSectionLabel(context, '习惯描述'),
                        SizedBox(height: 10.h),
                        _buildSectionPanel(
                          context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_descriptionJson != null &&
                                  _descriptionJson!.isNotEmpty) ...[
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight:
                                        AddHabitPageConstants.richTextMinHeight,
                                    maxHeight:
                                        AddHabitPageConstants.richTextMaxHeight,
                                  ),
                                  child: QuillEditor.basic(
                                    controller: QuillController(
                                      document: Document.fromJson(
                                        jsonDecode(_descriptionJson!),
                                      ),
                                      selection:
                                          const TextSelection.collapsed(
                                            offset: 0,
                                          ),
                                    )..readOnly = true,
                                    config: const QuillEditorConfig(
                                      padding: EdgeInsets.zero,
                                      autoFocus: false,
                                      expands: false,
                                      scrollable: true,
                                      showCursor: false,
                                      placeholder: '',
                                    ),
                                  ),
                                ),
                              ] else ...[
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: ScreenUtil().setHeight(120),
                                    maxHeight: ScreenUtil().setHeight(240),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '暂无描述内容',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(height: 12.h),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _openFullEditor,
                                  icon: Icon(
                                    Icons.edit_rounded,
                                    size: AddHabitPageConstants.editIconSize,
                                  ),
                                  label: const Text('编辑描述'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildSectionLabel(context, '主题颜色'),
                        SizedBox(height: 10.h),
                        _buildSectionPanel(
                          context,
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing:
                                      AddHabitPageConstants.colorGridSpacing,
                                  mainAxisSpacing:
                                      AddHabitPageConstants.colorGridSpacing,
                                ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _colorOptions.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _colorOptions.length) {
                                return GestureDetector(
                                  onTap: _openCustomColorPicker,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).colorScheme.surface,
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.24),
                                        width:
                                            AddHabitPageConstants.colorBorderWidth,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.add,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        size: ScreenUtil().setSp(18),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final color = _colorOptions[index];
                              final isSelected =
                                  color.toARGB32() ==
                                  _selectedColor.toARGB32();
                              return GestureDetector(
                                onTap: () => _selectColor(color),
                                onLongPress: () => _deleteCustomColor(color),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                    border: isSelected
                                        ? Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                            width: AddHabitPageConstants
                                                .colorSelectedBorderWidth,
                                          )
                                        : null,
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Icon(
                                            Icons.check,
                                            color: ThemeHelper.onPrimary(
                                              context,
                                            ),
                                            size: AddHabitPageConstants
                                                .colorCheckIconSize,
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildSectionLabel(context, '目标类型'),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildChoiceTile(
                                context,
                                label: '培养好习惯',
                                selected: _goalType == GoalType.positive,
                                onTap: () {
                                  setState(() {
                                    _goalType = GoalType.positive;
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _buildChoiceTile(
                                context,
                                label: '戒掉坏习惯',
                                selected: _goalType == GoalType.negative,
                                onTap: () {
                                  setState(() {
                                    _goalType = GoalType.negative;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        _buildToggleTile(
                          context,
                          title: '追踪时间',
                          subtitle: '记录每次专注的持续时长',
                          value: _trackTime,
                          onChanged: (value) {
                            setState(() {
                              _trackTime = value;
                            });
                          },
                        ),
                        SizedBox(height: 12.h),
                        _buildToggleTile(
                          context,
                          title: '设置目标',
                          subtitle: '开启后可按周期管理完成次数与时长',
                          value: _isSetGoal,
                          onChanged: (value) {
                            setState(() {
                              _isSetGoal = value;
                              if (!value) {
                                _cycleType = null;
                              } else if (_cycleType == null) {
                                _cycleType = CycleType.monthly;
                              }
                            });
                          },
                        ),
                        if (_isSetGoal) ...[
                          SizedBox(height: 16.h),
                          _buildSectionLabel(context, '周期类型'),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildChoiceTile(
                                  context,
                                  label: '每日',
                                  selected: _cycleType == CycleType.daily,
                                  onTap: () {
                                    setState(() {
                                      _cycleType = CycleType.daily;
                                      _targetDays = 1;
                                      _updateTargetTimeMinutes();
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _buildChoiceTile(
                                  context,
                                  label: '每周',
                                  selected: _cycleType == CycleType.weekly,
                                  onTap: () {
                                    setState(() {
                                      _cycleType = CycleType.weekly;
                                      _targetDays = 1;
                                      _updateTargetTimeMinutes();
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _buildChoiceTile(
                                  context,
                                  label: '每月',
                                  selected: _cycleType == CycleType.monthly,
                                  onTap: () {
                                    setState(() {
                                      _cycleType = CycleType.monthly;
                                      _targetDays = 1;
                                      _updateTargetTimeMinutes();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_cycleType != CycleType.daily) ...[
                            SizedBox(height: 16.h),
                            _buildSectionPanel(
                              context,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionLabel(context, '目标天数'),
                                  SizedBox(height: 8.h),
                                  Slider(
                                    value: _targetDays.toDouble(),
                                    min: 1.0,
                                    max: _getMaxDaysForCycleType().toDouble(),
                                    divisions: _getMaxDaysForCycleType() - 1,
                                    label: '$_targetDays 天',
                                    onChanged: (value) {
                                      setState(() {
                                        _targetDays = value.toInt();
                                        _updateTargetTimeMinutes();
                                      });
                                    },
                                  ),
                                  Center(
                                    child: GestureDetector(
                                      onTap: _showTargetDaysInputDialog,
                                      child: Text(
                                        '$_targetDays 天',
                                        style: TextStyle(
                                          fontSize: AddHabitPageConstants
                                              .subtitleFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                        if (_isSetGoal && _trackTime) ...[
                          SizedBox(height: 16.h),
                          _buildSectionPanel(
                            context,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel(context, '目标时长（分钟）'),
                                SizedBox(height: 8.h),
                                Slider(
                                  value: _targetTimeMinutes.toDouble(),
                                  min: 5.0,
                                  max: _getMaxTimeMinutes().toDouble(),
                                  divisions: _getMaxTimeMinutes() ~/ 5,
                                  label: '$_targetTimeMinutes 分钟',
                                  onChanged: (value) {
                                    setState(() {
                                      _targetTimeMinutes = value.toInt();
                                    });
                                  },
                                ),
                                Center(
                                  child: GestureDetector(
                                    onTap: _showTargetTimeInputDialog,
                                    child: Text(
                                      '$_targetTimeMinutes 分钟',
                                      style: TextStyle(
                                        fontSize: AddHabitPageConstants
                                            .subtitleFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Center(
                                  child: Text(
                                    '最大时长: ${_getMaxTimeMinutes() ~/ 60}小时${_getMaxTimeMinutes() % 60}分钟',
                                    style: TextStyle(
                                      fontSize: AddHabitPageConstants
                                          .sectionTitleFontSize,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveHabit,
                            style: ThemeHelper.elevatedButtonStyle(
                              context,
                              padding:
                                  AddHabitPageConstants.buttonVerticalPadding,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                            child: Text(
                              isEditing ? '更新习惯' : '添加习惯',
                              style: TextStyle(
                                fontSize: ScreenUtil().setSp(20),
                                fontWeight: FontWeight.w800,
                                color: ThemeHelper.onPrimary(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18.sp, color: heroForeground),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: heroForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: ThemeHelper.onBackground(context),
      ),
    );
  }

  Widget _buildSectionPanel(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: ThemeHelper.panelDecoration(context, radius: 24),
      child: child,
    );
  }

  Widget _buildChoiceTile(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.14)
                : ThemeHelper.visualTheme(context).panelSecondaryColor,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.5)
                  : ThemeHelper.visualTheme(context).panelBorderColor,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? scheme.primary : ThemeHelper.onBackground(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSectionPanel(
      context,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: ThemeHelper.onBackground(context),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.5,
                    color: ThemeHelper.onBackground(
                      context,
                    ).withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
