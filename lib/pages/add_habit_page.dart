import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import '../models/habit.dart';
import '../providers/habit_provider.dart';
// 从habit_management_page.dart导入CycleType枚举
import './habit_management_page.dart' show CycleType;

// 不再需要在这里定义CycleType，使用从habit_management_page.dart导入的枚举

class AddHabitPage extends StatefulWidget {
  final Habit? habitToEdit;
  const AddHabitPage({super.key, this.habitToEdit});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final uuid = Uuid();
  final nameController = TextEditingController();
  final targetCountController = TextEditingController();
  int targetDays = 7; // 默认每周
  CycleType? selectedCycleType = CycleType.daily; // 默认每天
  GoalType selectedGoalType = GoalType.positive; // 默认正向目标
  String? selectedImagePath;
  bool trackTime = false; // 是否统计时间
  int trackingDuration = 30; // 默认追踪时间（分钟）
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.habitToEdit != null) {
      isEditing = true;
      final habit = widget.habitToEdit!;
      nameController.text = habit.name;
      targetDays = habit.targetDays ?? 7;
      selectedCycleType = habit.cycleType;
      selectedGoalType = habit.goalType;
      selectedImagePath = habit.imagePath;
      trackTime = habit.trackTime ?? false;
      trackingDuration = 30; // 默认值，实际应用中可能需要从habit中获取
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);

    return Scaffold(
      appBar: AppBar(
                title: Text(isEditing ? '编辑习惯' : '添加习惯'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '习惯名称',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 12),
              // 背景图片选择
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                [
                  Text('背景图片:'),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // 显示图片来源选择对话框
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('选择图片来源'),
                          actions: [
                            TextButton(
                              child: Text('从相册选择'),
                              onPressed: () async {
                                Navigator.pop(context);
                                final img_picker.ImagePicker picker = img_picker.ImagePicker();
                                final img_picker.XFile? image = await picker.pickImage(source: img_picker.ImageSource.gallery);
                                if (image != null) {
                                  setState(() => selectedImagePath = image.path);
                                }
                              },
                            ),
                            TextButton(
                              child: Text('从资源选择'),
                              onPressed: () {
                                // 这里可以实现从应用资源中选择图片的逻辑
                                Navigator.pop(context);
                                // 简单示例：设置为null，表示使用默认背景
                                setState(() => selectedImagePath = null);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(selectedImagePath != null ? Icons.check : Icons.add),
                    label: Text(selectedImagePath != null ? '已选择' : '选择'),
                  ),
                ],
              ),
              SizedBox(height: 12),
              DropdownButton<GoalType>(
                value: selectedGoalType,
                hint: const Text('选择目标类型'),
                items: const [
                  DropdownMenuItem(value: GoalType.positive, child: Text('正向目标')),
                  DropdownMenuItem(value: GoalType.negative, child: Text('反向目标')),
                ],
                onChanged: (value) => setState(() => selectedGoalType = value!),
                isExpanded: true,
              ),
              SizedBox(height: 12),
              // 周期类型选择
              Text('选择周期类型:'),
              SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('每天'),
                      selected: selectedCycleType == CycleType.daily,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedCycleType = CycleType.daily);
                        }
                      },
                    ),
                    SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('每周'),
                      selected: selectedCycleType == CycleType.weekly,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedCycleType = CycleType.weekly);
                        }
                      },
                    ),
                    SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('每月'),
                      selected: selectedCycleType == CycleType.monthly,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedCycleType = CycleType.monthly);
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // 根据选择的周期类型显示不同的配置项
              if (selectedCycleType == CycleType.daily) ...[
                Text('每天都要完成此习惯'),
              ] else if (selectedCycleType == CycleType.weekly) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('每周完成目标的天数: '),
                        SizedBox(width: 60),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                int? newVal = int.tryParse(value);
                                if (newVal != null && newVal >= 1 && newVal <= 7) {
                                  setState(() {
                                    targetDays = newVal;
                                  });
                                }
                              }
                            },
                            controller: TextEditingController(text: targetDays.toString()),
                            textAlign: TextAlign.center,
                            maxLength: 2,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: targetDays.clamp(1, 7).toDouble(), // 确保值在1-7之间
                      min: 1,
                      max: 7,
                      divisions: 6,
                      label: targetDays.toString(),
                      onChanged: (double value) {
                        setState(() {
                          targetDays = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ] else if (selectedCycleType == CycleType.monthly) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('每月完成目标的天数: '),
                        SizedBox(width: 60),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                int? newVal = int.tryParse(value);
                                if (newVal != null && newVal >= 1 && newVal <= 31) {
                                  setState(() {
                                    targetDays = newVal;
                                  });
                                }
                              }
                            },
                            controller: TextEditingController(text: targetDays.toString()),
                            textAlign: TextAlign.center,
                            maxLength: 2,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: targetDays.clamp(1, 31).toDouble(), // 确保值在1-31之间
                      min: 1,
                      max: 31,
                      divisions: 30,
                      label: targetDays.toString(),
                      onChanged: (double value) {
                        setState(() {
                          targetDays = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ],
              // 是否统计时间
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                [
                  Text('是否统计时间:'),
                  Switch(
                    value: trackTime,
                    onChanged: (value) => setState(() => trackTime = value),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // 只有当统计时间为true时，才显示追踪时间设置框
              if (trackTime) ...[
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '追踪时间 (分钟)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      // 确保输入的值为正整数
                      if (value.isNotEmpty) {
                        trackingDuration = int.tryParse(value) ?? 30;
                        if (trackingDuration < 1) trackingDuration = 1;
                      }
                    });
                  },
                  controller: TextEditingController(text: trackingDuration.toString()),
                ),
                SizedBox(height: 12),
              ],
              SizedBox(height: 24),
              // 确认添加按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      try {
                        // 处理周期配置
                        String cycleConfig = '';
                        if (selectedCycleType == CycleType.daily) {
                          cycleConfig = 'daily';
                        } else if (selectedCycleType == CycleType.weekly || selectedCycleType == CycleType.monthly) {
                          cycleConfig = targetDays.toString();
                        }

                        if (isEditing && widget.habitToEdit != null) {
                        // 更新现有习惯
                        final updatedHabit = Habit(
                          id: widget.habitToEdit!.id,
                          name: nameController.text,
                          goalType: selectedGoalType,
                          imagePath: selectedImagePath,
                          targetCount: targetDays,
                          targetDays: targetDays,
                          cycleType: selectedCycleType,
                          cycleConfig: cycleConfig,
                          trackTime: trackTime,
                          trackingRecords: widget.habitToEdit!.trackingRecords,
                          currentCount: widget.habitToEdit!.currentCount,
                          currentDays: widget.habitToEdit!.currentDays,
                        );
                        await habitProvider.updateHabit(updatedHabit);
                      } else {
                        // 添加新习惯
                        await habitProvider.addHabit(Habit(
                          id: uuid.v4(),
                          name: nameController.text,
                          goalType: selectedGoalType,
                          imagePath: selectedImagePath,
                          targetCount: targetDays,
                          targetDays: targetDays,
                          cycleType: selectedCycleType,
                          cycleConfig: cycleConfig,
                          trackTime: trackTime,
                        ));
                      }
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isEditing ? '习惯更新成功！' : '习惯添加成功！')),
                          );
                        }
                      } catch (e) {
                        print('添加习惯时发生错误: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('添加习惯失败: ${e.toString()}')),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('请输入习惯名称')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text(
                    '添加',
                    style: TextStyle(fontSize: 18),
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