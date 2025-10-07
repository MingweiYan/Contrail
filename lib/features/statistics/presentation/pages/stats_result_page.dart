import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:contrail/shared/models/cycle_type.dart';

class StatsResultPage extends StatefulWidget {
  // 可选的参数，用于接收统计数据
  final Map<String, dynamic>? statisticsData;
  final String? periodType; // 'week', 'month', 'year'

  const StatsResultPage({
    Key? key,
    this.statisticsData,
    this.periodType,
  }) : super(key: key);

  @override
  State<StatsResultPage> createState() => _StatsResultPageState();
}

class _StatsResultPageState extends State<StatsResultPage> {
  late Map<String, dynamic> _statisticsData;
  late HabitStatisticsService _statisticsService;
  bool _isLoading = true;
  
  // 性能测量变量
  DateTime? _pageLoadStartTime;
  DateTime? _dataLoadStartTime;
  DateTime? _dataLoadEndTime;
  DateTime? _uiRenderEndTime;
  Timer? _renderTimer;

  @override
  void initState() {
    super.initState();
    // 记录页面加载开始时间
    _pageLoadStartTime = DateTime.now();
    logger.debug('📊  StatsResultPage 初始化');
    logger.debug('⏱️  页面加载开始时间: $_pageLoadStartTime');
    logger.debug('🔧  构造参数: statisticsData=${widget.statisticsData != null ? '有数据' : '无数据'}, periodType=${widget.periodType}');
    _statisticsService = HabitStatisticsService();
    _loadStatistics();
  }

  @override
  void dispose() {
    _renderTimer?.cancel();
    super.dispose();
  }

  // 加载统计数据
  Future<void> _loadStatistics() async {
    try {
      logger.debug('📊  开始加载统计数据');
      // 记录数据加载开始时间
      _dataLoadStartTime = DateTime.now();
      setState(() => _isLoading = true);
      
      // 如果有传入的数据，直接使用
      if (widget.statisticsData != null) {
        logger.debug('✅  使用传入的统计数据');
        _statisticsData = widget.statisticsData!;
      } else {
        logger.debug('🔄  从服务获取统计数据');
        // 否则从服务中获取数据
        final habitProvider = Provider.of<HabitProvider>(context, listen: false);
        final habits = habitProvider.habits;
        
        logger.debug('📋  共有 ${habits.length} 个习惯需要统计');
        // 根据传入的周期类型获取不同的统计数据
          if (widget.periodType == 'month') {
            logger.debug('📅  获取月度统计数据');
            _statisticsData = _statisticsService.getMonthlyHabitStatistics(habits);
          } else {
            logger.debug('📅  获取周度统计数据 (默认)');
            // 默认获取周统计
            _statisticsData = _statisticsService.getWeeklyHabitStatistics(habits);
          }
          logger.debug('📊  统计数据加载完成: 平均完成率 ${( _statisticsData['averageCompletionRate'] * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      logger.error('❌  加载统计数据失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加载统计数据失败')),
      );
    } finally {
      // 记录数据加载结束时间
      _dataLoadEndTime = DateTime.now();
      // 计算数据加载耗时
      final dataLoadDuration = _dataLoadStartTime != null 
          ? _dataLoadEndTime!.difference(_dataLoadStartTime!).inMilliseconds 
          : -1;
      
      logger.debug('✅  统计数据加载流程结束，isLoading=false');
      logger.debug('⏱️  数据加载耗时: $dataLoadDuration 毫秒');
      setState(() => _isLoading = false);
      
      // 计划检查UI渲染完成时间
      _scheduleRenderCheck();
    }
  }
  
  // 计划检查UI渲染完成时间
  void _scheduleRenderCheck() {
    _renderTimer?.cancel();
    // 在下一帧绘制完成后检查
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_uiRenderEndTime == null) {
        _uiRenderEndTime = DateTime.now();
        
        // 计算完整的页面加载时间
        final totalLoadDuration = _pageLoadStartTime != null 
            ? _uiRenderEndTime!.difference(_pageLoadStartTime!).inMilliseconds 
            : -1;
        
        final dataLoadDuration = _dataLoadStartTime != null 
            ? _dataLoadEndTime!.difference(_dataLoadStartTime!).inMilliseconds 
            : -1;
        
        final renderDuration = _dataLoadEndTime != null 
            ? _uiRenderEndTime!.difference(_dataLoadEndTime!).inMilliseconds 
            : -1;
        
        logger.debug('⏱️  页面加载性能统计:');
        logger.debug('⏱️  - 总加载时间: $totalLoadDuration 毫秒');
        logger.debug('⏱️  - 数据加载时间: $dataLoadDuration 毫秒');
        logger.debug('⏱️  - UI渲染时间: $renderDuration 毫秒');
        
        // 显示加载时间到用户界面
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('页面加载完成: $totalLoadDuration 毫秒'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  // 格式化日期显示
  String _formatDateRange(DateTime startDate, DateTime endDate) {
    final formatter = DateFormat('yyyy年MM月dd日');
    return '${formatter.format(startDate)} 至 ${formatter.format(endDate)}';
  }

  // 获取当前主题下最佳的文本颜色
  Color _getOptimalTextColor(BuildContext context, {bool isImportant = false}) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    if (isImportant) {
      return ThemeHelper.ensureTextContrast(ThemeHelper.primary(context), bgColor);
    }
    return ThemeHelper.ensureTextContrast(ThemeHelper.onBackground(context), bgColor);
  }

  // 获取周期标题
  String _getPeriodTitle() {
    if (widget.periodType == 'month') {
      return '月度统计报告';
    } else if (widget.periodType == 'year') {
      return '年度统计报告';
    } else {
      return '周度统计报告';
    }
  }

  // 获取当前月的习惯完成次数数据（用于饼状图）
  Map<String, int> _getMonthlyHabitCompletionCounts() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final habits = habitProvider.habits;
    
    final Map<String, int> completionCounts = {};
    
    for (final habit in habits) {
      int count = 0;
      habit.dailyCompletionStatus.forEach((date, completed) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (dateOnly.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
            dateOnly.isBefore(endOfMonth.add(const Duration(days: 1))) &&
            completed) {
          count++;
        }
      });
      completionCounts[habit.name] = count;
    }
    
    return completionCounts;
  }

  // 获取当前月的习惯完成时间数据（用于饼状图）
  Map<String, int> _getMonthlyHabitCompletionMinutes() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final habits = habitProvider.habits;
    
    final Map<String, int> completionMinutes = {};
    
    for (final habit in habits) {
      // 只有设置了追踪时间的习惯才会出现在时间统计的饼状图中
      if (habit.trackTime) {
        int totalMinutes = 0;
        habit.trackingDurations.forEach((date, durations) {
          final dateOnly = DateTime(date.year, date.month, date.day);
          if (dateOnly.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
              dateOnly.isBefore(endOfMonth.add(const Duration(days: 1)))) {
            for (final duration in durations) {
              totalMinutes += duration.inMinutes;
            }
          }
        });
        if (totalMinutes > 0) {
          completionMinutes[habit.name] = totalMinutes;
        }
      }
    }
    
    return completionMinutes;
  }



  // 获取有目标的习惯及其完成度数据（用于柱状图）
  List<Map<String, dynamic>> _getHabitGoalCompletionData() {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final habits = habitProvider.habits;
    final now = DateTime.now();
    
    final List<Map<String, dynamic>> goalCompletionData = [];
    
    // 确定统计周期
    DateTime startDate, endDate;
    if (widget.periodType == 'month') {
      // 月度统计 - 获取当前月的开始和结束日期
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
    } else if (widget.periodType == 'year') {
      // 年度统计 - 获取当前年的开始和结束日期
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31);
    } else {
      // 默认周度统计
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
    }
    
    for (final habit in habits) {
      // 只考虑有目标的习惯
      if (habit.targetDays != null && habit.color != null) {
        // 计算当前周期内的完成情况
        double completionRate = 0.0;
        int completedDays = 0;
        int requiredDays = 0;
        
        // 根据周期类型和统计周期计算完成率
        if (habit.cycleType == CycleType.daily) {
          // 每日习惯
          if (widget.periodType == 'month') {
            // 月度统计：计算本月需要完成的天数（按实际天数计算）
            final daysInMonth = endDate.day;
            requiredDays = min(now.day, daysInMonth); // 只计算到今天为止的天数
          } else if (widget.periodType == 'year') {
            // 年度统计：计算今年需要完成的天数
            final daysPassedInYear = now.difference(startDate).inDays + 1;
            requiredDays = daysPassedInYear;
          } else {
            // 周度统计：计算本周需要完成的天数
            final daysPassedInWeek = now.difference(startDate).inDays + 1;
            requiredDays = daysPassedInWeek;
          }
          
          // 计算完成的天数
          habit.dailyCompletionStatus.forEach((date, completed) {
            final dateOnly = DateTime(date.year, date.month, date.day);
            if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1))) &&
                dateOnly.isBefore(endDate.add(const Duration(days: 1))) &&
                dateOnly.isBefore(now.add(const Duration(days: 1))) && // 只计算到今天
                completed) {
              completedDays++;
            }
          });
        } else if (habit.cycleType == CycleType.weekly) {
          // 每周习惯：目标是每周完成特定天数
          if (widget.periodType == 'month') {
            // 月度统计：计算本月有多少周，每周需要完成的天数
            final weeksInMonth = (endDate.difference(startDate).inDays / 7).ceil();
            requiredDays = weeksInMonth * (habit.targetDays ?? 1);
          } else if (widget.periodType == 'year') {
            // 年度统计：计算今年有多少周，每周需要完成的天数
            final weeksInYear = (endDate.difference(startDate).inDays / 7).ceil();
            requiredDays = weeksInYear * (habit.targetDays ?? 1);
          } else {
            // 周度统计：直接使用目标天数
            requiredDays = habit.targetDays!;
          }
          
          // 计算完成的天数
          habit.dailyCompletionStatus.forEach((date, completed) {
            final dateOnly = DateTime(date.year, date.month, date.day);
            if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1))) &&
                dateOnly.isBefore(endDate.add(const Duration(days: 1))) &&
                dateOnly.isBefore(now.add(const Duration(days: 1))) && // 只计算到今天
                completed) {
              completedDays++;
            }
          });
        } else if (habit.cycleType == CycleType.monthly) {
          // 每月习惯：目标是每月完成特定天数
          if (widget.periodType == 'year') {
            // 年度统计：计算今年有多少月，每月需要完成的天数
            final monthsInYear = (endDate.year - startDate.year) * 12 + 
                              (endDate.month - startDate.month) + 1;
            requiredDays = monthsInYear * (habit.targetDays ?? 1);
          } else {
            // 月度或周度统计：直接使用目标天数
            requiredDays = habit.targetDays!;
          }
          
          // 计算完成的天数
          habit.dailyCompletionStatus.forEach((date, completed) {
            final dateOnly = DateTime(date.year, date.month, date.day);
            if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1))) &&
                dateOnly.isBefore(endDate.add(const Duration(days: 1))) &&
                dateOnly.isBefore(now.add(const Duration(days: 1))) && // 只计算到今天
                completed) {
              completedDays++;
            }
          });
        }
        
        // 确保requiredDays不为0，避免除零错误
        completionRate = requiredDays > 0 ? completedDays / requiredDays : 0.0;
        
        goalCompletionData.add({
          'name': habit.name,
          'completedDays': completedDays,
          'requiredDays': requiredDays,
          'completionRate': completionRate,
          'color': habit.color
        });
      }
    }
    
    // 按完成率从高到低排序，使图表更直观
    goalCompletionData.sort((a, b) => b['completionRate'].compareTo(a['completionRate']));
    
    return goalCompletionData;
  }

  // 柱状图部分 - 用于显示有目标习惯的完成度
  Widget _buildGoalCompletionBarChart() {
    final goalCompletionData = _getHabitGoalCompletionData();
    
    if (goalCompletionData.isEmpty) {
      return const Center(child: Text('暂无设置目标的习惯'));
    }
    
    // 创建柱状图数据点
    final List<BarChartGroupData> barGroups = [];
    final double maxValue = 1.0; // 完成率最大值为100%
    
    for (int i = 0; i < goalCompletionData.length; i++) {
      final data = goalCompletionData[i];
      final completionRate = data['completionRate'] as double;
      final color = data['color'] as Color;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: completionRate,
              color: color,
              width: 20,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                toY: maxValue,
                color: Colors.grey[200],
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: 
        [
          const Text('习惯目标完成度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < goalCompletionData.length) {
                          return SizedBox(
                            width: 60,
                            child: Text(
                              goalCompletionData[index]['name'].toString(),
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: true),
              ),
            ),
          ),
        ],
    );
  }

  // 饼状图部分 - 用于显示习惯完成次数
  Widget _buildCompletionCountPieChart() {
    final completionCounts = _getMonthlyHabitCompletionCounts();
    final totalCount = completionCounts.values.fold(0, (sum, count) => sum + count);
    
    if (totalCount == 0) {
      return const Center(child: Text('本月暂无打卡记录'));
    }
    
    // 创建饼图数据点
    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan
    ];
    
    int colorIndex = 0;
    for (final entry in completionCounts.entries) {
      if (entry.value > 0) {
        final percentage = (entry.value / totalCount) * 100;
        sections.add(
          PieChartSectionData(
            color: colors[colorIndex % colors.length],
            value: entry.value.toDouble(),
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 80,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
        colorIndex++;
      }
    }
    
    // 创建图例
    final List<Widget> legendItems = [];
    colorIndex = 0;
    for (final entry in completionCounts.entries) {
      if (entry.value > 0) {
        legendItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:
                [
                  Container(
                    width: 12,
                    height: 12,
                    color: colors[colorIndex % colors.length],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key}: ${entry.value}次',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
            ),
          ),
        );
        colorIndex++;
      }
    }
    
    // 使用StatefulWidget来处理触摸状态
    return StatefulBuilder(
      builder: (context, setState) {
        int? touchedIndex;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: 
            [
              // 先显示饼图
              SizedBox(
                height: 220, // 增加饼图高度，提供更多空间
                child: PieChart(
                  PieChartData(
                    sections: sections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final isTouched = index == touchedIndex;
                      // 增加缩放效果的差异，使变化更明显
                      final radius = isTouched ? 100.0 : 80.0;
                        
                      return PieChartSectionData(
                        color: data.color,
                        value: data.value,
                        title: data.title,
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: isTouched ? 14 : 12, 
                          fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                          color: isTouched ? Colors.white : Colors.black,
                        ),
                        // 增加更明显的边框效果
                        borderSide: isTouched 
                          ? const BorderSide(color: Colors.black, width: 3) 
                          : BorderSide.none,
                      );
                    }).toList(),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          // 增强触摸效果，支持悬停和点击
                          if (event is FlTapUpEvent && pieTouchResponse != null) {
                            // 切换触摸状态
                            touchedIndex = touchedIndex == null ? 0 : null;
                          } else if (event is FlPointerHoverEvent && pieTouchResponse != null) {
                            // 悬停效果 - 使用索引来设置被触摸的部分
                            touchedIndex = touchedIndex == null ? 0 : null;
                          } else if (event is FlPointerExitEvent) {
                            // 鼠标离开时恢复正常状态
                            touchedIndex = null;
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
              // 再显示图例（确保不覆盖图标）
              const SizedBox(height: 20), // 增加饼图和图例之间的间距
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10), // 增加左右内边距
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20.0, // 增加图例项之间的水平间距
                    runSpacing: 12.0, // 增加图例项之间的垂直间距
                    children: legendItems,
                  ),
                ),
              ),
              // 最后显示标题（标题放在图例下面）
              const SizedBox(height: 20), // 增加图例和标题之间的间距
              Text(
                '本月习惯完成次数分布', 
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.onSurface(context),
                ),
              ),
            ],
        );
      },
    );
  }

  // 饼状图部分 - 用于显示习惯完成时间
  Widget _buildCompletionTimePieChart() {
    final completionMinutes = _getMonthlyHabitCompletionMinutes();
    final totalMinutes = completionMinutes.values.fold(0, (sum, minutes) => sum + minutes);
    
    if (totalMinutes == 0) {
      return const Center(child: Text('本月暂无时间记录'));
    }
    
    // 创建饼图数据点
    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.indigo,
      Colors.blue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lime,
      Colors.yellow
    ];
    
    int colorIndex = 0;
    for (final entry in completionMinutes.entries) {
      if (entry.value > 0) {
        final percentage = (entry.value / totalMinutes) * 100;
        sections.add(
          PieChartSectionData(
            color: colors[colorIndex % colors.length],
            value: entry.value.toDouble(),
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 80,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
        colorIndex++;
      }
    }
    
    // 创建图例
    final List<Widget> legendItems = [];
    colorIndex = 0;
    for (final entry in completionMinutes.entries) {
      if (entry.value > 0) {
        final hours = entry.value ~/ 60;
        final minutes = entry.value % 60;
        final timeDisplay = hours > 0 ? '$hours时$minutes分' : '$minutes分';
        
        legendItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:
                [
                  Container(
                    width: 12,
                    height: 12,
                    color: colors[colorIndex % colors.length],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key}: $timeDisplay',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
            ),
          ),
        );
        colorIndex++;
      }
    }
    
    // 使用StatefulWidget来处理触摸状态
    return StatefulBuilder(
      builder: (context, setState) {
        int? touchedIndex;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: 
            [
              // 先显示饼图
              SizedBox(
                height: 220, // 增加饼图高度，提供更多空间
                child: PieChart(
                  PieChartData(
                    sections: sections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final isTouched = index == touchedIndex;
                      // 增加缩放效果的差异，使变化更明显
                      final radius = isTouched ? 100.0 : 80.0;
                        
                      return PieChartSectionData(
                        color: data.color,
                        value: data.value,
                        title: data.title,
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: isTouched ? 14 : 12, 
                          fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                          color: isTouched ? Colors.white : Colors.black,
                        ),
                        // 增加更明显的边框效果
                        borderSide: isTouched 
                          ? const BorderSide(color: Colors.black, width: 3) 
                          : BorderSide.none,
                      );
                    }).toList(),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          // 增强触摸效果，支持悬停和点击
                          if (event is FlTapUpEvent && pieTouchResponse != null) {
                            // 切换触摸状态
                            touchedIndex = touchedIndex == null ? 1 : null;
                          } else if (event is FlPointerHoverEvent && pieTouchResponse != null) {
                            // 悬停效果 - 使用索引来设置被触摸的部分
                            touchedIndex = touchedIndex == null ? 1 : null;
                          } else if (event is FlPointerExitEvent) {
                            // 鼠标离开时恢复正常状态
                            touchedIndex = null;
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
              // 再显示图例（确保不覆盖图标）
              const SizedBox(height: 20), // 增加饼图和图例之间的间距
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10), // 增加左右内边距
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20.0, // 增加图例项之间的水平间距
                    runSpacing: 12.0, // 增加图例项之间的垂直间距
                    children: legendItems,
                  ),
                ),
              ),
              // 最后显示标题（标题放在图例下面）
              const SizedBox(height: 20), // 增加图例和标题之间的间距
              Text(
                '本月习惯完成时间分布', 
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.onSurface(context),
                ),
              ),
            ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('月度统计报告'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final goalCompletionData = _getHabitGoalCompletionData();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
          [
            // 移除了日期范围显示，因为当前只统计当前月的结果
            const SizedBox(height: 10),

            // 结果统计
            ThemeHelper.gradientText(
              context,
              '结果统计',
              style: ThemeHelper.textStyleWithTheme(
                context,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 饼状图部分（使用一个大的背景块）
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: 
                      [
                        // 完成次数饼状图
                        _buildCompletionCountPieChart(),
                        const SizedBox(height: 60), // 增大次数和时间统计之间的间隔
                        // 完成时间饼状图
                        _buildCompletionTimePieChart(),
                      ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 目标追踪
            if (goalCompletionData.isNotEmpty) ...[
              ThemeHelper.gradientText(
                context,
                '目标追踪',
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // 习惯目标完成度柱状图
              SizedBox(
                width: double.infinity,
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildGoalCompletionBarChart(),
                  ),
                ),
              ),
            ],
          ],
      ),
    );
  }

  // 构建习惯卡片
  Widget _buildHabitCard(String habitName, dynamic completionRate) {
    final rate = (completionRate * 100).toStringAsFixed(1);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:
            [
              Text(
                habitName,
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.onSurface(context),
                ),
              ),
              ThemeHelper.highlightedText(
                context,
                '$rate%',
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                highlightColor: _getCompletionRateColor(double.parse(rate)),
              ),
            ],
        ),
      ),
    );
  }

  // 根据完成率获取颜色
  Color _getCompletionRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.lightGreen;
    if (rate >= 40) return Colors.yellow;
    if (rate >= 20) return Colors.orange;
    return Colors.red;
  }
}

// 创建一个缓存页面的包装器
class KeepAliveStatsResultPage extends StatefulWidget {
  final Map<String, dynamic>? statisticsData;
  final String? periodType;

  const KeepAliveStatsResultPage({
    Key? key,
    this.statisticsData,
    this.periodType,
  }) : super(key: key);

  @override
  State<KeepAliveStatsResultPage> createState() => _KeepAliveStatsResultPageState();
}

class _KeepAliveStatsResultPageState extends State<KeepAliveStatsResultPage>
    with AutomaticKeepAliveClientMixin<KeepAliveStatsResultPage> {
  @override
  void initState() {
    super.initState();
    logger.debug('💾  KeepAliveStatsResultPage 初始化');
    logger.debug('🔧  构造参数: statisticsData=${widget.statisticsData != null ? '有数据' : '无数据'}, periodType=${widget.periodType}');
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    logger.debug('🏗️  KeepAliveStatsResultPage 构建，传递参数给 StatsResultPage');
    return StatsResultPage(
      statisticsData: widget.statisticsData,
      periodType: widget.periodType,
    );
  }
}