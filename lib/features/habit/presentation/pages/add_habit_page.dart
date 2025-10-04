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
import 'package:contrail/core/state/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AddHabitPage extends StatefulWidget {
  final Habit? habitToEdit;
  
  const AddHabitPage({super.key, this.habitToEdit});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String? _descriptionJson; // 存储富文本JSON
  late GoalType _goalType;
  late String? _selectedIcon;
  late Color _selectedColor; // 添加颜色变量定义

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
    
    // 初始化表单数据
    if (widget.habitToEdit != null) {
      // 编辑模式
      _nameController = TextEditingController(text: widget.habitToEdit!.name);
      
      // 存储富文本JSON
      _descriptionJson = widget.habitToEdit!.descriptionJson;
      
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
      _targetTimeMinutes = _targetDays * 60; // 使用修正后的_targetDays计算目标时间
      _selectedColor = widget.habitToEdit!.color; // 从现有习惯加载颜色
    } else {
        // 添加模式
        _nameController = TextEditingController();
        _descriptionJson = null; // 初始化富文本JSON为空
        _goalType = GoalType.positive;
        _selectedIcon = 'book'; // 默认图标
        _isSetGoal = false; // 默认不设置目标
        _cycleType = CycleType.monthly; // 默认无周期类型
        _targetDays = 1;
        _trackTime = false; // 默认不追踪目标
        _targetTimeMinutes = 60; // 默认值为1小时
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
          Colors.amber
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
              showLabel: true,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('不能删除预定义颜色')),
      );
      return;
    }
    
    // 显示确认对话框
    final shouldDelete = await showDialog<bool>(
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
    
    if (shouldDelete) {
      // 删除自定义颜色
      await ColorHelper.removeCustomColor(color);
      
      // 重新加载所有颜色
      await _loadAllColors();
      
      // 如果删除的是当前选中的颜色，选择第一个颜色
      if (_selectedColor.value == color.value && _colorOptions.isNotEmpty) {
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
      MaterialPageRoute(builder: (context) => IconSelectorPage(selectedIcon: _selectedIcon)),
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
    if (_cycleType == CycleType.daily) {
      return 31; // 每日习惯，每月最多31天
    } else if (_cycleType == CycleType.weekly) {
      return 7; // 每周最大7天
    } else if (_cycleType == CycleType.monthly) {
      return 31; // 每月最大31天
    }
    return 7; // 默认每周最大7天
  }

  // 根据目标天数获取最大时间值（天数*1小时，单位为分钟）
  int _getMaxTimeMinutes() {
    return _targetDays * 60; // 天数*1小时，转换为分钟
  }

  // 根据目标天数更新目标时间（按照次数乘半小时的结果作为默认值，单位为分钟）
  void _updateTargetTimeMinutes() {
    setState(() {
      _targetTimeMinutes = _targetDays * 30; // 每天30分钟
      // 确保不小于最小时间限制
      if (_targetTimeMinutes < 5) {
        _targetTimeMinutes = 5;
      }
      // 确保不超过最大时间限制
      final maxTimeMinutes = _getMaxTimeMinutes();
      if (_targetTimeMinutes > maxTimeMinutes) {
        _targetTimeMinutes = maxTimeMinutes;
      }
    });
  }

  // 保存习惯
  void _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 显示加载状态
        showDialog(
          context: context, 
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
        
        final habitProvider = Provider.of<HabitProvider>(context, listen: false);
        
        // 使用已有的富文本JSON数据
          final descriptionJson = _descriptionJson;
          logger.debug('保存习惯描述JSON: $descriptionJson');
          
          // 创建习惯对象
            final habit = Habit(
              id: widget.habitToEdit?.id ?? const Uuid().v4(),
              name: _nameController.text.trim(),
              targetDays: _targetDays,
              goalType: _goalType,
              icon: _selectedIcon,
              descriptionJson: descriptionJson,
              cycleType: _isSetGoal ? _cycleType : null,
              trackTime: _trackTime,
              colorValue: _selectedColor.value, // 保存颜色值
              currentDays: widget.habitToEdit?.currentDays ?? 0,
              totalDuration: widget.habitToEdit?.totalDuration ?? Duration.zero,
              trackingDurations: widget.habitToEdit?.trackingDurations ?? {},
              dailyCompletionStatus: widget.habitToEdit?.dailyCompletionStatus ?? {},
            );
        
        // 保存习惯
        if (widget.habitToEdit != null) {
          await habitProvider.updateHabit(habit);
        } else {
          await habitProvider.addHabit(habit);
        }
        
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final decoration = ThemeHelper.generateBackgroundDecoration(context);

    return Scaffold(
      body: Container(
        decoration: decoration,
        child: SafeArea(
          child: Column(
            children: [
              // 渐变背景的头部
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: ThemeHelper.onPrimary(context)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          widget.habitToEdit != null ? '编辑习惯' : '添加习惯',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ThemeHelper.onPrimary(context),
                          ),
                        ),
                        // 去掉右上角的保存按钮
                      ],
                    ),
                  ],
                ),
              ),
              
              // 表单内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 图标选择
                        Center(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: GestureDetector(
                              onTap: _openIconSelector,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _selectedColor,
                                      _selectedColor.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    _getIconData(_selectedIcon),
                                    size: 48,
                                    color: ThemeHelper.onPrimary(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _openIconSelector,
                            child: Text('选择图标', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // 习惯名称
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: '习惯名称',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.normal,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
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
                        ),
                        const SizedBox(height: 16),
                        
                        // 习惯描述（富文本显示 + 完整编辑按钮）
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // 富文本显示区域
                                if (_descriptionJson != null && _descriptionJson!.isNotEmpty) ...[
                                  ConstrainedBox(
                                    constraints: BoxConstraints(minHeight: 120, maxHeight: 240), // 设置最小高度为120，最大高度为240
                                    child: QuillEditor.basic(
                                      controller: QuillController(
                                        document: Document.fromJson(jsonDecode(_descriptionJson!)),
                                        selection: const TextSelection.collapsed(offset: 0),
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
                                  // 没有富文本时显示提示
                                  ConstrainedBox(
                                    constraints: BoxConstraints(minHeight: 120, maxHeight: 240), // 设置最小高度为120，最大高度为240
                                    child: Center(
                                      child: Text(
                                        '暂无描述内容',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                // 编辑按钮
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _openFullEditor,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.primary,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit, size: 16),
                                          const SizedBox(width: 4),
                                          Text('编辑描述'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _colorOptions.length + 1, // 增加一个加号按钮
                              itemBuilder: (context, index) {
                                // 如果是最后一个元素，显示加号按钮
                                if (index == _colorOptions.length) {
                                  return GestureDetector(
                                    onTap: _openCustomColorPicker,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).colorScheme.surface,
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.add,
                                          color: Theme.of(context).colorScheme.onSurface,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                
                                // 普通颜色选项
                                final color = _colorOptions[index];
                                final isSelected = color.value == _selectedColor.value;
                                return GestureDetector(
                                  onTap: () => _selectColor(color),
                                  onLongPress: () => _deleteCustomColor(color),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color,
                                      border: isSelected
                                          ? Border.all(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              width: 3,
                                            )
                                          : null,
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Icon(
                                              Icons.check,
                                              color: ThemeHelper.onPrimary(context),
                                              size: 18,
                                            ),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        

                        // 目标类型
                        Text(
                          '目标类型',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<GoalType>(
                                    title: Text('培养好习惯', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                    value: GoalType.positive,
                                    groupValue: _goalType,
                                    onChanged: (value) {
                                      setState(() {
                                        _goalType = value!;
                                      });
                                    },
                                    activeColor: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<GoalType>(
                                    title: Text('戒掉坏习惯', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                    value: GoalType.negative,
                                    groupValue: _goalType,
                                    onChanged: (value) {
                                      setState(() {
                                        _goalType = value!;
                                      });
                                    },
                                    activeColor: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // 是否追踪时间
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '是否追踪时间',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Switch(
                              value: _trackTime,
                              onChanged: (value) {
                                setState(() {
                                  _trackTime = value;
                                });
                              },
                              activeColor: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // 是否设置目标
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '是否设置目标',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Switch(
                              value: _isSetGoal,
                              onChanged: (value) {
                                setState(() {
                                  _isSetGoal = value;
                                  // 如果关闭目标设置，清除周期类型
                                  if (!value) {
                                    _cycleType = null;
                                  }
                                  // 如果开启目标设置且周期类型为null，设置默认周期类型为月度
                                  else if (_cycleType == null) {
                                    _cycleType = CycleType.monthly;
                                  }
                                });
                              },
                              activeColor: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // 如果选择了设置目标，显示目标选项
                        if (_isSetGoal) ...[
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '周期类型',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // 周期类型选择
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Expanded(
                                        child: RadioListTile<CycleType>(
                                          title: Text('每日', style: TextStyle(
                                            color: _cycleType == CycleType.daily 
                                              ? Theme.of(context).colorScheme.primary 
                                              : Theme.of(context).colorScheme.onSurface
                                          )),
                                          value: CycleType.daily,
                                          groupValue: _cycleType,
                                          onChanged: (value) {
                                            setState(() {
                                              _cycleType = value;
                                              // 当选择周期类型时，重置目标天数和目标时间
                                              _targetDays = 1;
                                              _updateTargetTimeMinutes();
                                            });
                                          },
                                          activeColor: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<CycleType>(
                                          title: Text('每周', style: TextStyle(
                                            color: _cycleType == CycleType.weekly 
                                              ? Theme.of(context).colorScheme.primary 
                                              : Theme.of(context).colorScheme.onSurface
                                          )),
                                          value: CycleType.weekly,
                                          groupValue: _cycleType,
                                          onChanged: (value) {
                                            setState(() {
                                              _cycleType = value;
                                              // 当选择周期类型时，重置目标天数和目标时间
                                              _targetDays = 1;
                                              _updateTargetTimeMinutes();
                                            });
                                          },
                                          activeColor: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<CycleType>(
                                          title: Text('每月', style: TextStyle(
                                            color: _cycleType == CycleType.monthly 
                                              ? Theme.of(context).colorScheme.primary 
                                              : Theme.of(context).colorScheme.onSurface
                                          )),
                                          value: CycleType.monthly,
                                          groupValue: _cycleType,
                                          onChanged: (value) {
                                            setState(() {
                                              _cycleType = value;
                                              // 当选择周期类型时，重置目标天数和目标时间
                                              _targetDays = 1;
                                              _updateTargetTimeMinutes();
                                            });
                                          },
                                          activeColor: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // 目标天数滑动条
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '目标天数',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Slider(
                                    value: _targetDays.toDouble(),
                                    min: 1.0,
                                    max: _getMaxDaysForCycleType().toDouble(),
                                    divisions: _getMaxDaysForCycleType() - 1,
                                    label: '$_targetDays 天',
                                    onChanged: (value) {
                                      setState(() {
                                        _targetDays = value.toInt();
                                        // 当目标天数改变时，更新目标时间
                                        _updateTargetTimeMinutes();
                                      });
                                    },
                                    activeColor: Theme.of(context).colorScheme.primary,
                                    inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      '$_targetDays 天',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // 如果选择了设置目标和追踪时间，显示目标时间值
                        if (_isSetGoal && _trackTime) ...[
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '目标时长 (分钟)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Slider(
                                    value: _targetTimeMinutes.toDouble(),
                                    min: 5.0,
                                    max: _getMaxTimeMinutes().toDouble(),
                                    divisions: (_getMaxTimeMinutes() ~/ 5), // 每5分钟一个刻度
                                    label: '$_targetTimeMinutes 分钟',
                                    onChanged: (value) {
                                      setState(() {
                                        _targetTimeMinutes = value.toInt();
                                      });
                                    },
                                    activeColor: Theme.of(context).colorScheme.primary,
                                    inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      '$_targetTimeMinutes 分钟',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      '最大时长: ${_getMaxTimeMinutes() ~/ 60}小时${_getMaxTimeMinutes() % 60}分钟',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        const SizedBox(height: 24),
                        
                        // 保存按钮
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveHabit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              elevation: 4,
                              shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            ),
                            child: Text(
                              widget.habitToEdit != null ? '更新习惯' : '添加习惯',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ThemeHelper.onPrimary(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
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
}