import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/habit/domain/use_cases/get_habits_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/add_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/delete_habit_use_case.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/habit/presentation/pages/add_habit_page.dart';
import 'package:contrail/features/habit/presentation/pages/habit_tracking_page.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:provider/provider.dart';
import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/icon_helper.dart';
import 'package:contrail/core/state/focus_state.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/features/statistics/presentation/pages/habit_detail_statistics_page.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


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
  int _daysUsed = 0; // 存储用户使用天数

  @override
  void initState() {
    super.initState();
    _getHabitsUseCase = sl<GetHabitsUseCase>();
    _addHabitUseCase = sl<AddHabitUseCase>();
    _updateHabitUseCase = sl<UpdateHabitUseCase>();
    _deleteHabitUseCase = sl<DeleteHabitUseCase>();
    _loadHabits();
    _calculateDaysUsed();
  }
  
  // 计算用户使用天数
  Future<void> _calculateDaysUsed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstLaunchDateStr = prefs.getString('firstLaunchDate');
      
      if (firstLaunchDateStr != null) {
        final firstLaunchDate = DateTime.parse(firstLaunchDateStr);
        final now = DateTime.now();
        // 计算天数差
        final daysDifference = now.difference(firstLaunchDate).inDays;
        // 确保天数不为负数，至少为1天
        setState(() {
          _daysUsed = daysDifference >= 0 ? daysDifference + 1 : 1;
        });
        logger.debug('计算用户使用天数: $_daysUsed天 (首次启动日期: $firstLaunchDate)');
      } else {
        // 如果没有找到首次启动日期，使用默认值1天
        setState(() {
          _daysUsed = 1;
        });
        logger.warning('未找到首次启动日期，使用默认值1天');
      }
    } catch (e) {
      logger.error('计算用户使用天数失败', e);
      // 发生错误时使用默认值1天
      setState(() {
        _daysUsed = 1;
      });
    }
  }

  Future<void> _loadHabits() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final habits = await _getHabitsUseCase.execute();
      setState(() {
        _habits = habits;
      });
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
    TimeOfDay selectedTime = TimeOfDay.now();
    int durationMinutes = 30; // 默认时长30分钟

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(24)),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
                    ),
              borderRadius: BorderRadius.circular(ScreenUtil().setWidth(24)),
            ),
            padding: EdgeInsets.all(ScreenUtil().setWidth(24)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Center(
                    child: Text(
                      '补充记录',
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(24),
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.onPrimary(context),
                      ),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(24)),

                  // 习惯选择
                  Text(
                    '选择习惯',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(18),
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.onPrimary(context),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(8)),
                  Container(
                    decoration: BoxDecoration(
                      color: ThemeHelper.onPrimary(context).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(12)),
                    child: DropdownButton<Habit>(
                      hint: Text('选择习惯', style: TextStyle(color: ThemeHelper.onPrimary(context).withOpacity(0.7))),
                      value: selectedHabit,
                      onChanged: (Habit? newValue) {
                        setStateDialog(() {
                          selectedHabit = newValue;
                        });
                      },
                      items: _habits.map((Habit habit) {
                        return DropdownMenuItem<Habit>(
                          value: habit,
                          child: Text(habit.name, style: TextStyle(color: ThemeHelper.onPrimary(context))),
                        );
                      }).toList(),
                      isExpanded: true,
                      dropdownColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                      icon: Icon(Icons.arrow_drop_down, color: ThemeHelper.onPrimary(context)),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(20)),

                  // 日期选择
                  Text(
                    '选择日期',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(18),
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.onPrimary(context),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(8)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text(
                        '日期:',
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(20),
                          color: ThemeHelper.onPrimary(context).withOpacity(0.8),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  primaryColor: Theme.of(context).colorScheme.primary,
                                  colorScheme: ColorScheme.light(primary: Theme.of(context).colorScheme.primary),
                                  buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
                                ),
                                child: child!, 
                              );
                            },
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(selectedDate),
                          style: TextStyle(color: ThemeHelper.onPrimary(context)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(16)),

                  // 时间选择（新增的开始时间选择功能）
                  Text(
                    '选择开始时间',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(18),
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.onPrimary(context),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(8)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text(
                        '时间:',
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(20),
                          color: ThemeHelper.onPrimary(context).withOpacity(0.8),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  primaryColor: Theme.of(context).colorScheme.primary,
                                  colorScheme: ColorScheme.light(primary: Theme.of(context).colorScheme.primary),
                                  buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
                                ),
                                child: child!, 
                              );
                            },
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          selectedTime.format(context),
                          style: TextStyle(color: ThemeHelper.onPrimary(context)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(20))

                  // 时长选择（仅当习惯需要追踪时间时显示）
                  ,if (selectedHabit?.trackTime ?? false)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        Text(
                          '选择时长',
                            style: TextStyle(
                              fontSize: ScreenUtil().setSp(18),
                              fontWeight: FontWeight.w500,
                              color: ThemeHelper.onPrimary(context),
                            ),
                          ),
                          SizedBox(height: ScreenUtil().setHeight(8)),
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
                          activeColor: ThemeHelper.onPrimary(context),
                          inactiveColor: ThemeHelper.onPrimary(context).withOpacity(0.3),
                        ),
                        Center(
                          child: Text(
                            '$durationMinutes 分钟',
                            style: TextStyle(
                              fontSize: ScreenUtil().setSp(18),
                              fontWeight: FontWeight.bold,
                              color: ThemeHelper.onPrimary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: ScreenUtil().setHeight(24)),

                  // 按钮区域
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(24), vertical: ScreenUtil().setHeight(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          '取消',
                          style: TextStyle(color: ThemeHelper.onPrimary(context)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (selectedHabit == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('请选择习惯')),
                            );
                            return;
                          }

                          // 执行补充打卡 - 合并日期和时间
                          final completeDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          
                          final duration = selectedHabit!.trackTime
                            ? Duration(minutes: durationMinutes)
                            : Duration.zero;

                          selectedHabit!.addTrackingRecord(completeDateTime, duration);
                          try {
                            await _updateHabitUseCase.execute(selectedHabit!);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${selectedHabit!.name} 补充打卡成功')),
                            );
                            // 重新加载习惯列表
                            _loadHabits();
                            
                            // 通知StatisticsProvider更新数据，确保统计页面能及时刷新
                            final statisticsProvider = Provider.of<StatisticsProvider>(context, listen: false);
                            statisticsProvider.notifyListeners();
                          } catch (e) {
                            logger.error('更新习惯失败', e);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('补充打卡失败: ${e.toString()}')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.onPrimary(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(24), vertical: ScreenUtil().setHeight(12)),
                          elevation: 4,
                        ),
                        child: Text(
                          '确认',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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

  // 格式化习惯描述
  String _formatHabitDescription(Habit habit) {
    final buffer = StringBuffer();
    
    if (habit.cycleType != null && habit.targetDays != null) {
      // 如果设置了目标，显示周期和进度
      switch (habit.cycleType!) {
        case CycleType.daily:
          buffer.write('每日');
          break;
        case CycleType.weekly:
          buffer.write('每周');
          break;
        case CycleType.monthly:
          buffer.write('每月');
          break;
        case CycleType.annual:
          buffer.write('每年');
          break;
      }
      
      // 计算周期内的完成度
      int completedInCycle = _getCompletedDaysInCurrentCycle(habit);
      int totalDaysInCycle = habit.targetDays!;
      
      buffer.write(' ($completedInCycle/$totalDaysInCycle)');
      
      // 如果追踪时间，显示时间目标
      if (habit.trackTime) {
        int totalMinutesInCycle = _getTotalMinutesInCurrentCycle(habit);
        int targetMinutes = habit.targetDays! * 60; // 目标天数 * 1小时/天
        buffer.write(' · 时间: ${totalMinutesInCycle ~/ 60}h${totalMinutesInCycle % 60}m/${targetMinutes ~/ 60}h${targetMinutes % 60}m');
      }
    } else {
      // 如果没有设置目标，显示今天的完成情况
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final todayCompleted = habit.dailyCompletionStatus.containsKey(todayOnly) && habit.dailyCompletionStatus[todayOnly] == true;
      
      if (todayCompleted) {
        buffer.write('今日已完成');
      } else {
        buffer.write('今日未完成');
      }
      
      // 如果追踪时间，显示今天的专注时间
      if (habit.trackTime) {
        int todayMinutes = _getTodayMinutes(habit);
        if (todayMinutes > 0) {
          buffer.write(' · 专注 ${todayMinutes ~/ 60}h${todayMinutes % 60}m');
        }
      }
    }
    
    return buffer.toString();
  }
  
  // 获取今天的专注时长（分钟）
  int _getTodayMinutes(Habit habit) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    int totalMinutes = 0;
    
    habit.trackingDurations.forEach((date, durations) {
      if (date.year == todayOnly.year && date.month == todayOnly.month && date.day == todayOnly.day) {
        for (var duration in durations) {
          totalMinutes += duration.inMinutes;
        }
      }
    });
    
    return totalMinutes;
  }
  
  // 获取今天是否完成
  bool _isTodayCompleted(Habit habit) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return habit.dailyCompletionStatus.containsKey(todayOnly) && habit.dailyCompletionStatus[todayOnly] == true;
  }
  
  // 获取最终的进度值（考虑次数和时间完成度的最大值）
  double _getFinalProgress(Habit habit) {
    if (habit.cycleType == null || habit.targetDays == null) {
      // 没有设置目标，根据当天是否打卡判断
      return _isTodayCompleted(habit) ? 1.0 : 0.0;
    } else {
      // 有设置目标，取次数和时间完成度的最大值
      double countProgress = _getCompletionRateInCurrentCycle(habit);
      double timeProgress = habit.trackTime ? _getTimeCompletionRateInCurrentCycle(habit) : 0.0;
      return countProgress > timeProgress ? countProgress : timeProgress;
    }
  }
  
  // 获取当前周期内的完成天数
  int _getCompletedDaysInCurrentCycle(Habit habit) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (habit.cycleType!) {
      case CycleType.weekly:
        // 本周开始（周一）
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case CycleType.monthly:
        // 本月开始
        startDate = DateTime(now.year, now.month, 1);
        break;
      case CycleType.daily:
      default:
        // 今天
        startDate = DateTime(now.year, now.month, now.day);
        break;
    }
    
    int count = 0;
    habit.dailyCompletionStatus.forEach((date, completed) {
      if (completed && date.isAfter(startDate.subtract(const Duration(days: 1))) && date.isBefore(now.add(const Duration(days: 1)))) {
        count++;
      }
    });
    
    return count;
  }
  
  // 获取当前周期内的总时长（分钟）
  int _getTotalMinutesInCurrentCycle(Habit habit) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (habit.cycleType!) {
      case CycleType.weekly:
        // 本周开始（周一）
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case CycleType.monthly:
        // 本月开始
        startDate = DateTime(now.year, now.month, 1);
        break;
      case CycleType.daily:
      default:
        // 今天
        startDate = DateTime(now.year, now.month, now.day);
        break;
    }
    
    int totalMinutes = 0;
    habit.trackingDurations.forEach((date, durations) {
      if (date.isAfter(startDate.subtract(const Duration(days: 1))) && date.isBefore(now.add(const Duration(days: 1)))) {
        for (var duration in durations) {
          totalMinutes += duration.inMinutes;
        }
      }
    });
    
    return totalMinutes;
  }
  
  // 计算当前周期内的完成度（0.0-1.0）
  double _getCompletionRateInCurrentCycle(Habit habit) {
    int completed = _getCompletedDaysInCurrentCycle(habit);
    int total = habit.targetDays ?? 1;
    return completed / total;
  }
  
  // 计算当前周期内的时间完成度（0.0-1.0）
  double _getTimeCompletionRateInCurrentCycle(Habit habit) {
    if (!habit.trackTime) return 0.0;
    
    int completedMinutes = _getTotalMinutesInCurrentCycle(habit);
    int targetMinutes = habit.targetDays! * 60; // 目标天数 * 1小时/天
    return completedMinutes / targetMinutes;
  }

  // 导航到追踪页面
  void _navigateToTrackingPage(Habit habit) {
    // 检查是否有正在进行的专注会话
    final focusState = sl<FocusState>();
    if (focusState.focusStatus != FocusStatus.stop && focusState.currentFocusHabit != null) {
      // 如果正在专注的习惯与当前选择的习惯不同，显示提示
      if (focusState.currentFocusHabit!.id != habit.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已有专注正在进行中，请先结束当前专注')),
        );
        return; // 不导航到新的专注页面
      }
    }
    
    // 如果习惯设置了追踪时间，则导航到专注页面
    if (habit.trackTime) {
      // 使用async/await来等待从HabitTrackingPage返回，并刷新UI
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HabitTrackingPage(habit: habit),
        ),
      ).then((_) {
        // 从专注页面返回后刷新UI，但要先检查widget是否仍然存在
        if (mounted) {
          setState(() {
            // 重新加载习惯列表以显示更新后的进度
            _loadHabits();
          });
        }
      });
    } else {
      // 如果习惯没有设置追踪时间，则直接完成该习惯的追踪
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      habitProvider.stopTracking(habit.id, Duration(minutes: 1)); // 添加1分钟的默认追踪记录
      
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已完成 ${habit.name}')),
      );
      
      // 刷新UI以显示更新后的进度
      setState(() {
        _loadHabits();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;
    final isDarkMode = ThemeHelper.isDarkMode(context);

    return Scaffold(
      body: Container(
        decoration: ThemeHelper.generateBackgroundDecoration(context) ?? BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor, // 与主题颜色联动
        ),
        padding: EdgeInsets.all(ScreenUtil().setWidth(16)), // 添加整体页面的边距
        child: _buildHabitList(),
      ),
    );
  }

  // 计算总体习惯统计数据
  Map<String, dynamic> _calculateHabitStats() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    int completedToday = 0;
    int totalDays = 0;
    double averageStreak = 0;
    
    for (var habit in _habits) {
      totalDays += habit.currentDays;
      if (habit.dailyCompletionStatus.containsKey(todayOnly) && 
          habit.dailyCompletionStatus[todayOnly] == true) {
        completedToday++;
      }
      // 简单的平均计算，实际应更复杂地计算连续天数
    }
    
    if (_habits.isNotEmpty) {
      averageStreak = totalDays / _habits.length;
    }
    
    return {
      'completedToday': completedToday,
      'totalHabitDays': totalDays,
      'averageStreak': averageStreak
    };
  }

  Widget _buildHabitList() {
    final stats = _habits.isEmpty ? {
      'completedToday': 0,
      'totalHabitDays': 0,
      'averageStreak': 0.0
    } : _calculateHabitStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 炫酷的头部设计
        AnimatedContainer(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(24), vertical: ScreenUtil().setHeight(32)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.all(Radius.circular(ScreenUtil().setWidth(30))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我的习惯',
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: ScreenUtil().setSp(32),
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.onPrimary(context),
                ),
              ),
              SizedBox(height: ScreenUtil().setHeight(8)),
              Text(
                '从新增一个习惯出发吧！',
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: ScreenUtil().setSp(20),
                  color: ThemeHelper.onPrimary(context).withOpacity(0.9),
                ),
              ),
              SizedBox(height: ScreenUtil().setHeight(24)),
              // 功能按钮 - 与统计页面风格一致
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 第一个按钮：补充打卡
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                    ),
                    child: InkWell(
                      onTap: () {
                        _showSupplementCheckInDialog(context);
                      },
                      borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                      child: Container(
                        width: ScreenUtil().setWidth(80),
                        height: ScreenUtil().setHeight(80),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit,
                              size: ScreenUtil().setSp(28),
                              color: Colors.black,
                            ),
                            SizedBox(height: ScreenUtil().setHeight(4)),
                            Text(
                              '补充记录',
                              style: TextStyle(
                                fontSize: ScreenUtil().setSp(16),
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // 第二个按钮：查看专注
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                    ),
                    child: InkWell(
                      onTap: () {
                        // 检查是否有正在进行中的专注
                        final focusState = sl<FocusState>();
                        if (focusState.focusStatus != FocusStatus.stop && focusState.currentFocusHabit != null) {
                          // 如果有正在进行中的专注，直接进入专注页面
                          // 再次检查currentFocusHabit是否为null，防止竞态条件
                          final currentHabit = focusState.currentFocusHabit;
                          if (currentHabit != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HabitTrackingPage(habit: currentHabit),
                              ),
                            ).then((_) {
                              // 从专注页面返回后刷新UI
                              setState(() {
                                _loadHabits();
                              });
                            });
                          } else {
                            // 如果currentFocusHabit变为null，显示错误提示
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('无法获取专注信息')),
                            );
                          }
                        } else {
                          // 如果没有正在进行中的专注，提示用户
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('没有正在进行中的专注')),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                      child: Container(
                        width: ScreenUtil().setWidth(80),
                        height: ScreenUtil().setHeight(80),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer,
                              size: ScreenUtil().setSp(28),
                              color: Colors.black,
                            ),
                            SizedBox(height: ScreenUtil().setHeight(4)),
                            Text(
                              '查看专注',
                              style: TextStyle(
                                fontSize: ScreenUtil().setSp(16),
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // 第三个按钮：新增习惯
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const AddHabitPage()),
                        );
                        if (result is Habit) {
                          setState(() {
                            _habits.add(result);
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                      child: Container(
                        width: ScreenUtil().setWidth(80),
                        height: ScreenUtil().setHeight(80),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: ScreenUtil().setSp(28),
                              color: Colors.black,
                            ),
                            SizedBox(height: ScreenUtil().setHeight(4)),
                            Text(
                              '新增习惯',
                              style: TextStyle(
                                fontSize: ScreenUtil().setSp(16),
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // 习惯列表或空状态
        Expanded(
          child: Container(
            padding: EdgeInsets.only(top: ScreenUtil().setHeight(24)),
            child: _habits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: Duration(seconds: 1),
                          curve: Curves.bounceInOut,
                          child: Icon(
                            Icons.list,
                            size: ScreenUtil().setSp(80),
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: ScreenUtil().setHeight(24)),
                        Text(
                          '还没有添加习惯',
                          style: ThemeHelper.textStyleWithTheme(
                            context,
                            fontSize: ScreenUtil().setSp(24),
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: ScreenUtil().setHeight(12)),
                        Text(
                          '点击右下角的+按钮开始添加',
                          style: ThemeHelper.textStyleWithTheme(
                            context,
                            fontSize: ScreenUtil().setSp(18),
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(16), vertical: ScreenUtil().setHeight(8)),
                    itemCount: _habits.length,
                    itemBuilder: (context, index) {
                      final habit = _habits[index];
                      return _buildHabitItem(habit);
                    },
                  ),
          ),
        ),
      ],
    );
  }





  // 获取习惯图标
  Widget _getHabitIcon(Habit habit) {
    // 使用共享的IconHelper类获取图标
    // 设置logError为false以避免在正常流程中记录过多日志
    return ThemeHelper.iconWithBackground(
      context,
      IconHelper.getIconData(habit.icon ?? '', logError: false),
      size: ScreenUtil().setSp(32),
      backgroundSize: ScreenUtil().setWidth(64),
      iconColor: Colors.white, // 图标颜色始终为白色，确保在任何背景下都清晰可见
      backgroundColor: Colors.transparent, // 背景颜色设置为透明，因为我们已经在_buildHabitItem中设置了渐变背景
      shape: BoxShape.circle,
    );
  }



  Widget _buildHabitItem(Habit habit) {
    final isDarkMode = ThemeHelper.isDarkMode(context);
    
    // 使用习惯的颜色属性来创建渐变，而不是使用主题颜色
    // 这样图标背景颜色不会随着主题变化而变化，保持习惯的专属颜色
    final primaryColor = habit.color;
    HSLColor hsl = HSLColor.fromColor(primaryColor);
    Color secondaryColor = hsl.withLightness(hsl.lightness * 0.8).toColor();
    final gradientColors = [primaryColor, secondaryColor];

    // 检查今天是否已完成
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isCompletedToday = habit.dailyCompletionStatus.containsKey(todayOnly) && 
                            habit.dailyCompletionStatus[todayOnly] == true;

    return Dismissible(
      // 唯一标识符
      key: Key(habit.id),
      // 左滑方向
      direction: DismissDirection.endToStart,
      // 滑动阈值，滑动超过这个比例才会触发删除
      dismissThresholds: const {
        DismissDirection.endToStart: 0.8, // 需要滑动80%才会触发删除
      },
      // 滑动背景
      background: Container(
        margin: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(16), vertical: ScreenUtil().setHeight(10)),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(ScreenUtil().setWidth(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '删除',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: ScreenUtil().setWidth(16)),
            Icon(
              Icons.delete,
              color: Colors.white,
            ),
            SizedBox(width: ScreenUtil().setWidth(24)),
          ],
        ),
      ),
      // 滑动确认删除
      confirmDismiss: (direction) async {
        // 显示确认对话框
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('确认删除'),
              content: Text('确定要删除习惯 "${habit.name}" 吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ?? false;

        // 如果用户确认删除，执行删除操作
        if (shouldDelete) {
          await _deleteHabit(habit.id);
        }

        // 返回是否真的要解除（删除）这个item
        // 返回false表示取消删除，item会自动恢复原位
        return false;
      },
      // 习惯卡片内容
      child: GestureDetector(
        onLongPress: () async {
          // 长按习惯卡片时，跳转到编辑习惯页面
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddHabitPage(habitToEdit: habit)),
          );
          if (result != null) {
            // 如果习惯被更新，重新加载习惯列表
            setState(() {
              _loadHabits();
            });
          }
        },
        onTap: () {
          // 点击习惯卡片（非播放按钮区域）跳转到统计页面
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HabitDetailStatisticsPage(habit: habit)),
          );
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(16), vertical: ScreenUtil().setHeight(10)),
          child: Stack(
            children: [
              // 卡片背景
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ScreenUtil().setWidth(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withOpacity(0.15),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(ScreenUtil().setWidth(20)),
                    border: Border.all(
                      color: isDarkMode 
                          ? Theme.of(context).colorScheme.outline.withOpacity(0.3) 
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(20), vertical: ScreenUtil().setHeight(28)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 图标区域
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: ScreenUtil().setWidth(64), 
                        height: ScreenUtil().setHeight(64),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                          borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16)),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors[0].withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _getHabitIcon(habit),
                        ),
                      ),
                      SizedBox(width: ScreenUtil().setWidth(20)),
                      // 内容区域
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: ScreenUtil().setWidth(60)), // 为右侧按钮留出空间
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children:[
                                  Text(
                                    habit.name,
                                    style: ThemeHelper.textStyleWithTheme(
                                      context,
                                      fontSize: ScreenUtil().setSp(18),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (isCompletedToday)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(12), vertical: ScreenUtil().setHeight(4)),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16)),
                                      ),
                                      child: Text(
                                        '今日已完成',
                                        style: ThemeHelper.textStyleWithTheme(
                                          context,
                                          fontSize: ScreenUtil().setSp(12),
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: ScreenUtil().setHeight(4)),
                              Text(
                                _formatHabitDescription(habit),
                                style: ThemeHelper.textStyleWithTheme(
                                  context,
                                  fontSize: ScreenUtil().setSp(16),
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              SizedBox(height: ScreenUtil().setHeight(8)),
                              // 根据是否设置目标显示不同内容
                              Column(
                                children: [
                                  // 主进度条（根据规则计算最终进度）
                                  LinearProgressIndicator(
                                    value: _getFinalProgress(habit).clamp(0.0, 1.0),
                                    backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(gradientColors[0]),
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  SizedBox(height: ScreenUtil().setHeight(4)),
                                ],
                              ),
                              SizedBox(height: ScreenUtil().setHeight(4)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 右侧操作按钮
              Positioned(
                right: ScreenUtil().setWidth(24),
                top: ScreenUtil().setHeight(50),
                child: Container(
                  width: ScreenUtil().setWidth(44),
                  height: ScreenUtil().setHeight(44),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.play_arrow,
                      color: ThemeHelper.onPrimary(context),
                      size: ScreenUtil().setSp(20),
                    ),
                    onPressed: () {
                      // 播放按钮点击事件，阻止事件冒泡到卡片的onTap
                      _navigateToTrackingPage(habit);
                    },
                    tooltip: '开始',
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