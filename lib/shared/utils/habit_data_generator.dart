import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:contrail/features/habit/domain/use_cases/add_habit_use_case.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/services/habit_service.dart';

/// 习惯数据生成器，用于创建测试数据
class HabitDataGenerator {
  static final Random _random = Random();
  static final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
  ];

  static final List<String> _icons = [
    'directions_run', // 对应running
    'book',
    'water_drop', // 对应water
    'self_improvement', // 对应meditation
    'fitness_center', // 对应workout
    'bedtime', // 对应sleep
    'menu_book', // 对应reading
    'sports_kabaddi', // 对应yoga
    'code', // 对应coding
    'music_note', // 对应music
  ];

  static final List<String> _habitNames = ['晨跑', '阅读', '喝水', '冥想', '健身', '早睡'];

  /// 为习惯生成默认的富文本描述JSON
  static String _generateDefaultRichTextDescription(String habitName) {
    // 定义默认的富文本模板
    final richTextTemplate = [
      {
        "insert": "🌟 $habitName 的小提示 🌟\n",
        "attributes": {"heading": 2},
      },
      {"insert": "\n"},
      {
        "insert": "📚 坚持是成功的关键，每天进步一点点。\n",
        "attributes": {"list": "bullet"},
      },
      {
        "insert": "📈 记录你的进步，看到自己的成长。\n",
        "attributes": {"list": "bullet"},
      },
      {
        "insert": "🎯 设定明确的目标，让习惯成为自然。\n",
        "attributes": {"list": "bullet"},
      },
    ];

    return jsonEncode(richTextTemplate);
  }

  /// 创建6个习惯并在过去一个月内随机生成100条数据
  static List<Habit> generateMockHabitsWithData() {
    final List<Habit> habits = [];

    // 创建6个习惯
    for (int i = 0; i < 6; i++) {
      final habit = Habit(
        id: 'habit_$i',
        name: _habitNames[i],
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
        icon: _icons[i],
        descriptionJson: _generateDefaultRichTextDescription(
          _habitNames[i],
        ), // 添加富文本描述
        trackTime: true, // 所有习惯都跟踪时间
        colorValue: _colors[i].toARGB32(),
        trackingDurations: {},
        dailyCompletionStatus: {},
      );
      habits.add(habit);
    }

    // 在过去一个月内随机生成100条数据
    final DateTime today = DateTime.now();
    final DateTime oneMonthAgo = today.subtract(const Duration(days: 30));

    // 生成100条随机数据
    for (int i = 0; i < 100; i++) {
      // 随机选择一个习惯
      final habitIndex = _random.nextInt(habits.length);
      final habit = habits[habitIndex];

      // 随机选择过去一个月内的日期
      final int randomDays = _random.nextInt(30);
      final DateTime randomDate = oneMonthAgo.add(Duration(days: randomDays));
      final dateKey = DateTime(
        randomDate.year,
        randomDate.month,
        randomDate.day,
      );

      // 随机决定是否完成
      final bool isCompleted = _random.nextBool();

      if (isCompleted) {
        // 更新完成状态
        habit.dailyCompletionStatus[dateKey] = true;
        habit.currentDays++;

        // 如果习惯跟踪时间，添加时间数据
        if (habit.trackTime) {
          // 随机生成持续时间（5-60分钟）
          final int minutes = 5 + _random.nextInt(56);
          final duration = Duration(minutes: minutes);

          // 更新总持续时间
          habit.totalDuration += duration;

          // 添加到当天的跟踪时间列表
          if (!habit.trackingDurations.containsKey(dateKey)) {
            habit.trackingDurations[dateKey] = [];
          }
          habit.trackingDurations[dateKey]!.add(duration);
        }
      } else {
        // 如果已存在该日期的完成状态，删除它
        habit.dailyCompletionStatus.remove(dateKey);
      }
    }

    return habits;
  }

  /// 生成测试数据并保存到HabitProvider
  /// 这个方法可以直接在应用中调用，用于快速创建测试数据
  static Future<void> generateAndSaveTestData({
    required AddHabitUseCase addHabitUseCase,
    required BuildContext context,
  }) async {
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 生成6个习惯并添加100条数据
      final habits = generateMockHabitsWithData();

      // 为生成的习惯添加专注数据
      _generateFocusDataForHabits(habits);

      // 保存所有习惯（包含专注数据）
      for (final habit in habits) {
        await addHabitUseCase.execute(habit);
      }

      // 关闭加载对话框
      Navigator.pop(context);

      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('测试数据生成成功！已创建6个习惯并生成100条数据，包括对应的专注数据')),
      );
    } catch (e) {
      // 关闭加载对话框
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // 显示错误消息
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('生成测试数据失败: $e')));
    }
  }

  /// 为习惯生成对应的专注数据
  static void _generateFocusDataForHabits(List<Habit> habits) {
    final today = DateTime.now();
    final oneMonthAgo = today.subtract(const Duration(days: 30));

    // 为每个习惯生成5条专注记录
    for (final habit in habits) {
      // 只对跟踪时间的习惯生成专注数据
      if (habit.trackTime) {
        for (int i = 0; i < 5; i++) {
          // 随机选择过去一个月内的日期
          final int randomDays = _random.nextInt(30);
          final DateTime randomDate = oneMonthAgo.add(
            Duration(days: randomDays),
          );

          // 随机生成专注持续时间（15-90分钟）
          final int minutes = 15 + _random.nextInt(76);
          final duration = Duration(minutes: minutes);

          // 直接在Habit对象上添加专注记录
          // 使用HabitService添加追踪记录
          sl<HabitService>().addTrackingRecord(habit, randomDate, duration);
        }
      }
    }
  }
}
