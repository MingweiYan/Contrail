import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';

/// 习惯服务类
/// 负责处理与习惯相关的业务逻辑操作
class HabitService {
  final AppLogger _logger = AppLogger();

  /// 添加习惯追踪记录
  ///
  /// 这个方法会更新习惯的完成天数、总时长和追踪记录
  ///
  /// 参数:
  /// - habit: 要添加记录的习惯对象
  /// - date: 记录的日期时间
  /// - duration: 完成的时长
  void addTrackingRecord(Habit habit, DateTime date, Duration duration) {
    _logger.debug(
      '📝  开始添加追踪记录: 日期=${date.toString()}, 时长=${duration.inMinutes}分钟',
    );

    final dateOnly = DateTime(date.year, date.month, date.day);
    final hasCompletedToday =
        habit.dailyCompletionStatus.containsKey(dateOnly) &&
        habit.dailyCompletionStatus[dateOnly] == true;

    _logger.debug(
      '🔍  检查当天打卡状态: hasCompletedToday=$hasCompletedToday, dateOnly=${dateOnly.toString()}',
    );
    _logger.debug(
      '📊  添加前状态 - 完成天数: ${habit.currentDays}, 总时长: ${habit.totalDuration.inMinutes}分钟',
    );

    // 记录完成时间
    if (!hasCompletedToday) {
      // 如果当天尚未完成打卡
      habit.currentDays++;
      habit.dailyCompletionStatus[dateOnly] = true; // 标记当天已完成打卡
      _logger.debug('✅  标记当天已完成打卡，更新后完成天数: ${habit.currentDays}');
    } else {
      _logger.debug('ℹ️  当天已经完成打卡，不增加完成天数');
    }

    habit.totalDuration += duration;
    // 修复：使用putIfAbsent和add方法确保所有记录都被保存，而不是覆盖
    habit.trackingDurations.putIfAbsent(date, () => []).add(duration);

    _logger.debug('📈  添加追踪记录完成 - 总时长: ${habit.totalDuration.inMinutes}分钟');
    _logger.debug('📋  追踪记录总数: ${habit.trackingDurations.length}');
    _logger.debug('📅  打卡天数: ${habit.dailyCompletionStatus.length}');
  }

  /// 删除习惯某次追踪记录
  ///
  /// 参数:
  /// - habit: 目标习惯
  /// - startTime: 本次记录的开始时间（键）
  /// - duration: 本次记录的持续时间（用于从列表中匹配删除）
  void removeTrackingRecord(
    Habit habit,
    DateTime startTime,
    Duration duration,
  ) {
    _logger.debug(
      '🗑️  删除追踪记录: 开始=${startTime.toIso8601String()}, 时长=${duration.inMinutes}分钟',
    );
    final dateOnly = DateTime(startTime.year, startTime.month, startTime.day);
    final list = habit.trackingDurations[startTime];
    if (list == null || list.isEmpty) {
      _logger.debug('ℹ️  未找到对应开始时间的记录，忽略删除');
      return;
    }
    // 按首次匹配的时长删除
    final removed = list.remove(duration);
    if (!removed) {
      _logger.debug('ℹ️  未匹配到相同时长的记录，忽略删除');
      return;
    }
    // 若该开始时间下无剩余记录，移除键
    if (list.isEmpty) {
      habit.trackingDurations.remove(startTime);
    } else {
      habit.trackingDurations[startTime] = list;
    }
    // 更新总时长，避免小于0
    final newTotal = habit.totalDuration - duration;
    habit.totalDuration = newTotal.isNegative ? Duration.zero : newTotal;
    // 重新评估当天是否还有记录
    bool hasAnyOnThatDay = false;
    habit.trackingDurations.forEach((dt, durations) {
      final d = DateTime(dt.year, dt.month, dt.day);
      if (d == dateOnly && durations.isNotEmpty) {
        hasAnyOnThatDay = true;
      }
    });
    if (!hasAnyOnThatDay) {
      if (habit.dailyCompletionStatus[dateOnly] == true) {
        habit.dailyCompletionStatus[dateOnly] = false;
        if (habit.currentDays > 0) {
          habit.currentDays -= 1;
        }
      }
    }
    _logger.debug(
      '✅  删除完成: 当前天数=${habit.currentDays}, 总时长=${habit.totalDuration.inMinutes}分钟',
    );
  }

  /// 检查习惯当天是否已完成
  ///
  /// 参数:
  /// - habit: 要检查的习惯对象
  ///
  /// 返回值:
  /// - 如果习惯在今天已经完成返回true，否则返回false
  bool hasCompletedToday(Habit habit) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return habit.dailyCompletionStatus.containsKey(todayOnly) &&
        habit.dailyCompletionStatus[todayOnly] == true;
  }

  /// 备份所有习惯数据
  ///
  /// 将所有习惯数据转换为可序列化的格式
  ///
  /// 参数:
  /// - habitRepository: 习惯数据仓库接口
  ///
  /// 返回值:
  /// - 包含所有习惯数据的列表，可直接用于JSON序列化
  Future<List<Map<String, dynamic>>> backupHabits(
    HabitRepository habitRepository,
  ) async {
    _logger.debug('📁  开始备份习惯数据');

    try {
      final habits = await habitRepository.getHabits();
      final result = habits
          .map(
            (habit) => {
              'id': habit.id,
              'name': habit.name,
              'totalDuration': habit.totalDuration.inMilliseconds,
              'currentDays': habit.currentDays,
              'targetDays': habit.targetDays,
              'goalType': habit.goalType.index,
              'imagePath': habit.imagePath,
              'cycleType': habit.cycleType?.index,
              'icon': habit.icon,
              'trackTime': habit.trackTime,
              'colorValue': habit.colorValue,
              'descriptionJson': habit.descriptionJson,
              'shortDescription': habit.shortDescription,
              'trackingDurations': habit.trackingDurations.map(
                (date, durations) => MapEntry(
                  date.toIso8601String(),
                  durations.map((duration) => duration.inMilliseconds).toList(),
                ),
              ),
              'dailyCompletionStatus': habit.dailyCompletionStatus.map(
                (date, completed) =>
                    MapEntry(date.toIso8601String(), completed),
              ),
              'targetTimeMinutes': habit.targetTimeMinutes,
            },
          )
          .toList();

      _logger.debug('✅  习惯数据备份完成，共备份 ${result.length} 个习惯');
      return result;
    } catch (e) {
      _logger.error('❌  备份习惯数据失败', e);
      rethrow;
    }
  }

  /// 从备份数据恢复习惯
  ///
  /// 将序列化的习惯数据恢复到数据库
  ///
  /// 参数:
  /// - habitRepository: 习惯数据仓库接口
  /// - habitsData: 从备份文件读取的习惯数据列表
  ///
  /// 返回值:
  /// - 如果恢复成功返回true，否则返回false
  Future<bool> restoreHabits(
    HabitRepository habitRepository,
    List<dynamic> habitsData,
  ) async {
    late final List<Habit> restoredHabits;
    try {
      _logger.debug('🔄  开始恢复习惯数据，共 ${habitsData.length} 个习惯');
      restoredHabits = _parseHabits(habitsData);
    } catch (e) {
      _logger.error('❌  备份习惯数据校验失败', e);
      return false;
    }

    List<Habit>? originalHabits;
    try {
      originalHabits = List<Habit>.of(await habitRepository.getHabits());
      await _replaceHabits(
        habitRepository,
        currentHabits: originalHabits,
        replacementHabits: restoredHabits,
      );

      _logger.debug('✅  习惯数据恢复完成');
      return true;
    } catch (e) {
      _logger.error('❌  习惯数据恢复失败，正在回滚', e);
      if (originalHabits != null) {
        try {
          final currentHabits = await habitRepository.getHabits();
          await _replaceHabits(
            habitRepository,
            currentHabits: currentHabits,
            replacementHabits: originalHabits,
          );
          _logger.debug('✅  习惯数据已回滚到恢复前状态');
        } catch (rollbackError) {
          _logger.error('❌  习惯数据回滚失败', rollbackError);
        }
      }
      return false;
    }
  }

  List<Habit> _parseHabits(List<dynamic> habitsData) {
    final restoredHabits = <Habit>[];
    final habitIds = <String>{};

    for (var index = 0; index < habitsData.length; index++) {
      final habitMap = _stringKeyedMap(habitsData[index], 'habits[$index]');
      final habit = _parseHabit(habitMap, index);
      if (!habitIds.add(habit.id)) {
        throw FormatException('habits[$index].id is duplicated: ${habit.id}');
      }
      restoredHabits.add(habit);
    }

    return restoredHabits;
  }

  Habit _parseHabit(Map<String, dynamic> habitMap, int index) {
    final fieldPrefix = 'habits[$index]';
    final id = _requiredString(habitMap, 'id', fieldPrefix);
    final name = _requiredString(habitMap, 'name', fieldPrefix);
    if (id.trim().isEmpty) {
      throw FormatException('$fieldPrefix.id must not be empty');
    }
    if (name.trim().isEmpty) {
      throw FormatException('$fieldPrefix.name must not be empty');
    }

    return Habit(
      id: id,
      name: name,
      totalDuration: Duration(
        milliseconds: _nonNegativeInt(habitMap, 'totalDuration', fieldPrefix),
      ),
      currentDays: _nonNegativeInt(habitMap, 'currentDays', fieldPrefix),
      targetDays: _nullableNonNegativeInt(habitMap, 'targetDays', fieldPrefix),
      goalType: _enumValue(
        GoalType.values,
        habitMap['goalType'],
        '$fieldPrefix.goalType',
      ),
      imagePath: _nullableString(habitMap, 'imagePath', fieldPrefix),
      cycleType: _nullableEnumValue(
        CycleType.values,
        habitMap['cycleType'],
        '$fieldPrefix.cycleType',
      ),
      icon: _nullableString(habitMap, 'icon', fieldPrefix),
      trackTime: _requiredBool(habitMap, 'trackTime', fieldPrefix),
      colorValue: _nullableInt(habitMap, 'colorValue', fieldPrefix),
      descriptionJson: _nullableString(
        habitMap,
        'descriptionJson',
        fieldPrefix,
      ),
      shortDescription: _nullableString(
        habitMap,
        'shortDescription',
        fieldPrefix,
      ),
      trackingDurations: _parseTrackingDurations(
        habitMap['trackingDurations'],
        '$fieldPrefix.trackingDurations',
      ),
      dailyCompletionStatus: _parseDailyCompletionStatus(
        habitMap['dailyCompletionStatus'],
        '$fieldPrefix.dailyCompletionStatus',
      ),
      targetTimeMinutes: _nullableNonNegativeInt(
        habitMap,
        'targetTimeMinutes',
        fieldPrefix,
      ),
    );
  }

  Map<DateTime, List<Duration>> _parseTrackingDurations(
    Object? value,
    String fieldName,
  ) {
    if (value == null) return <DateTime, List<Duration>>{};
    final source = _stringKeyedMap(value, fieldName);
    final result = <DateTime, List<Duration>>{};

    for (final entry in source.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) {
        throw FormatException('$fieldName contains an invalid date');
      }
      final durations = entry.value;
      if (durations is! List) {
        throw FormatException('$fieldName.${entry.key} must be a list');
      }
      result[date] = durations.indexed
          .map((indexedValue) {
            final (durationIndex, durationValue) = indexedValue;
            if (durationValue is! int || durationValue < 0) {
              throw FormatException(
                '$fieldName.${entry.key}[$durationIndex] must be a non-negative integer',
              );
            }
            return Duration(milliseconds: durationValue);
          })
          .toList(growable: false);
    }
    return result;
  }

  Map<DateTime, bool> _parseDailyCompletionStatus(
    Object? value,
    String fieldName,
  ) {
    if (value == null) return <DateTime, bool>{};
    final source = _stringKeyedMap(value, fieldName);
    final result = <DateTime, bool>{};

    for (final entry in source.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) {
        throw FormatException('$fieldName contains an invalid date');
      }
      if (entry.value is! bool) {
        throw FormatException('$fieldName.${entry.key} must be a boolean');
      }
      result[date] = entry.value as bool;
    }
    return result;
  }

  Future<void> _replaceHabits(
    HabitRepository habitRepository, {
    required List<Habit> currentHabits,
    required List<Habit> replacementHabits,
  }) async {
    for (final habit in currentHabits) {
      await habitRepository.deleteHabit(habit.id);
    }
    for (final habit in replacementHabits) {
      await habitRepository.addHabit(habit);
    }
  }

  Map<String, dynamic> _stringKeyedMap(Object? value, String fieldName) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw FormatException('$fieldName must be an object');
    }
    return value.map((key, item) => MapEntry(key as String, item));
  }

  String _requiredString(
    Map<String, dynamic> source,
    String key,
    String fieldPrefix,
  ) {
    final value = source[key];
    if (value is! String) {
      throw FormatException('$fieldPrefix.$key must be a string');
    }
    return value;
  }

  String? _nullableString(
    Map<String, dynamic> source,
    String key,
    String fieldPrefix,
  ) {
    final value = source[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('$fieldPrefix.$key must be a string or null');
    }
    return value;
  }

  bool _requiredBool(
    Map<String, dynamic> source,
    String key,
    String fieldPrefix,
  ) {
    final value = source[key];
    if (value is! bool) {
      throw FormatException('$fieldPrefix.$key must be a boolean');
    }
    return value;
  }

  int _nonNegativeInt(
    Map<String, dynamic> source,
    String key,
    String fieldPrefix,
  ) {
    final value = source[key];
    if (value is! int || value < 0) {
      throw FormatException('$fieldPrefix.$key must be a non-negative integer');
    }
    return value;
  }

  int? _nullableNonNegativeInt(
    Map<String, dynamic> source,
    String key,
    String fieldPrefix,
  ) {
    final value = source[key];
    if (value == null) return null;
    if (value is! int || value < 0) {
      throw FormatException(
        '$fieldPrefix.$key must be a non-negative integer or null',
      );
    }
    return value;
  }

  int? _nullableInt(
    Map<String, dynamic> source,
    String key,
    String fieldPrefix,
  ) {
    final value = source[key];
    if (value == null) return null;
    if (value is! int) {
      throw FormatException('$fieldPrefix.$key must be an integer or null');
    }
    return value;
  }

  T _enumValue<T>(List<T> values, Object? value, String fieldName) {
    if (value is! int || value < 0 || value >= values.length) {
      throw FormatException('$fieldName is out of range');
    }
    return values[value];
  }

  T? _nullableEnumValue<T>(List<T> values, Object? value, String fieldName) {
    if (value == null) return null;
    return _enumValue(values, value, fieldName);
  }

  /// 根据周期类型获取最大天数限制
  int getMaxDaysForCycleType(CycleType? cycleType) {
    if (cycleType == CycleType.daily) {
      return 1; // 每日习惯，固定为1天
    } else if (cycleType == CycleType.weekly) {
      return 7; // 每周最大7天
    } else if (cycleType == CycleType.monthly) {
      return 31; // 每月最大31天
    }
    return 7; // 默认每周最大7天
  }

  /// 根据目标天数获取最大时间值（天数*8小时，单位为分钟）
  int getMaxTimeMinutes(int targetDays) {
    return targetDays * 480; // 天数*8小时(480分钟)，转换为分钟
  }

  /// 计算默认目标时间（按照次数乘半小时的结果作为默认值，单位为分钟）
  int calculateDefaultTargetTimeMinutes(int targetDays) {
    int targetTimeMinutes = targetDays * 30; // 每天30分钟
    final maxTimeMinutes = getMaxTimeMinutes(targetDays);

    // 确保不小于最小时间限制
    if (targetTimeMinutes < 5) {
      targetTimeMinutes = 5;
    }

    // 确保不超过最大时间限制
    if (targetTimeMinutes > maxTimeMinutes) {
      targetTimeMinutes = maxTimeMinutes;
    }

    return targetTimeMinutes;
  }

  /// 创建习惯对象
  Habit createHabit({
    required String id,
    required String name,
    required int targetDays,
    required GoalType goalType,
    String? icon,
    String? descriptionJson,
    String? shortDescription,
    CycleType? cycleType,
    required bool trackTime,
    int? colorValue,
    int currentDays = 0,
    Duration totalDuration = Duration.zero,
    Map<DateTime, List<Duration>> trackingDurations = const {},
    Map<DateTime, bool> dailyCompletionStatus = const {},
    int? targetTimeMinutes,
  }) {
    return Habit(
      id: id,
      name: name.trim(),
      targetDays: targetDays,
      goalType: goalType,
      icon: icon,
      descriptionJson: descriptionJson,
      shortDescription: shortDescription,
      cycleType: cycleType,
      trackTime: trackTime,
      colorValue: colorValue,
      currentDays: currentDays,
      totalDuration: totalDuration,
      trackingDurations: trackingDurations,
      dailyCompletionStatus: dailyCompletionStatus,
      targetTimeMinutes: targetTimeMinutes,
    );
  }

  /// 保存习惯
  Future<void> saveHabit(
    HabitProvider habitProvider,
    Habit habit,
    bool isUpdating,
  ) async {
    _logger.debug('保存习惯: id=${habit.id}, 名称=${habit.name}, 是更新操作=$isUpdating');

    if (isUpdating) {
      await habitProvider.updateHabit(habit);
      _logger.debug('习惯更新成功: id=${habit.id}');
    } else {
      await habitProvider.addHabit(habit);
      _logger.debug('习惯添加成功: id=${habit.id}');
    }
  }
}
