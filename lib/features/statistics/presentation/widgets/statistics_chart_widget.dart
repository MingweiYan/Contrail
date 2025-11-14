import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

class StatisticsChartWidget extends StatefulWidget {
  final List<Habit> habits;
  final String selectedPeriod;
  final int selectedYear;
  final int selectedMonth;
  final int selectedWeek;
  final List<bool> isHabitVisible;
  final WeekStartDay weekStartDay;

  const StatisticsChartWidget({
    super.key,
    required this.habits,
    required this.selectedPeriod,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedWeek,
    required this.isHabitVisible,
    required this.weekStartDay,
  });

  @override
  State<StatisticsChartWidget> createState() => _StatisticsChartWidgetState();
}

class _StatisticsChartWidgetState extends State<StatisticsChartWidget> {
  // 存储当前选中的数据点信息
  FlSpot? touchedSpot;
  // 存储当前选中的线条索引
  int? touchedBarIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.habits.isEmpty) {
      return const Center(child: Text('暂无习惯数据'));
    }

    // 获取习惯的颜色
    final List<String> habitNames = widget.habits.map((habit) => habit.name).toList();
    final List<Color> habitColors = widget.habits.map((habit) => habit.color).toList();

    final titles = _generateXAxisTitles();

    // 为每个习惯生成次数统计数据
    final List<LineChartBarData> countData = widget.habits.asMap().entries.map((entry) {
      final index = entry.key;
      final habit = entry.value;
      final data = _generateChartDataForType(habit, 'count');
      return _createLineChartBarData(data, habit.color, index);
    }).toList();

    // 为每个习惯生成时间统计数据
    final List<LineChartBarData> timeData = widget.habits.asMap().entries.map((entry) {
      final index = entry.key;
      final habit = entry.value;
      final data = _generateChartDataForType(habit, 'time');
      return _createLineChartBarData(data, habit.color, index);
    }).toList();

    // 过滤显示的数据
    final List<LineChartBarData> filteredCountData = [];
    final List<LineChartBarData> filteredTimeData = [];
    for (int i = 0; i < widget.habits.length; i++) {
      if (widget.isHabitVisible[i]) {
        filteredCountData.add(countData[i]);
        filteredTimeData.add(timeData[i]);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算图表高度，根据屏幕高度的一定比例
        final screenHeight = MediaQuery.of(context).size.height;
        final chartHeight = screenHeight * 0.25; // 图表高度为屏幕高度的25%

        return SingleChildScrollView(
      child: Column(
        children: [
          // 次数统计图表 - 添加独立的白色背景块
          Container(
            margin: StatisticsChartWidgetConstants.containerMargin,
            decoration: BoxDecoration(
              color: Colors.white, // 使用纯白色背景
              borderRadius: BorderRadius.circular(StatisticsChartWidgetConstants.containerBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: StatisticsChartWidgetConstants.containerPadding,
            child: Container(
              height: chartHeight,
              width: double.infinity,
              child: LineChart(
                _createLineChartData(
                  filteredCountData.isEmpty ? countData : filteredCountData,
                  titles,
                  'count',
                  habitNames,
                  habitColors,
                ),
              ),
            ),
          ),
          
          // 次数统计标题
          Padding(
            padding: StatisticsChartWidgetConstants.titlePadding,
            child: Text(
              '习惯完成次数统计',
              style: TextStyle(
                fontSize: StatisticsChartWidgetConstants.chartTitleFontSize,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.onBackground(context),
              ),
            ),
          ),

          // 时间统计图表 - 添加独立的白色背景块
          Container(
            margin: StatisticsChartWidgetConstants.containerMargin,
            decoration: BoxDecoration(
              color: Colors.white, // 使用纯白色背景
              borderRadius: BorderRadius.circular(StatisticsChartWidgetConstants.containerBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: StatisticsChartWidgetConstants.containerPadding,
            child: Container(
              height: chartHeight,
              width: double.infinity,
              child: LineChart(
                _createLineChartData(
                  filteredTimeData.isEmpty ? timeData : filteredTimeData,
                  titles,
                  'time',
                  habitNames,
                  habitColors,
                ),
              ),
            ),
          ),
          
          // 时间统计标题
          Padding(
            padding: StatisticsChartWidgetConstants.titlePadding,
            child: Text(
              '习惯专注时间统计 (分钟)',
              style: TextStyle(
                fontSize: StatisticsChartWidgetConstants.chartTitleFontSize,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.onBackground(context),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  // 创建线条数据
  LineChartBarData _createLineChartBarData(List<FlSpot> spots, Color color, int index) {
    return LineChartBarData(
      spots: spots,
      isCurved: true, // 曲线样式
      curveSmoothness: 0.3, // 曲线平滑度
      color: color,
      barWidth: StatisticsChartWidgetConstants.lineWidth,
      isStrokeCapRound: true, // 线条两端为圆形
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          // 根据是否选中显示不同样式的点
          return FlDotCirclePainter(
            radius: touchedSpot == spot && touchedBarIndex == index ? StatisticsChartWidgetConstants.dotRadiusSelected : StatisticsChartWidgetConstants.dotRadiusNormal,
            color: touchedSpot == spot && touchedBarIndex == index 
              ? color.withOpacity(1.0) 
              : color.withOpacity(0.8),
            strokeWidth: touchedSpot == spot && touchedBarIndex == index ? StatisticsChartWidgetConstants.dotStrokeWidth : 0,
            strokeColor: ThemeHelper.onBackground(context),
          );
        },
      ),
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

  // 创建图表数据
  LineChartData _createLineChartData(
    List<LineChartBarData> lineBarsData,
    List<String> titles,
    String chartType,
    List<String> habitNames,
    List<Color> habitColors,
  )
  {
    // 计算Y轴的最大值
    double maxY = 0;
    for (final barData in lineBarsData) {
      for (final spot in barData.spots) {
        if (spot.y > maxY) {
          maxY = spot.y;
        }
      }
    }
    
    // 根据图表类型和最大值设置不同的边距策略
    if (chartType == 'count') {
      // 次数统计：如果最大值不超过5次，直接使用习惯的最大值
      if (maxY > 0 && maxY <= 5) {
        // 直接使用习惯的最大值，不增加额外边距
        // maxY = maxY;  // 这是一个空操作，可以省略
      } else {
        // 添加一些边距
        maxY = maxY == 0 ? 10 : maxY * 1.1;
      }
    } else {
      // 时间统计保持原逻辑
      maxY = maxY == 0 ? 10 : maxY * 1.1;
    }

    return LineChartData(
      // 启用交互功能
      lineTouchData: LineTouchData(
          enabled: true,
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> indicators) {
            return indicators.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: barData.color != null ? barData.color!.withOpacity(0.3) : Colors.grey.shade300,
                  strokeWidth: ScreenUtil().setWidth(2),
                ),
                FlDotData(
                  show: false,
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final habitName = habitNames[touchedSpot.barIndex];
                final value = chartType == 'count' 
                  ? touchedSpot.y.toInt().toString() 
                  : touchedSpot.y.toStringAsFixed(1);
                final label = chartType == 'count' ? '完成次数' : '专注时间(分钟)';
                
                return LineTooltipItem(
                  '$habitName: $value $label\n',
                  TextStyle(color: habitColors[touchedSpot.barIndex]),
                );
              }).toList();
            },
            // 在0.68.0版本中，我们使用默认的tooltip样式
          ),
        // 设置触摸回调
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          setState(() {
            if (event is FlTapUpEvent || event is FlPanEndEvent) {
              // 触摸结束，重置选中状态
              touchedSpot = null;
              touchedBarIndex = null;
            } else if (touchResponse != null &&
                touchResponse.lineBarSpots != null &&
                touchResponse.lineBarSpots!.isNotEmpty) {
              // 触摸中，更新选中状态
              final spot = touchResponse.lineBarSpots![0];
              touchedSpot = FlSpot(spot.x, spot.y);
              touchedBarIndex = spot.barIndex;
            }
          });
        },
      ),
      // 标题配置
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < titles.length) {
                return Padding(
                  padding: EdgeInsets.only(top: ScreenUtil().setHeight(8)),
                  child: Text(
                    titles[value.toInt()],
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(16),
                      color: ThemeHelper.onSurfaceVariant(context),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
            interval: 1,
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: chartType == 'count' ? 1 : maxY / 5,
            getTitlesWidget: (value, meta) {
              if (value == meta.min || value == meta.max || value % (chartType == 'count' ? 1 : maxY / 5) < 0.01) {
                return Text(
                  chartType == 'count' 
                    ? value.toInt().toString() 
                    : value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaleFactor * 12,
                    color: ThemeHelper.onSurfaceVariant(context),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      // 网格线配置 - 关闭背景虚线
      gridData: FlGridData(
        show: false,
      ),
      // 边框配置 - 只显示底部和左侧边框
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
                    color: ThemeHelper.outline(context),
                    width: ScreenUtil().setWidth(1),
                  ),
                  left: BorderSide(
                    color: ThemeHelper.outline(context),
                    width: ScreenUtil().setWidth(1),
                  ),
          top: BorderSide.none,
          right: BorderSide.none,
        ),
      ),
      // 限制范围
      minX: 0,
      maxX: (titles.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      // 线条数据
      lineBarsData: lineBarsData,
    );
  }

  // 根据统计类型生成图表数据
  List<FlSpot> _generateChartDataForType(Habit habit, String statType) {
    final spots = <FlSpot>[];

    if (widget.selectedPeriod == 'week') {
      // 周聚合 - 使用选中的周和年份
      // 获取选中周的第一天（周一）
      final firstDayOfWeek = _getStartOfWeek(widget.selectedWeek, widget.selectedYear);
      for (int i = 0; i < 7; i++) {
        double value = 0;
        final targetDate = firstDayOfWeek.add(Duration(days: i));
        final dateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);

        if (statType == 'count') {
          // 次数统计
          value = habit.dailyCompletionStatus.containsKey(dateOnly) &&
              habit.dailyCompletionStatus[dateOnly] == true ? 1 : 0;
        } else {
          // 时间统计 (分钟)
          final duration = sl<HabitStatisticsService>().getTotalDurationForDay(habit, targetDate);
          value = duration.inMinutes.toDouble();
        }
        spots.add(FlSpot(i.toDouble(), value));
      }
    } else if (widget.selectedPeriod == 'month') {
      // 月维度：按周聚合数据
      // 获取当月的周范围
      final monthStartDate = DateTime(widget.selectedYear, widget.selectedMonth, 1);
      final monthEndDate = DateTime(widget.selectedYear, widget.selectedMonth + 1, 0);
      
      // 获取月份包含的周范围（确保从周一到周日）
      final weeks = _getMonthWeeks(monthStartDate, monthEndDate);
      
      for (int i = 0; i < weeks.length; i++) {
        double value = 0;
        final weekStart = weeks[i]['start'] as DateTime;
        final weekEnd = weeks[i]['end'] as DateTime;
        
        if (statType == 'count') {
          // 次数统计 - 统计整周的完成次数
          int weeklyCount = 0;
          for (DateTime date = weekStart; date.isBefore(weekEnd.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
            final dateOnly = DateTime(date.year, date.month, date.day);
            if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
                habit.dailyCompletionStatus[dateOnly] == true) {
              weeklyCount++;
            }
          }
          value = weeklyCount.toDouble();
        } else {
          // 时间统计 (分钟) - 统计整周的总时长
          int weeklyMinutes = 0;
          for (DateTime date = weekStart; date.isBefore(weekEnd.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
            final duration = sl<HabitStatisticsService>().getTotalDurationForDay(habit, date);
            weeklyMinutes += duration.inMinutes.toInt();
          }
          value = weeklyMinutes.toDouble();
        }
        spots.add(FlSpot(i.toDouble(), value));
      }
    } else { // year
      // 年维度：显示选中年份的12个月数据
      for (int month = 1; month <= 12; month++) {
        double value = 0;

        if (statType == 'count') {
          // 月度完成次数统计
          int monthlyCount = 0;
          final daysInMonth = DateTime(widget.selectedYear, month + 1, 0).day;
          for (int day = 1; day <= daysInMonth; day++) {
            final dateOnly = DateTime(widget.selectedYear, month, day);
            if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
                habit.dailyCompletionStatus[dateOnly] == true) {
              monthlyCount++;
            }
          }
          value = monthlyCount.toDouble();
        } else {
          // 月度总时间统计 (分钟)
          int monthlyMinutes = 0;
          final daysInMonth = DateTime(widget.selectedYear, month + 1, 0).day;
          for (int day = 1; day <= daysInMonth; day++) {
            final date = DateTime(widget.selectedYear, month, day);
            final duration = sl<HabitStatisticsService>().getTotalDurationForDay(habit, date);
            monthlyMinutes += duration.inMinutes.toInt();
          }
          value = monthlyMinutes.toDouble();
        }

        spots.add(FlSpot((month - 1).toDouble(), value));
      }
    }

    return spots;
  }
  
  // 获取月份包含的所有周范围（根据用户设置的周起始日）
  List<Map<String, dynamic>> _getMonthWeeks(DateTime monthStart, DateTime monthEnd) {
    final weeks = <Map<String, dynamic>>[];
    
    DateTime startOfFirstWeek;
    DateTime endOfLastWeek;
    
    if (widget.weekStartDay == WeekStartDay.monday) {
      // 周一为起始日
      // 计算月份第一天是星期几，调整到本周一
      final firstDayWeekday = monthStart.weekday;
      final daysToMonday = firstDayWeekday == 7 ? 0 : 7 - firstDayWeekday;
      startOfFirstWeek = monthStart.subtract(Duration(days: daysToMonday));
      
      // 计算月份最后一天是星期几，调整到下周日
      final lastDayWeekday = monthEnd.weekday;
      final daysToSunday = lastDayWeekday == 7 ? 0 : 7 - lastDayWeekday;
      endOfLastWeek = monthEnd.add(Duration(days: daysToSunday));
    } else {
      // 周日为起始日
      // 计算月份第一天是星期几，调整到本周日
      final firstDayWeekday = monthStart.weekday;
      final daysToSunday = firstDayWeekday == 7 ? 0 : 7 - firstDayWeekday;
      startOfFirstWeek = monthStart.subtract(Duration(days: daysToSunday));
      
      // 计算月份最后一天是星期几，调整到下周六
      final lastDayWeekday = monthEnd.weekday;
      final daysToSaturday = lastDayWeekday == 6 ? 0 : 6 - lastDayWeekday;
      endOfLastWeek = monthEnd.add(Duration(days: daysToSaturday));
    }
    
    // 生成每周的开始和结束日期
    DateTime currentWeekStart = startOfFirstWeek;
    while (currentWeekStart.isBefore(endOfLastWeek.add(const Duration(days: 1)))) {
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
      weeks.add({
        'start': currentWeekStart,
        'end': currentWeekEnd,
        'label': '第${_getWeekNumber(currentWeekStart)}周'
      });
      currentWeekStart = currentWeekEnd.add(const Duration(days: 1));
    }
    
    return weeks;
  }

  // 计算日期是当年的第几周
  int _getWeekNumber(DateTime date) {
    // 计算日期是当年的第几周
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    int daysToFirstWeekStart;
    
    if (widget.weekStartDay == WeekStartDay.monday) {
      // 每周从周一开始
      final firstDayOfYearWeekday = firstDayOfYear.weekday;
      daysToFirstWeekStart = firstDayOfYearWeekday == 7 ? 0 : 7 - firstDayOfYearWeekday;
    } else {
      // 每周从周日开始
      final firstDayOfYearWeekday = firstDayOfYear.weekday;
      daysToFirstWeekStart = firstDayOfYearWeekday == 7 ? 0 : 7 - firstDayOfYearWeekday;
    }
    
    final adjustedDays = days - daysToFirstWeekStart;
    return adjustedDays >= 0 ? (adjustedDays ~/ 7) + 1 : 1;
  }

  // 获取周的第一天（根据用户设置）
  DateTime _getStartOfWeek(int weekNumber, int year) {
    final firstDayOfYear = DateTime(year, 1, 1);
    DateTime firstWeekStart;
    
    if (widget.weekStartDay == WeekStartDay.monday) {
      // 周一为起始日
      final firstDayOfYearWeekday = firstDayOfYear.weekday;
      final daysToFirstMonday = firstDayOfYearWeekday == 7 ? 0 : 7 - firstDayOfYearWeekday;
      firstWeekStart = firstDayOfYear.add(Duration(days: daysToFirstMonday));
    } else {
      // 周日为起始日
      final firstDayOfYearWeekday = firstDayOfYear.weekday;
      final daysToFirstSunday = firstDayOfYearWeekday == 7 ? 0 : 7 - firstDayOfYearWeekday;
      firstWeekStart = firstDayOfYear.add(Duration(days: daysToFirstSunday));
    }
    
    return firstWeekStart.add(Duration(days: (weekNumber - 1) * 7));
  }

  List<String> _generateXAxisTitles() {
    final titles = <String>[];

    if (widget.selectedPeriod == 'week') {
      // 周聚合 - 使用选中的周和年份
      final firstDayOfWeek = _getStartOfWeek(widget.selectedWeek, widget.selectedYear);
      for (int i = 0; i < 7; i++) {
        final date = firstDayOfWeek.add(Duration(days: i));
        titles.add('${date.month}/${date.day}'); // 月/日
      }
    } else if (widget.selectedPeriod == 'month') {
      // 月维度：按周显示，确保从周一到周日
      final monthStartDate = DateTime(widget.selectedYear, widget.selectedMonth, 1);
      final monthEndDate = DateTime(widget.selectedYear, widget.selectedMonth + 1, 0);
      
      // 获取月份包含的周范围
      final weeks = _getMonthWeeks(monthStartDate, monthEndDate);
      
      // 生成每周的标题（显示周数和日期范围）
      for (var week in weeks) {
        final weekStart = week['start'] as DateTime;
        final weekEnd = week['end'] as DateTime;
        
        // 生成简洁的日期范围显示
        if (weekStart.month == weekEnd.month) {
          // 同月显示：月/日-日
          titles.add('${weekStart.month}/${weekStart.day}-${weekEnd.day}');
        } else {
          // 跨月显示：月/日-月/日
          titles.add('${weekStart.month}/${weekStart.day}-${weekEnd.month}/${weekEnd.day}');
        }
      }
    } else { // year
      // 年维度：显示选中年份的12个月
      for (int month = 1; month <= 12; month++) {
        titles.add('$month月');
      }
    }

    return titles;
  }
}