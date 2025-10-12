import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/features/statistics/presentation/widgets/calendar_view_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HabitDetailStatisticsPage extends StatefulWidget {
  final Habit habit;

  const HabitDetailStatisticsPage({super.key, required this.habit});

  @override
  State<HabitDetailStatisticsPage> createState() => _HabitDetailStatisticsPageState();
}

class _HabitDetailStatisticsPageState extends State<HabitDetailStatisticsPage> {
  late int _selectedMonth;
  late int _selectedYear;
  String _timeRange = 'week'; // 'week', 'month', 'year'
  
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  // 计算习惯在当前周期内的完成情况
  Map<String, dynamic> _calculateHabitStats() {
    final now = DateTime.now();
    DateTime startDate, endDate;
    int totalRequiredDays = 0;
    int completedDays = 0;
    
    // 根据习惯的目标类型和选择的时间范围确定统计时间段
    // 对于周和月目标，固定显示对应周期的进展，不跟随趋势按钮联动
    if (widget.habit.cycleType == CycleType.weekly) {
      // 周目标：固定显示本周进展
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
      totalRequiredDays = widget.habit.targetDays ?? 3; // 每周目标天数
    } else if (widget.habit.cycleType == CycleType.monthly) {
      // 月目标：固定显示本月进展
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
      totalRequiredDays = widget.habit.targetDays ?? 1; // 每月目标天数
    } else {
      // 对于每日和年度目标，保持与趋势按钮联动的逻辑
      if (_timeRange == 'week') {
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        
        // 计算本周需要完成的天数
        if (widget.habit.cycleType == CycleType.daily) {
          totalRequiredDays = 7; // 每周7天
        } 
      } else if (_timeRange == 'month') {
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        
        // 计算本月需要完成的天数
        if (widget.habit.cycleType == CycleType.daily) {
          totalRequiredDays = endDate.day; // 当月总天数
        } 
      } else { // year
        startDate = DateTime(now.year, 1, 1);
        endDate = now;
        
        // 计算本年需要完成的天数
        if (widget.habit.cycleType == CycleType.daily) {
          totalRequiredDays = now.difference(startDate).inDays + 1;
        }
      }
    }
    
    // 计算已完成的天数
    widget.habit.dailyCompletionStatus.forEach((date, isCompleted) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1))) &&
          dateOnly.isBefore(endDate.add(const Duration(days: 1))) &&
          isCompleted) {
        completedDays++;
      }
    });
    
    return {
      'completedDays': completedDays,
      'totalRequiredDays': totalRequiredDays,
      'remainingDays': max(0, totalRequiredDays - completedDays),
      'completionRate': totalRequiredDays > 0 ? completedDays / totalRequiredDays : 0.0
    };
  }
  
  // 生成饼图数据
  List<PieChartSectionData> _generatePieData() {
    final stats = _calculateHabitStats();
    final completedDays = stats['completedDays'] as int;
    final remainingDays = stats['remainingDays'] as int;
    
    if (remainingDays <= 0) {
      // 如果没有剩余天数，只显示完成部分
      return [
        PieChartSectionData(
          value: completedDays.toDouble(),
          color: widget.habit.color,
          title: '$completedDays',
          radius: 60,
          titleStyle: TextStyle(
                      fontSize: ScreenUtil().setSp(20),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
        ),
      ];
    }
    
    return [
      PieChartSectionData(
        value: completedDays.toDouble(),
        color: widget.habit.color,
        title: '$completedDays',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: ScreenUtil().setSp(20),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: remainingDays.toDouble(),
        color: Colors.grey.withOpacity(0.3),
        title: '$remainingDays',
        radius: 60,
        titleStyle: TextStyle(
                      fontSize: ScreenUtil().setSp(20),
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
      ),
    ];
  }
  
  // 生成次数趋势图数据
  LineChartBarData _generateCountTrendData() {
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    final color = widget.habit.color;
    
    if (_timeRange == 'week') {
      // 生成周次数趋势数据
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final dateOnly = DateTime(date.year, date.month, date.day);
        final isCompleted = widget.habit.dailyCompletionStatus.containsKey(dateOnly) &&
                           widget.habit.dailyCompletionStatus[dateOnly] == true;
        
        spots.add(FlSpot(i.toDouble(), isCompleted ? 1.0 : 0.0));
      }
    } else if (_timeRange == 'month') {
      // 生成月次数趋势数据（按周显示）
      final weeksInMonth = (DateTime(now.year, now.month + 1, 0).day / 7).ceil();
      for (int i = 0; i < weeksInMonth; i++) {
        final weekStart = DateTime(now.year, now.month, 1).add(Duration(days: i * 7));
        int weekCompleted = 0;
        
        for (int j = 0; j < 7; j++) {
          final date = weekStart.add(Duration(days: j));
          if (date.month != now.month) break;
          final dateOnly = DateTime(date.year, date.month, date.day);
          if (widget.habit.dailyCompletionStatus.containsKey(dateOnly) &&
              widget.habit.dailyCompletionStatus[dateOnly] == true) {
            weekCompleted++;
          }
        }
        
        spots.add(FlSpot(i.toDouble(), weekCompleted.toDouble()));
      }
    } else { // year
      // 生成年次数趋势数据（按月份显示）
      for (int i = 1; i <= now.month; i++) {
        int monthCompleted = 0;
        final daysInMonth = DateTime(now.year, i + 1, 0).day;
        
        for (int j = 1; j <= daysInMonth; j++) {
          final date = DateTime(now.year, i, j);
          if (date.isAfter(now)) break;
          final dateOnly = DateTime(date.year, date.month, date.day);
          
          // 统计已完成的天数
          if (widget.habit.dailyCompletionStatus.containsKey(dateOnly) &&
              widget.habit.dailyCompletionStatus[dateOnly] == true) {
            monthCompleted++;
          }
        }
        
        spots.add(FlSpot((i - 1).toDouble(), monthCompleted.toDouble()));
      }
    }
    
    return LineChartBarData(
      spots: spots,
      isCurved: true, // 曲线样式
      curveSmoothness: 0.3, // 曲线平滑度
      color: color,
      barWidth: ScreenUtil().setWidth(3), // 线条宽度
      isStrokeCapRound: true, // 线条两端为圆形
      dotData: FlDotData(show: true),
      // 添加背景填充
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1), // 半透明背景色
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
  
  // 生成时间趋势图数据
  LineChartBarData _generateTimeTrendData() {
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    final color = widget.habit.color;
    
    if (_timeRange == 'week') {
      // 生成周时间趋势数据
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final dateOnly = DateTime(date.year, date.month, date.day);
        int duration = 0;
        
        // 计算当日专注时间（默认30分钟为一个单位）
        if (widget.habit.dailyCompletionStatus.containsKey(dateOnly) &&
            widget.habit.dailyCompletionStatus[dateOnly] == true) {
          // 假设每次完成专注30分钟
          duration = 30;
        }
        
        spots.add(FlSpot(i.toDouble(), duration.toDouble()));
      }
    } else if (_timeRange == 'month') {
      // 生成月时间趋势数据（按周显示）
      final weeksInMonth = (DateTime(now.year, now.month + 1, 0).day / 7).ceil();
      for (int i = 0; i < weeksInMonth; i++) {
        final weekStart = DateTime(now.year, now.month, 1).add(Duration(days: i * 7));
        int weekDuration = 0;
        
        for (int j = 0; j < 7; j++) {
          final date = weekStart.add(Duration(days: j));
          if (date.month != now.month) break;
          final dateOnly = DateTime(date.year, date.month, date.day);
          
          // 计算当日专注时间（默认30分钟为一个单位）
          if (widget.habit.dailyCompletionStatus.containsKey(dateOnly) &&
              widget.habit.dailyCompletionStatus[dateOnly] == true) {
            weekDuration += 30; // 假设每次完成专注30分钟
          }
        }
        
        spots.add(FlSpot(i.toDouble(), weekDuration.toDouble()));
      }
    } else { // year
      // 生成年时间趋势数据（按月份显示）
      for (int i = 1; i <= now.month; i++) {
        int monthDuration = 0;
        final daysInMonth = DateTime(now.year, i + 1, 0).day;
        
        for (int j = 1; j <= daysInMonth; j++) {
          final date = DateTime(now.year, i, j);
          if (date.isAfter(now)) break;
          final dateOnly = DateTime(date.year, date.month, date.day);
          
          // 统计已完成的天数
          if (widget.habit.dailyCompletionStatus.containsKey(dateOnly) &&
              widget.habit.dailyCompletionStatus[dateOnly] == true) {
            monthDuration += 30; // 假设每次完成专注30分钟
          }
        }
        
        spots.add(FlSpot((i - 1).toDouble(), monthDuration.toDouble()));
      }
    }
    
    return LineChartBarData(
      spots: spots,
      isCurved: true, // 曲线样式
      curveSmoothness: 0.3, // 曲线平滑度
      color: color,
      barWidth: ScreenUtil().setWidth(3), // 线条宽度
      isStrokeCapRound: true, // 线条两端为圆形
      dotData: FlDotData(show: true),
      // 添加背景填充
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1), // 半透明背景色
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  
  // 生成图表标题数据
  FlTitlesData _generateTitlesData({bool isCountChart = true}) {
    final now = DateTime.now();
    final List<String> titles = [];
    
    if (_timeRange == 'week') {
      // 生成周标题（周一到周日）
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        titles.add('${date.month}/${date.day}');
      }
    } else if (_timeRange == 'month') {
      // 生成月标题（按周）
      final weeksInMonth = (DateTime(now.year, now.month + 1, 0).day / 7).ceil();
      for (int i = 0; i < weeksInMonth; i++) {
        titles.add('第${i + 1}周');
      }
    } else { // year
      // 生成年标题（按月）
      for (int i = 1; i <= now.month; i++) {
        titles.add('${i}月');
      }
    }
    
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < titles.length) {
              return Padding(
                padding: EdgeInsets.only(top: ScreenUtil().setHeight(8)),
                child: Text(
                  titles[index],
                  style: TextStyle(fontSize: ScreenUtil().setSp(12)),
                ),
              );
            }
            return Container();
          },
          reservedSize: 40,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (isCountChart) {
              // 次数统计显示次数
              return Text('${value.toInt()}');
            } else {
              // 时间统计显示分钟数
              return Text('${value.toInt()}');
            }
          },
          reservedSize: 40,
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
  
  // 获取次数统计提示标签
  String _getCountTooltipLabel(int x, double value) {
    final now = DateTime.now();
    
    if (_timeRange == 'week') {
      final date = now.subtract(Duration(days: 6 - x));
      return '${date.month}/${date.day}: 完成${value.toInt()}次';
    } else if (_timeRange == 'month') {
      return '第${x + 1}周: 完成${value.toInt()}次';
    } else { // year
      return '${x + 1}月: 完成${value.toInt()}次';
    }
  }
  
  // 获取时间统计提示标签
  String _getTimeTooltipLabel(int x, double value) {
    final now = DateTime.now();
    
    if (_timeRange == 'week') {
      final date = now.subtract(Duration(days: 6 - x));
      return '${date.month}/${date.day}: ${value.toInt()}分钟';
    } else if (_timeRange == 'month') {
      return '第${x + 1}周: ${value.toInt()}分钟';
    } else { // year
      return '${x + 1}月: ${value.toInt()}分钟';
    }
  }
  

  
  // 上一个月
  void _previousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }
  
  // 下一个月
  void _nextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }
  
  // 获取当前周期标签
  String _getCurrentPeriodLabel() {
    // 对于周和月目标，固定显示对应周期的标签
    if (widget.habit.cycleType == CycleType.weekly) {
      return '本周';
    } else if (widget.habit.cycleType == CycleType.monthly) {
      return '本月';
    } else {
      // 对于其他类型，根据时间范围显示标签
      if (_timeRange == 'week') {
        return '本周';
      } else if (_timeRange == 'month') {
        return '本月';
      } else {
        return '本年';
      }
    }
  }
  
  
  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final stats = _calculateHabitStats();
    final completedDays = stats['completedDays'] as int;
    final remainingDays = stats['remainingDays'] as int;
    final hasTarget = widget.habit.cycleType != null && widget.habit.targetDays != null;
    
    // 创建只有当前习惯的列表用于日历
    final singleHabitList = [widget.habit];
    
    // 创建习惯颜色映射
    final habitColors = {
      widget.habit.name: widget.habit.color,
    };
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 设置页面整体背景色
      appBar: AppBar(
        title: Text('${widget.habit.name} 统计'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 去掉开头的习惯名称部分，直接显示统计内容
            
            // 饼状图 - 只有设置了目标才显示
            if (hasTarget)
              Container(
                margin: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(16), vertical: ScreenUtil().setHeight(12)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getCurrentPeriodLabel()}完成情况',
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(24),
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.onBackground(context),
                      ),
                    ),
                    SizedBox(height: ScreenUtil().setHeight(16)),
                    Container(
                      height: ScreenUtil().setHeight(300),
                      padding: EdgeInsets.only(left: ScreenUtil().setWidth(40)), // 增加左侧内边距，使整体向右平移
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight, // 饼图向右对齐
                              child: Padding(
                                padding: EdgeInsets.only(right: ScreenUtil().setWidth(10)), // 增加右侧内边距，使饼图整体右移
                                child: PieChart(
                                  PieChartData(
                                    sections: _generatePieData(),
                                    centerSpaceRadius: 40,
                                    sectionsSpace: 0,
                                    pieTouchData: PieTouchData(enabled: true),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: ScreenUtil().setWidth(40)), // 调整文字部分的左侧内边距
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: ScreenUtil().setWidth(16),
                                        height: ScreenUtil().setHeight(16),
                                        color: widget.habit.color,
                                      ),
                                      SizedBox(width: ScreenUtil().setWidth(8)),
                                      Text('完成: $completedDays 天'),
                                    ],
                                  ),
                                  SizedBox(height: ScreenUtil().setHeight(12)),
                                  Row(
                                    children: [
                                      Container(
                                        width: ScreenUtil().setWidth(16),
                                        height: ScreenUtil().setHeight(16),
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                      SizedBox(width: ScreenUtil().setWidth(8)),
                                      Text('剩余: $remainingDays 天'),
                                    ],
                                  ),
                                  SizedBox(height: ScreenUtil().setHeight(12)),
                                  Text(
                                    '完成率: ${(stats['completionRate'] * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: ScreenUtil().setSp(18),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // 月度完成日历
            Container(
              margin: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(16), vertical: ScreenUtil().setHeight(12)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedYear}年${_selectedMonth}月打卡记录',
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(24),
                          fontWeight: FontWeight.bold,
                          color: ThemeHelper.onBackground(context),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left),
                            onPressed: _previousMonth,
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right),
                            onPressed: _nextMonth,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(16)),
                  Container(
                    height: ScreenUtil().setHeight(450),
                    child: CalendarViewWidget(
                      habits: singleHabitList,
                      selectedYear: _selectedYear,
                      selectedMonth: _selectedMonth,
                      habitColors: habitColors,
                    ),
                  ),
                ],
              ),
            ),
            
            // 完成次数统计图表
            Container(
              margin: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(16), vertical: ScreenUtil().setHeight(12)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '习惯完成次数统计',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(24),
                      fontWeight: FontWeight.bold,
                      color: ThemeHelper.onBackground(context),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => _timeRange = 'week'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _timeRange == 'week' ? widget.habit.color : Colors.grey,
                        ),
                        child: Text('周'),
                      ),
                      SizedBox(width: ScreenUtil().setWidth(8)),
                      ElevatedButton(
                        onPressed: () => setState(() => _timeRange = 'month'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _timeRange == 'month' ? widget.habit.color : Colors.grey,
                        ),
                        child: Text('月'),
                      ),
                      SizedBox(width: ScreenUtil().setWidth(8)),
                      ElevatedButton(
                        onPressed: () => setState(() => _timeRange = 'year'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _timeRange == 'year' ? widget.habit.color : Colors.grey,
                        ),
                        child: Text('年'),
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(16)),
                  Container(
                    height: ScreenUtil().setHeight(300),
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [_generateCountTrendData()],
                        titlesData: _generateTitlesData(isCountChart: true),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((touchedSpot) {
                                final value = touchedSpot.y;
                                final index = touchedSpot.x.toInt();
                                return LineTooltipItem(
                                  '${_getCountTooltipLabel(index, value)}',
                                  TextStyle(color: Colors.black),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 专注时间统计图表
            Container(
              margin: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(16), vertical: ScreenUtil().setHeight(12)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '习惯专注时间统计 (分钟)',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(24),
                      fontWeight: FontWeight.bold,
                      color: ThemeHelper.onBackground(context),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(16)),
                  Container(
                    height: ScreenUtil().setHeight(300),
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [_generateTimeTrendData()],
                        titlesData: _generateTitlesData(isCountChart: false),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((touchedSpot) {
                                final value = touchedSpot.y;
                                final index = touchedSpot.x.toInt();
                                return LineTooltipItem(
                                  '${_getTimeTooltipLabel(index, value)}',
                                  TextStyle(color: Colors.black),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: ScreenUtil().setHeight(80)),
          ],
        ),
      ),
    );
  }
}