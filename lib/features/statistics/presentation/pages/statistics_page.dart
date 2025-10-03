import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_chart_widget.dart';
import 'package:contrail/features/statistics/presentation/widgets/timeline_view_widget.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/statistics/presentation/widgets/calendar_view_widget.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/core/routing/app_router.dart';
import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late AnimationController _fadeAnimation;
  bool _isDetailView = true;
  // 跟踪第二个按钮当前显示的时间范围（week/month/year）
  String _statsTimeRange = 'week'; // 默认显示周统计

  @override
  void initState() {
    super.initState();
    _fadeAnimation = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 300),
    )..value = 1.0;
  }

  @override
  void dispose() {
    _fadeAnimation.dispose();
    super.dispose();
  }

  void _toggleView(StatisticsProvider statisticsProvider) {
    setState(() {
      _isDetailView = !_isDetailView;
      _fadeAnimation.value = 0.0;
    });

    // 添加延迟以确保动画完成
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _fadeAnimation.value = 1.0;
      });
    });
  }

  void _sendProgressReport(BuildContext context) {
    // 获取当前的习惯数据
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final habits = habitProvider.habits;
    
    // 直接实例化HabitStatisticsService
    final statisticsService = HabitStatisticsService();
    Map<String, dynamic> stats;
    
    // 根据当前选择的时间范围获取相应的统计数据
    if (_statsTimeRange == 'month') {
      stats = statisticsService.getMonthlyHabitStatistics(habits);
    } else if (_statsTimeRange == 'year') {
      stats = statisticsService.getYearlyHabitStatistics(habits);
    } else {
      stats = statisticsService.getWeeklyHabitStatistics(habits);
    }
    
    // 导航到统计报告页面
    AppRouter.router.go(
      '/statistics/result',
      extra: {
        'statisticsData': stats,
        'periodType': _statsTimeRange,
      },
    );
  }

  // 创建维度切换按钮
  Widget _buildPeriodButton(BuildContext context, String label, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
        foregroundColor: isSelected ? ThemeHelper.onPrimary(context) : ThemeHelper.onBackground(context),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: isSelected ? 3 : 1,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
    );
  }

  // 计算日期是当年的第几周
  int _getWeekNumber(DateTime date) {
    // 计算日期是当年的第几周
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    // 假设每周从周一开始
    final firstDayOfYearWeekday = firstDayOfYear.weekday;
    final daysToFirstMonday = firstDayOfYearWeekday == 7 ? 0 : 7 - firstDayOfYearWeekday;
    final adjustedDays = days - daysToFirstMonday;
    return adjustedDays >= 0 ? (adjustedDays ~/ 7) + 1 : 1;
  }

  // 计算统计数据
  Map<String, dynamic> _calculateStats(List<Habit> habits) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    // 计算本周第一天（周一）
    final firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));
    
    // 计算本月第一天
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    
    // 计算本年第一天
    final firstDayOfYear = DateTime(today.year, 1, 1);
    
    // 计算当月总天数
    final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
    final totalMonthDays = min(today.day, lastDayOfMonth.day);
    
    int completedWeekTasks = 0;
    int totalWeekDays = 0;
    int completedMonthTasks = 0;
    int totalMonthTasks = habits.length * totalMonthDays;
    int completedYearTasks = 0;
    int totalYearTasks = habits.length * (today.difference(firstDayOfYear).inDays + 1);
    
    // 计算本周、本月和本年的完成情况
    for (final habit in habits) {
      // 本周完成情况
      for (int i = 0; i < 7; i++) {
        final date = firstDayOfWeek.add(Duration(days: i));
        final dateOnly = DateTime(date.year, date.month, date.day);
        
        // 只计算不大于今天的日期
        if (!date.isAfter(today)) {
          totalWeekDays++;
          if (habit.dailyCompletionStatus.containsKey(dateOnly) && 
              habit.dailyCompletionStatus[dateOnly] == true) {
            completedWeekTasks++;
          }
        }
      }
      
      // 本月完成情况
      for (int i = 0; i < totalMonthDays; i++) {
        final date = firstDayOfMonth.add(Duration(days: i));
        final dateOnly = DateTime(date.year, date.month, date.day);
        
        if (habit.dailyCompletionStatus.containsKey(dateOnly) && 
            habit.dailyCompletionStatus[dateOnly] == true) {
          completedMonthTasks++;
        }
      }
      
      // 本年完成情况
      final yearDays = today.difference(firstDayOfYear).inDays + 1;
      for (int i = 0; i < yearDays; i++) {
        final date = firstDayOfYear.add(Duration(days: i));
        final dateOnly = DateTime(date.year, date.month, date.day);
        
        if (habit.dailyCompletionStatus.containsKey(dateOnly) && 
            habit.dailyCompletionStatus[dateOnly] == true) {
          completedYearTasks++;
        }
      }
    }
    
    return {
      'totalHabits': habits.length,
      'completedWeekTasks': completedWeekTasks,
      'totalWeekDays': totalWeekDays,
      'completedMonthTasks': completedMonthTasks,
      'totalMonthDays': totalMonthDays,
      'completedYearTasks': completedYearTasks,
      'totalYearTasks': totalYearTasks,
    };
  }

  // 构建合并的明细视图（日历和时间轴）
  Widget _buildCombinedDetailView(
    BuildContext context, 
    List<Habit> visibleHabits,
    StatisticsProvider statisticsProvider,
    Map<String, Color> habitColors,
  ) {
    return Column(
      children: [
          // 日历视图 - 独立的白色块
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white, // 使用纯白色背景
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text(
                  '打卡日历',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.onBackground(context),
                  ),
                ),
                const SizedBox(height: 16),
                CalendarViewWidget(
                  habits: visibleHabits,
                  selectedYear: statisticsProvider.detailSelectedYear,
                  selectedMonth: statisticsProvider.detailSelectedMonth,
                  habitColors: habitColors,
                ),
              ],
            ),
          ),
          // 时间轴视图 - 独立的白色块
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white, // 使用纯白色背景
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text(
                  '活动时间轴',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.onBackground(context),
                  ),
                ),
                const SizedBox(height: 16),
                TimelineViewWidget(
                  habits: visibleHabits,
                  selectedYear: statisticsProvider.detailSelectedYear,
                  selectedMonth: statisticsProvider.detailSelectedMonth,
                ),
              ],
            ),
          ),
          // 添加底部内边距，确保内容不会贴在底部
          const SizedBox(height: 80),
        ],
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<HabitProvider, StatisticsProvider>(
        builder: (context, habitProvider, statisticsProvider, child) {
          final habits = habitProvider.habits;
          
          // 延迟初始化习惯可见性列表，避免在build过程中调用notifyListeners
          if (statisticsProvider.isHabitVisible == null || statisticsProvider.isHabitVisible!.length != habits.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                statisticsProvider.initializeHabitVisibility(habits);
              }
            });
          }
          
          // 确保isHabitVisible不为null，提供默认值用于初始渲染
          final isHabitVisible = statisticsProvider.isHabitVisible ?? List<bool>.filled(habits.length, true);
          
          // 过滤可见习惯时添加索引安全检查
          final visibleHabits = habits.asMap().entries
              .where((entry) => entry.key < isHabitVisible.length && isHabitVisible[entry.key])
              .map((entry) => entry.value)
              .toList();
                      
          // 使用习惯的颜色属性，不再需要固定的颜色列表
          final Map<String, Color> habitColors = {};
          for (int i = 0; i < habits.length; i++) {
            habitColors[habits[i].name] = habits[i].color;
          }
          
          // 计算统计数据
          final stats = _calculateStats(visibleHabits);
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // 渐变背景的头部（与习惯页面统一使用主题颜色）
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
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32), // 与习惯页面统一内边距
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // 与习惯页面统一对齐方式
                    children: [
                      Text(
                        '习惯统计',
                        style: ThemeHelper.textStyleWithTheme(
                          context,
                          fontSize: 32, // 与习惯页面统一标题大小
                          fontWeight: FontWeight.bold,
                          color: ThemeHelper.onPrimary(context),
                        ),
                      ),
                      SizedBox(height: 8), // 添加标题与副标题间距
                      Text(
                        '查看你的努力成果', // 添加副标题
                        style: ThemeHelper.textStyleWithTheme(
                          context,
                          fontSize: 16,
                          color: ThemeHelper.onPrimary(context).withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 24), // 添加与统计卡片的间距
                      // 功能按钮 - 与习惯页面风格一致
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // 第一个按钮：视图切换
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _toggleView(statisticsProvider),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 80,
                                height: 80,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timeline,
                                      size: 28,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isDetailView ? '明细视图' : '趋势视图',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // 第二个按钮：点击切换显示周/月/年统计
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                // 点击时切换显示的时间范围
                                setState(() {
                                  if (_statsTimeRange == 'week') {
                                    _statsTimeRange = 'month';
                                  } else if (_statsTimeRange == 'month') {
                                    _statsTimeRange = 'year';
                                  } else {
                                    _statsTimeRange = 'week';
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 80,
                                height: 80,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _statsTimeRange == 'week'
                                        ? '${stats['completedWeekTasks']}'
                                        : _statsTimeRange == 'month'
                                          ? '${stats['completedMonthTasks']}'
                                          : '${stats['completedYearTasks']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _statsTimeRange == 'week' ? '本周次数' : _statsTimeRange == 'month' ? '本月次数' : '本年次数',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // 第三个按钮：分享按钮
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _sendProgressReport(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 80,
                                height: 80,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.send,
                                      size: 28,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '分享报告',
                                      style: TextStyle(
                                        fontSize: 12,
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
                // 时间选择器 - 根据视图类型显示不同的选择器
                _isDetailView ? 
                  // 明细视图时间选择器（固定为月份选择）
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, // 与其他卡片保持一致的背景色
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            // 切换到上个月
                            if (statisticsProvider.detailSelectedMonth > 1) {
                              statisticsProvider.setDetailSelectedMonth(statisticsProvider.detailSelectedMonth - 1);
                            } else {
                              statisticsProvider.setDetailSelectedMonth(12);
                              statisticsProvider.setDetailSelectedYear(statisticsProvider.detailSelectedYear - 1);
                            }
                          },
                          icon: Icon(
                            Icons.arrow_left,
                            color: ThemeHelper.onBackground(context),
                          ),
                        ),
                        Text(
                          '${statisticsProvider.detailSelectedYear}年${statisticsProvider.detailSelectedMonth}月',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ThemeHelper.onBackground(context)
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // 切换到下个月
                            if (statisticsProvider.detailSelectedMonth < 12) {
                              statisticsProvider.setDetailSelectedMonth(statisticsProvider.detailSelectedMonth + 1);
                            } else {
                              statisticsProvider.setDetailSelectedMonth(1);
                              statisticsProvider.setDetailSelectedYear(statisticsProvider.detailSelectedYear + 1);
                            }
                          },
                          icon: Icon(
                            Icons.arrow_right,
                            color: ThemeHelper.onBackground(context),
                          ),
                        ),
                      ],
                    ),
                  ) : 
                  // 趋势视图时间选择器（可切换周/月/年）
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (statisticsProvider.trendSelectedPeriod == 'year') {
                              statisticsProvider.setTrendSelectedYear(statisticsProvider.trendSelectedYear - 1);
                            } else if (statisticsProvider.trendSelectedPeriod == 'week') {
                              // 切换到上一周
                              if (statisticsProvider.trendSelectedWeek > 1) {
                                statisticsProvider.setTrendSelectedWeek(statisticsProvider.trendSelectedWeek - 1);
                              } else {
                                statisticsProvider.setTrendSelectedWeek(52); // 假设一年最多52周
                                statisticsProvider.setTrendSelectedYear(statisticsProvider.trendSelectedYear - 1);
                              }
                            } else {
                              // 切换到上个月
                              if (statisticsProvider.trendSelectedMonth > 1) {
                                statisticsProvider.setTrendSelectedMonth(statisticsProvider.trendSelectedMonth - 1);
                              } else {
                                statisticsProvider.setTrendSelectedMonth(12);
                                statisticsProvider.setTrendSelectedYear(statisticsProvider.trendSelectedYear - 1);
                              }
                            }
                          },
                          icon: Icon(
                            Icons.arrow_left,
                            color: ThemeHelper.onBackground(context),
                          ),
                        ),
                        Text(
                          statisticsProvider.trendSelectedPeriod == 'week'
                            ? '${statisticsProvider.trendSelectedYear}年第${statisticsProvider.trendSelectedWeek}周'
                            : statisticsProvider.trendSelectedPeriod == 'month'
                              ? '${statisticsProvider.trendSelectedYear}年${statisticsProvider.trendSelectedMonth}月'
                              : '${statisticsProvider.trendSelectedYear}年',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ThemeHelper.onBackground(context)
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (statisticsProvider.trendSelectedPeriod == 'year') {
                              statisticsProvider.setTrendSelectedYear(statisticsProvider.trendSelectedYear + 1);
                            } else if (statisticsProvider.trendSelectedPeriod == 'week') {
                              // 切换到下一周
                              // 使用31/12计算当年的最大周数
                              final lastDayOfYear = DateTime(statisticsProvider.trendSelectedYear, 12, 31);
                              final firstDayOfYear = DateTime(statisticsProvider.trendSelectedYear, 1, 1);
                              final days = lastDayOfYear.difference(firstDayOfYear).inDays;
                              final firstDayOfYearWeekday = firstDayOfYear.weekday;
                              final daysToFirstMonday = firstDayOfYearWeekday == 7 ? 0 : 7 - firstDayOfYearWeekday;
                              final adjustedDays = days - daysToFirstMonday;
                              final maxWeeks = adjustedDays >= 0 ? (adjustedDays ~/ 7) + 1 : 1;
                                
                              if (statisticsProvider.trendSelectedWeek < maxWeeks) {
                                statisticsProvider.setTrendSelectedWeek(statisticsProvider.trendSelectedWeek + 1);
                              } else {
                                statisticsProvider.setTrendSelectedWeek(1);
                                statisticsProvider.setTrendSelectedYear(statisticsProvider.trendSelectedYear + 1);
                              }
                            } else {
                              // 切换到下个月
                              if (statisticsProvider.trendSelectedMonth < 12) {
                                statisticsProvider.setTrendSelectedMonth(statisticsProvider.trendSelectedMonth + 1);
                              } else {
                                statisticsProvider.setTrendSelectedMonth(1);
                                statisticsProvider.setTrendSelectedYear(statisticsProvider.trendSelectedYear + 1);
                              }
                            }
                          },
                          icon: Icon(
                            Icons.arrow_right,
                            color: ThemeHelper.onBackground(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 明细视图的图例选择部分 - 放在日期选择下方
                  if (_isDetailView) 
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: habits.asMap().entries.map((entry) {
                                final index = entry.key;
                                final habit = entry.value;
                                final isVisible = index < isHabitVisible.length && isHabitVisible[index];
                                    
                                return GestureDetector(
                                  onTap: () {
                                    statisticsProvider.toggleHabitVisibility(index);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isVisible ? habit.color : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isVisible ? habit.color : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: isVisible ? ThemeHelper.onPrimary(context) : Colors.grey.shade400,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          habit.name,
                                          style: TextStyle(
                                            color: isVisible ? ThemeHelper.onPrimary(context) : Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          // 确保容器宽度充足，即使习惯数量较少
                          habits.length < 3 ? Container(width: 80) : Container(),
                        ],
                      ),
                    ),
                // 主体内容 - 简洁的淡入淡出动画
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value == 0.0 ? 1.0 : _fadeAnimation.value,
                      child: _isDetailView
                                ? _buildCombinedDetailView(
                                    context, 
                                    visibleHabits,
                                    statisticsProvider,
                                    habitColors,
                                  )
                                : Column(
                                    children: [
                                      // 周/月/年维度切换控件
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildPeriodButton(context, '周', statisticsProvider.trendSelectedPeriod == 'week', () {
                                              statisticsProvider.setTrendSelectedPeriod('week');
                                            }),
                                            const SizedBox(width: 16),
                                            _buildPeriodButton(context, '月', statisticsProvider.trendSelectedPeriod == 'month', () {
                                              statisticsProvider.setTrendSelectedPeriod('month');
                                            }),
                                            const SizedBox(width: 16),
                                            _buildPeriodButton(context, '年', statisticsProvider.trendSelectedPeriod == 'year', () {
                                              statisticsProvider.setTrendSelectedPeriod('year');
                                            }),
                                          ],
                                        ),
                                      ),
                                      // 趋势视图的图例选择部分 - 放在周、月、年选择维度下方
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Wrap(
                                                spacing: 12,
                                                runSpacing: 8,
                                                children: habits.asMap().entries.map((entry) {
                                                  final index = entry.key;
                                                  final habit = entry.value;
                                                  final isVisible = index < isHabitVisible.length && isHabitVisible[index];
                                                       
                                                  return GestureDetector(
                                                    onTap: () {
                                                      statisticsProvider.toggleHabitVisibility(index);
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: isVisible ? habit.color : Colors.grey.shade200,
                                                        borderRadius: BorderRadius.circular(20),
                                                        border: Border.all(
                                                          color: isVisible ? habit.color : Colors.grey.shade300,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 12,
                                                            height: 12,
                                                            decoration: BoxDecoration(
                                                              color: isVisible ? ThemeHelper.onPrimary(context) : Colors.grey.shade400,
                                                              shape: BoxShape.circle,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            habit.name,
                                                            style: TextStyle(
                                                              color: isVisible ? ThemeHelper.onPrimary(context) : Colors.grey.shade600,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                            // 确保容器宽度充足，即使习惯数量较少
                                            habits.length < 3 ? Container(width: 80) : Container(),
                                          ],
                                        ),
                                      ),
                                      // 图表内容
                                      StatisticsChartWidget(
                                        habits: visibleHabits,
                                        selectedPeriod: statisticsProvider.trendSelectedPeriod,
                                        selectedYear: statisticsProvider.trendSelectedYear,
                                        selectedMonth: statisticsProvider.trendSelectedMonth,
                                        selectedWeek: statisticsProvider.trendSelectedWeek,
                                        isHabitVisible: statisticsProvider.isHabitVisible,
                                      ),
                                    ],
                                  ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}