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
  static const int _historyRangeDays = 365;
  static const int _mockRecordCount = 480;
  static const int _monthlyCoverageCount = 12;
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

  /// 创建 6 个习惯，并生成覆盖过去一年的 480 条记录。
  ///
  /// 每个习惯在最近 12 个自然月中至少有一条记录，同时显式包含
  /// 一年前和今天两个边界，确保年趋势、日历和时间轴都有完整测试数据。
  static List<Habit> generateMockHabitsWithData({
    DateTime? referenceDate,
    Random? random,
  }) {
    final List<Habit> habits = [];
    final randomSource = random ?? _random;
    final referenceMoment = referenceDate ?? DateTime.now();
    final today = _dateOnly(referenceMoment);
    final earliestDate = today.subtract(
      const Duration(days: _historyRangeDays),
    );

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
        shortDescription: Habit.defaultShortDescription,
        trackTime: true, // 所有习惯都跟踪时间
        colorValue: _colors[i].toARGB32(),
        trackingDurations: {},
        dailyCompletionStatus: {},
      );
      habits.add(habit);
    }

    var generatedRecordCount = 0;

    // 先为每个习惯铺满最近 12 个自然月，避免纯随机数据造成月份空洞。
    for (var habitIndex = 0; habitIndex < habits.length; habitIndex++) {
      for (
        var monthOffset = 0;
        monthOffset < _monthlyCoverageCount;
        monthOffset++
      ) {
        final recordDay = _dateInPreviousMonth(
          today: today,
          monthOffset: monthOffset,
          seed: habitIndex * _monthlyCoverageCount + monthOffset,
        );
        _addRecord(
          habits[habitIndex],
          _timestampOnDay(recordDay, referenceMoment, randomSource),
          _randomDuration(randomSource, minimumMinutes: 5, maximumMinutes: 60),
        );
        generatedRecordCount++;
      }
    }

    // 显式覆盖一年前和今天，保证测试数据的可见范围确实跨越一年。
    _addRecord(
      habits.first,
      _timestampOnDay(earliestDate, referenceMoment, randomSource),
      _randomDuration(randomSource, minimumMinutes: 5, maximumMinutes: 60),
    );
    generatedRecordCount++;
    _addRecord(
      habits[1],
      _timestampOnDay(today, referenceMoment, randomSource),
      _randomDuration(randomSource, minimumMinutes: 5, maximumMinutes: 60),
    );
    generatedRecordCount++;

    // 剩余记录随机分布在完整年度范围内，保留自然的数据密度和同日多次场景。
    while (generatedRecordCount < _mockRecordCount) {
      final habit = habits[randomSource.nextInt(habits.length)];
      final recordDay = earliestDate.add(
        Duration(days: randomSource.nextInt(_historyRangeDays + 1)),
      );
      _addRecord(
        habit,
        _timestampOnDay(recordDay, referenceMoment, randomSource),
        _randomDuration(randomSource, minimumMinutes: 5, maximumMinutes: 60),
      );
      generatedRecordCount++;
    }

    // currentDays 表示记录天数而不是记录次数，按日期去重后统一回填。
    for (final habit in habits) {
      habit.currentDays = habit.dailyCompletionStatus.entries
          .where((entry) => entry.value)
          .length;
    }

    return habits;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _dateInPreviousMonth({
    required DateTime today,
    required int monthOffset,
    required int seed,
  }) {
    final monthStart = DateTime(today.year, today.month - monthOffset);
    final monthEndDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final latestAllowedDay = monthOffset == 0
        ? min(today.day, monthEndDay)
        : monthEndDay;
    final day = 1 + seed % latestAllowedDay;
    return DateTime(monthStart.year, monthStart.month, day);
  }

  static DateTime _timestampOnDay(
    DateTime day,
    DateTime referenceMoment,
    Random random,
  ) {
    final normalizedDay = _dateOnly(day);
    final isToday = normalizedDay == _dateOnly(referenceMoment);
    final latestMinute = isToday
        ? max(1, referenceMoment.hour * 60 + referenceMoment.minute + 1)
        : 24 * 60;
    final minuteOfDay = random.nextInt(latestMinute);
    return normalizedDay.add(Duration(minutes: minuteOfDay));
  }

  static Duration _randomDuration(
    Random random, {
    required int minimumMinutes,
    required int maximumMinutes,
  }) {
    return Duration(
      minutes:
          minimumMinutes + random.nextInt(maximumMinutes - minimumMinutes + 1),
    );
  }

  static void _addRecord(Habit habit, DateTime timestamp, Duration duration) {
    final dateKey = _dateOnly(timestamp);
    habit.dailyCompletionStatus[dateKey] = true;
    habit.totalDuration += duration;
    habit.trackingDurations.putIfAbsent(timestamp, () => []).add(duration);
  }

  /// 生成测试数据并保存到HabitProvider
  /// 这个方法可以直接在应用中调用，用于快速创建测试数据
  static Future<void> generateAndSaveTestData({
    required AddHabitUseCase addHabitUseCase,
    required BuildContext context,
    required Future<void> Function() onDataSaved,
  }) async {
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 生成 6 个习惯并添加覆盖过去一年的 480 条数据
      final habits = generateMockHabitsWithData();

      // 为生成的习惯添加专注数据
      _generateFocusDataForHabits(habits);

      // 保存所有习惯（包含专注数据）
      for (final habit in habits) {
        await addHabitUseCase.execute(habit);
      }

      // Debug 数据绕过了 HabitProvider 直接写入仓库，写完后必须重新加载
      // Provider，确保所有正在监听习惯数据的页面立即得到一致状态。
      await onDataSaved();

      if (!context.mounted) {
        return;
      }

      // 关闭加载对话框
      Navigator.pop(context);

      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('测试数据生成成功！已创建6个习惯，并生成覆盖过去一年的480条记录及专注数据')),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

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
    final referenceMoment = DateTime.now();
    final today = _dateOnly(referenceMoment);
    final earliestDate = today.subtract(
      const Duration(days: _historyRangeDays),
    );

    // 为每个习惯生成5条专注记录
    for (final habit in habits) {
      // 只对跟踪时间的习惯生成专注数据
      if (habit.trackTime) {
        for (int i = 0; i < 5; i++) {
          // 随机选择过去一年内的日期
          final recordDay = earliestDate.add(
            Duration(days: _random.nextInt(_historyRangeDays + 1)),
          );
          final timestamp = _timestampOnDay(
            recordDay,
            referenceMoment,
            _random,
          );

          // 随机生成专注持续时间（15-90分钟）
          final duration = _randomDuration(
            _random,
            minimumMinutes: 15,
            maximumMinutes: 90,
          );

          // 直接在Habit对象上添加专注记录
          // 使用HabitService添加追踪记录
          sl<HabitService>().addTrackingRecord(habit, timestamp, duration);
        }
      }
    }
  }
}
