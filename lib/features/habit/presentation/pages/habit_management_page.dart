import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/habit/domain/use_cases/get_habits_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/add_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/delete_habit_use_case.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/habit/presentation/pages/habit_tracking_page.dart';
import 'package:contrail/features/habit/presentation/pages/add_habit_page.dart';
import 'package:contrail/features/focus/presentation/pages/focus_selection_page.dart';

// 从habit.dart导入所需枚举
import 'package:contrail/shared/models/habit.dart' show CycleType, ImageSourceType, TrackingMode, GoalType;

class HabitManagementPage extends StatefulWidget {
  const HabitManagementPage({super.key});

  @override
  State<HabitManagementPage> createState() => _HabitManagementPageState();
}

class _HabitManagementPageState extends State<HabitManagementPage> {
  late final GetHabitsUseCase _getHabitsUseCase;
  late final AddHabitUseCase _addHabitUseCase;
  late final UpdateHabitUseCase _updateHabitUseCase;
  late final DeleteHabitUseCase _deleteHabitUseCase;
  List<Habit> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getHabitsUseCase = sl<GetHabitsUseCase>();
    _addHabitUseCase = sl<AddHabitUseCase>();
    _updateHabitUseCase = sl<UpdateHabitUseCase>();
    _deleteHabitUseCase = sl<DeleteHabitUseCase>();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      setState(() {
        _isLoading = true;
      });
      _habits = await _getHabitsUseCase.execute();
    } catch (e) {
      logger.error('加载习惯失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载习惯失败: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 显示补充打卡对话框
  void _showSupplementCheckInDialog(BuildContext context) {
    if (_habits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('暂无习惯，请先添加习惯')),
      );
      return;
    }

    Habit? selectedHabit;
    DateTime selectedDate = DateTime.now();
    int durationMinutes = 30; // 默认时长30分钟

    showDialog(
      context: context, 
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('补充打卡'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 习惯选择
                DropdownButton<Habit>(
                  hint: const Text('选择习惯'),
                  value: selectedHabit,
                  onChanged: (Habit? newValue) {
                    setStateDialog(() {
                      selectedHabit = newValue;
                    });
                  },
                  items: _habits.map((Habit habit) {
                    return DropdownMenuItem<Habit>(
                      value: habit,
                      child: Text(habit.name),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 日期选择
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    const Text('选择日期:'),
                    TextButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 时长选择（仅当习惯需要追踪时间时显示）
                if (selectedHabit?.trackTime ?? false)
                  Column(
                    children:[
                      const Text('选择时长 (分钟):'),
                      Slider(
                        value: durationMinutes.toDouble(),
                        min: 1.0,
                        max: 120.0,
                        divisions: 119,
                        label: '$durationMinutes 分钟',
                        onChanged: (double value) {
                          setStateDialog(() {
                            durationMinutes = value.toInt();
                          });
                        },
                      ),
                      Text('$durationMinutes 分钟'),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedHabit == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('请选择习惯')),
                  );
                  return;
                }

                // 执行补充打卡
                final duration = selectedHabit!.trackTime
                  ? Duration(minutes: durationMinutes)
                  : Duration.zero;

                selectedHabit!.addTrackingRecord(selectedDate, duration);
                try {
                  await _updateHabitUseCase.execute(selectedHabit!);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${selectedHabit!.name} 补充打卡成功')),
                  );
                  // 重新加载习惯列表
                  _loadHabits();
                } catch (e) {
                  logger.error('更新习惯失败', e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('补充打卡失败: ${e.toString()}')),
                  );
                }
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
  }

  // 删除习惯
  Future<void> _deleteHabit(String habitId) async {
    try {
      await _deleteHabitUseCase.execute(habitId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('习惯删除成功')),
      );
      _loadHabits();
    } catch (e) {
      logger.error('删除习惯失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除习惯失败: ${e.toString()}')),
      );
    }
  }

  // 打卡习惯
  Future<void> _checkInHabit(Habit habit) async {
    try {
      habit.addTrackingRecord(DateTime.now(), habit.trackTime ? Duration(minutes: 30) : Duration.zero);
      await _updateHabitUseCase.execute(habit);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${habit.name} 打卡成功')),
      );
      _loadHabits();
    } catch (e) {
      logger.error('打卡失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打卡失败: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.debug('HabitManagementPage 构建中，习惯数量: ${_habits.length}');

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddHabitPage()),
          );
          if (result is Habit) {
            try {
              await _addHabitUseCase.execute(result);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${result.name} 添加成功')),
              );
              _loadHabits();
            } catch (e) {
              logger.error('添加习惯失败', e);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('添加习惯失败: ${e.toString()}')),
              );
            }
          }
        },
      ),
      body: Column(
        children: [
          // 蓝色标题区
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.blueAccent, Colors.lightBlue],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            width: double.infinity,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '我的习惯',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '培养良好习惯，提升生活品质',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (value) {
                      if (value == 'supplement_check_in') {
                        _showSupplementCheckInDialog(context);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'supplement_check_in',
                        child: Text('补充打卡'),
                      ),
                    ],
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 内容区
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _habits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.format_list_bulleted,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '暂无习惯数据',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AddHabitPage()),
                                );
                                if (result is Habit) {
                                  try {
                                    await _addHabitUseCase.execute(result);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${result.name} 添加成功')),
                                    );
                                    _loadHabits();
                                  } catch (e) {
                                    logger.error('添加习惯失败', e);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('添加习惯失败: ${e.toString()}')),
                                    );
                                  }
                                }
                              },
                              child: Text('添加第一个习惯'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHabits,
                        child: ListView.builder(
                          itemCount: _habits.length,
                          itemBuilder: (context, index) {
                            final habit = _habits[index];
                            return _buildHabitCard(habit, index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // 构建习惯卡片的方法
  Widget _buildHabitCard(Habit habit, int index) {
    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        // 显示确认对话框
        bool? confirmDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除习惯 ${habit.name} 吗？'),
            actions: [
              TextButton(
                child: const Text('取消'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('确认'),
                style: TextButton.styleFrom(textStyle: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (confirmDelete == true) {
          await _deleteHabit(habit.id);
        }
        return confirmDelete ?? false;
      },
      child: GestureDetector(
        onLongPress: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddHabitPage(habitToEdit: habit),
            ),
          );
          if (result is Habit) {
            try {
              await _updateHabitUseCase.execute(result);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${result.name} 更新成功')),
              );
              _loadHabits();
            } catch (e) {
              logger.error('更新习惯失败', e);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('更新习惯失败: ${e.toString()}')),
              );
            }
          }
        },
        child: Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[150] ?? Colors.grey[200]!, width: 0.5),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.97), (Colors.grey[50] ?? Colors.grey[100])!.withOpacity(0.97)],
              ),
              image: habit.imagePath != null
                  ? DecorationImage(
                      image: FileImage(File(habit.imagePath!)),
                      fit: BoxFit.cover,
                      opacity: 0.15,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题和按钮行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (habit.trackTime) {
                          // 导航到专注选择页面
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FocusSelectionPage(habit: habit),
                            ),
                          );
                        } else {
                          // 打卡逻辑
                          _checkInHabit(habit);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(habit.trackTime ? '开始专注' : '打卡'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // 进度环行
                if (habit.targetDays != null) 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // 次数进度环和文字描述
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: habit.currentDays / habit.targetDays!, 
                                  strokeWidth: 2,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${habit.currentDays}/${habit.targetDays}天',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          // 时间进度环和文字描述（仅当trackTime为true时显示）
                          if (habit.trackTime) 
                            Row(
                              children: [
                                SizedBox(width: 16),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    value: habit.targetDays != null
                                        ? habit.getTotalDurationForWeek(DateTime.now()).inMinutes / (habit.targetDays! * 30) // 假设每天目标30分钟
                                        : 0,
                                    strokeWidth: 2,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${habit.getTotalDurationForWeek(DateTime.now()).inMinutes}分钟',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                // 本周累计时间（与进度环水平对齐）
                if (habit.trackTime) 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '本周累计: ${habit.getTotalDurationForWeek(DateTime.now()).inMinutes}分钟',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}