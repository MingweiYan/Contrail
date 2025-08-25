import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'dart:io';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import './habit_tracking_page.dart';
import './focus_selection_page.dart';
import './add_habit_page.dart';

// 从habit.dart导入所需枚举
import '../models/habit.dart' show CycleType, ImageSourceType;

class HabitManagementPage extends StatefulWidget {
  const HabitManagementPage({super.key});

  @override
  State<HabitManagementPage> createState() => _HabitManagementPageState();
}

class _HabitManagementPageState extends State<HabitManagementPage> {
  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    print('HabitManagementPage 构建中，习惯数量: ${habitProvider.habits.length}');

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddHabitPage()),
        ),
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
                      top: 10,
                      right: 16,
                      child: ElevatedButton(
                        onPressed: () => _showSupplementDialog(context, habitProvider),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          backgroundColor: Colors.white.withOpacity(0.2),
                          padding: EdgeInsets.all(10),
                        ),
                        child: Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // 习惯列表
          Expanded(
            child: habitProvider.habits.isEmpty
                ? Center(
                    child: Text('暂无习惯，点击右下角添加'),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: habitProvider.habits.length,
                    itemBuilder: (context, index) {
                      final habit = habitProvider.habits[index];
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
                              content: Text('确定要删除习惯 "${habit.name}" 吗？'),
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
                            await habitProvider.deleteHabit(habit.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${habit.name} 已删除')),
                              );
                            }
                          }
                          return confirmDelete ?? false;
                        },
                        child: GestureDetector(
                          onLongPress: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddHabitPage(habitToEdit: habit),
                            ),
                          ),
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
                                            // 调用addTrackingRecord方法，传入当前时间和0时长
                                            habit.addTrackingRecord(DateTime.now(), Duration.zero);
                                            habitProvider.updateHabit(habit);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${habit.name} 打卡成功')),
                                            );
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  final uuid = Uuid();

  void _showSupplementDialog(BuildContext context, HabitProvider provider) {
    if (provider.habits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('暂无习惯，请先添加习惯')),
      );
      return;
    }

    Habit? selectedHabit;
    Duration? trackingDuration;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('补充打卡'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<Habit>(
                    value: selectedHabit,
                    hint: const Text('选择习惯'),
                    items: provider.habits.map((habit) {
                      return DropdownMenuItem(
                        value: habit,
                        child: Row(
                          children: [
                            Icon(
                              Icons.add,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(habit.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedHabit = value;
                        trackingDuration = value?.trackTime == true ? Duration(minutes: 30) : null;
                      });
                    },
                    isExpanded: true,
                  ),
                  if (selectedHabit?.trackTime == true) ...[
                    SizedBox(height: 12),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '追踪时间（分钟）',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            trackingDuration = Duration(minutes: int.parse(value));
                          });
                        }
                      },
                      controller: TextEditingController(
                        text: trackingDuration?.inMinutes.toString() ?? '30',
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('确认'),
                  onPressed: () async {
                    if (selectedHabit != null) {
                      try {
                        provider.stopTracking(
                          selectedHabit!.id,
                          trackingDuration ?? Duration(minutes: 0),
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('补充打卡成功！')),
                          );
                        }
                      } catch (e) {
                        print('补充打卡时发生错误: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('补充打卡失败: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // _showAddHabitDialog方法已被移除，使用AddHabitPage替代
  // void _showAddHabitDialog(BuildContext context, HabitProvider provider) {
  //   // 方法内容已迁移到AddHabitPage
  // }

  // 删除了_showActionDialog和_showEditHabitDialog方法，直接使用AddHabitPage进行编辑

  // void _showEditHabitDialog(BuildContext context, HabitProvider provider, Habit habit) {
  //   // 方法内容已迁移到AddHabitPage
  // }
}