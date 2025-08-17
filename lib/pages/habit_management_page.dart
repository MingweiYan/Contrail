import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import './habit_tracking_page.dart';

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
        onPressed: () => _showAddHabitDialog(context, habitProvider),
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
                  top: 40,
                  right: 16,
                  child: ElevatedButton(
                    onPressed: () => _showSupplementDialog(context, habitProvider),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: EdgeInsets.all(10),
                    ),
                    child: Icon(Icons.add, color: Colors.white),
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
                        onDismissed: (direction) async {
                          await habitProvider.deleteHabit(habit.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${habit.name} 已删除')),
                          );
                        },
                        child: GestureDetector(
                          onLongPress: () => _showEditHabitDialog(context, habitProvider, habit),
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
                                        image: AssetImage(habit.imagePath!),
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              IconData(
                                                int.parse(habit.icon, radix: 16),
                                                fontFamily: 'MaterialIcons',
                                              ),
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                habit.name,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '当前: ${habit.currentCount}/${habit.targetCount ?? '无'} 次',
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HabitTrackingPage(habit: habit),
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          backgroundColor: Colors.blueAccent,
                                        ),
                                        child: Text(habit.targetDays != null ? '开始' : '打卡'),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  // 进度环
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value: habit.targetCount != null
                                                  ? habit.currentCount / habit.targetCount!
                                                  : 0,
                                              strokeWidth: 8,
                                              backgroundColor: Colors.grey[200],
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                habit.targetCount != null &&
                                                        habit.currentCount >= habit.targetCount!
                                                    ? Colors.green
                                                    : Colors.blueAccent,
                                              ),
                                            ),
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  habit.targetCount != null
                                                      ? '${(habit.currentCount / habit.targetCount! * 100).round()}%'
                                                      : '0%',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '完成率',
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
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
                              IconData(
                                int.parse(habit.icon, radix: 16),
                                fontFamily: 'MaterialIcons',
                              ),
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
                        trackingDuration = value?.targetDays != null ? Duration(minutes: 30) : null;
                      });
                    },
                    isExpanded: true,
                  ),
                  if (selectedHabit?.targetDays != null) ...[
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

  void _showAddHabitDialog(BuildContext context, HabitProvider provider) {
    final nameController = TextEditingController();
    final targetCountController = TextEditingController();
    final targetDaysController = TextEditingController();
    GoalType selectedGoalType = GoalType.none;
    String selectedIcon = 'emoji_events';
    String? selectedImagePath;
    final Map<String, IconData> addIconOptions = {
      'emoji_events': Icons.emoji_events,
      'book': Icons.book,
      'fitness_center': Icons.fitness_center,
      'music_note': Icons.music_note,
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('添加习惯'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
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
                  DropdownButton<String>(
                    value: selectedIcon,
                    hint: const Text('选择图标'),
                    items: [
                      DropdownMenuItem(value: 'emoji_events', child: Row(children: [Icon(Icons.emoji_events), SizedBox(width: 8), Text('成就')])),
                      DropdownMenuItem(value: 'book', child: Row(children: [Icon(Icons.book), SizedBox(width: 8), Text('阅读')])),
                      DropdownMenuItem(value: 'fitness_center', child: Row(children: [Icon(Icons.fitness_center), SizedBox(width: 8), Text('运动')])),
                      DropdownMenuItem(value: 'music_note', child: Row(children: [Icon(Icons.music_note), SizedBox(width: 8), Text('音乐')])),
                    ],
                    onChanged: (value) => setState(() => selectedIcon = value!),
                    isExpanded: true,
                  ),
                  SizedBox(height: 12),
                  DropdownButton<GoalType>(
                    value: selectedGoalType,
                    hint: const Text('选择目标类型'),
                    items: const [
                      DropdownMenuItem(value: GoalType.none, child: Text('无目标')),
                      DropdownMenuItem(value: GoalType.positive, child: Text('正向目标')),
                      DropdownMenuItem(value: GoalType.negative, child: Text('反向目标')),
                    ],
                    onChanged: (value) => setState(() => selectedGoalType = value!),
                    isExpanded: true,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: targetCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '目标次数',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: targetDaysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '目标天数',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('添加'),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                        try {
                          await provider.addHabit(Habit(
                            id: uuid.v4(),
                            name: nameController.text,
                            icon: addIconOptions[selectedIcon]!.codePoint.toRadixString(16),
                            goalType: selectedGoalType,
                            imagePath: selectedImagePath,
                            targetCount: int.tryParse(targetCountController.text),
                            targetDays: int.tryParse(targetDaysController.text),
                          ));
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('习惯添加成功！')),
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
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showActionDialog(BuildContext context, HabitProvider provider, Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('操作选择'),
        actions: [
          TextButton(
            child: const Text('编辑'),
            onPressed: () {
              Navigator.pop(context);
              _showEditHabitDialog(context, provider, habit);
            },
          ),
          TextButton(
            child: const Text('删除'),
            style: TextButton.styleFrom(textStyle: TextStyle(color: Colors.red)),
            onPressed: () async {
              await provider.deleteHabit(habit.id);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditHabitDialog(BuildContext context, HabitProvider provider, Habit habit) {
    final nameController = TextEditingController(text: habit.name);
    final targetCountController = TextEditingController(text: habit.targetCount?.toString() ?? '');
    final targetDaysController = TextEditingController(text: habit.targetDays?.toString() ?? '');
    GoalType selectedGoalType = habit.goalType;
    final Map<String, IconData> iconOptions = {
      'emoji_events': Icons.emoji_events,
      'book': Icons.book,
      'fitness_center': Icons.fitness_center,
      'music_note': Icons.music_note,
    };
    int codePoint = int.parse(habit.icon, radix: 16);
    String selectedIconName = 'emoji_events';
    String? selectedImagePath = habit.imagePath;

    for (var entry in iconOptions.entries) {
      if (entry.value.codePoint == codePoint) {
        selectedIconName = entry.key;
        break;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('编辑习惯'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
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
                  DropdownButton<String>(
                    value: selectedIconName,
                    hint: const Text('选择图标'),
                    items: [
                      DropdownMenuItem(value: 'emoji_events', child: Row(children: [Icon(Icons.emoji_events), SizedBox(width: 8), Text('成就')])),
                      DropdownMenuItem(value: 'book', child: Row(children: [Icon(Icons.book), SizedBox(width: 8), Text('阅读')])),
                      DropdownMenuItem(value: 'fitness_center', child: Row(children: [Icon(Icons.fitness_center), SizedBox(width: 8), Text('运动')])),
                      DropdownMenuItem(value: 'music_note', child: Row(children: [Icon(Icons.music_note), SizedBox(width: 8), Text('音乐')])),
                    ],
                    onChanged: (value) => setState(() => selectedIconName = value!),
                    isExpanded: true,
                  ),
                  SizedBox(height: 12),
                  DropdownButton<GoalType>(
                    value: selectedGoalType,
                    hint: const Text('选择目标类型'),
                    items: const [
                      DropdownMenuItem(value: GoalType.none, child: Text('无目标')),
                      DropdownMenuItem(value: GoalType.positive, child: Text('正向目标')),
                      DropdownMenuItem(value: GoalType.negative, child: Text('反向目标')),
                    ],
                    onChanged: (value) => setState(() => selectedGoalType = value!),
                    isExpanded: true,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '目标次数',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    controller: targetCountController,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '目标天数',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    controller: targetDaysController,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('保存'),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final updatedHabit = Habit(
                        id: habit.id,
                        name: nameController.text,
                        icon: iconOptions[selectedIconName]!.codePoint.toRadixString(16),
                        currentCount: habit.currentCount,
                        currentDays: habit.currentDays,
                        targetCount: int.tryParse(targetCountController.text),
                        targetDays: int.tryParse(targetDaysController.text),
                        goalType: selectedGoalType,
                        imagePath: selectedImagePath,
                        trackingRecords: habit.trackingRecords,
                      );
                      await provider.updateHabit(updatedHabit);
                      if (mounted) Navigator.pop(context);
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
}