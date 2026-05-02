import 'package:flutter/material.dart'; // 导入Material包以使用Color类
import 'package:hive/hive.dart';
import 'goal_type.dart';
import 'cycle_type.dart';
part 'habit.g.dart';

// 图片来源枚举
enum ImageSourceType { gallery, assets }

// 跟踪模式枚举
enum TrackingMode { stopwatch, pomodoro, countdown }

@HiveType(typeId: 0)
class Habit extends HiveObject {
  static const String defaultShortDescription = '点击查看详情，双击追踪专注，长按编辑习惯';
  // firt part is about property

  // unique id
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(9)
  String? imagePath;

  @HiveField(10)
  CycleType? cycleType;

  @HiveField(15)
  String? icon; // 习惯图标路径或标识符

  @HiveField(16)
  String? descriptionJson; // 富文本描述的JSON字符串

  @HiveField(11)
  final bool trackTime;

  @HiveField(3)
  Duration totalDuration;

  @HiveField(4)
  int currentDays;

  @HiveField(6)
  int? targetDays;

  @HiveField(7)
  GoalType goalType;

  @HiveField(8) // 使用未使用的字段索引8
  int colorValue; // 存储颜色的整数值，便于Hive存储

  @HiveField(13)
  Map<DateTime, List<Duration>> trackingDurations; // 存储每天的持续时间列表

  @HiveField(14)
  Map<DateTime, bool> dailyCompletionStatus; // 记录每天的打卡状态，true 表示当天已完成打卡

  @HiveField(17)
  int? targetTimeMinutes; // 目标时间，单位为分钟

  @HiveField(18)
  String? shortDescription; // 用于卡片等场景的简短描述

  // 获取Color对象
  Color get color => Color(colorValue);

  // 设置Color对象
  set color(Color newColor) {
    colorValue = newColor.toARGB32();
  }

  String get effectiveShortDescription {
    final value = shortDescription?.trim();
    if (value == null || value.isEmpty) {
      return defaultShortDescription;
    }
    return value;
  }

  Habit({
    required this.id,
    required this.name,
    this.totalDuration = Duration.zero,
    this.currentDays = 0,
    this.targetDays,
    this.goalType = GoalType.positive,
    this.imagePath,
    this.cycleType,
    this.icon,
    this.descriptionJson,
    this.trackTime = false,
    int? colorValue,
    Map<DateTime, List<Duration>>? trackingDurations,
    Map<DateTime, bool>? dailyCompletionStatus,
    this.targetTimeMinutes,
    this.shortDescription,
  }) : colorValue = colorValue ?? Colors.blue.toARGB32(),
       trackingDurations = trackingDurations ?? {},
       dailyCompletionStatus = dailyCompletionStatus ?? {};

  // 创建一个专门用于Hive读取的构造函数，确保colorValue在对象创建时就被正确设置
  Habit.fromHive({
    required this.id,
    required this.name,
    required this.totalDuration,
    required this.currentDays,
    this.targetDays,
    required this.goalType,
    this.imagePath,
    this.cycleType,
    this.icon,
    this.descriptionJson,
    required this.trackTime,
    required this.colorValue,
    Map<DateTime, List<Duration>>? trackingDurations,
    Map<DateTime, bool>? dailyCompletionStatus,
    this.targetTimeMinutes,
    this.shortDescription,
  }) : trackingDurations = trackingDurations ?? {},
       dailyCompletionStatus = dailyCompletionStatus ?? {};
}
