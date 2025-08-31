import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:calendar_view/calendar_view.dart';
import 'dart:math' as math;
import '../providers/habit_provider.dart';
import '../models/habit.dart';

// 定义习惯图表配置类
class HabitChartConfig {
  final Color color;
  final String dotShape;

  HabitChartConfig({
    required this.color,
    required this.dotShape,
  });
  

  // 根据字符串获取对应的点形状
  FlDotData getDotData() {
    return FlDotData(show: true);
  }
}

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String _selectedPeriod = 'week'; // 'week', 'month', 'year' (实际显示为: 周, 月, 年)
  String _selectedView = 'trend'; // 'trend' 或 'detail'
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String _detailViewType = 'calendar'; // 'calendar' 或 'timeline' - 提升为类成员变量
  List<bool>? _isHabitVisible; // 跟踪每个习惯的显示状态

  // 为不同习惯配置不同颜色和点形状
  final Map<String, HabitChartConfig> _habitConfigs = {};

  // 预设一些颜色和点形状
  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.teal,
  ];

  final List<String> _dotShapes = [
    'circle',
    'square',
    'triangle',
    'diamond',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初始化习惯配置
    final habitProvider = Provider.of<HabitProvider>(context);
    if (habitProvider.habits.isNotEmpty) {
      _initializeHabitConfigs(habitProvider.habits);
    }
  }

  // 初始化习惯配置
  void _initializeHabitConfigs(List<Habit> habits) {
    _habitConfigs.clear();
    for (int i = 0; i < habits.length; i++) {
      final habit = habits[i];
      final colorIndex = i % _colors.length;
      final shapeIndex = i % _dotShapes.length;
      _habitConfigs[habit.name] = HabitChartConfig(
        color: _colors[colorIndex],
        dotShape: _dotShapes[shapeIndex],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final habits = habitProvider.habits;

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 视图切换
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['trend', 'detail'].map((view) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 24.0, 8.0),
                    child: ElevatedButton(
                      onPressed: () => setState(() => _selectedView = view),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedView == view ? Colors.blue : null,
                      ),
                      child: Text(view == 'trend' ? '趋势' : '明细'),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 图表设置区域
            if (_selectedView == 'trend')
              Column(
                children: [
                  // 时间周期选择器
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['week', 'month', 'year'].map((period) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 24.0, 8.0),
                          child: ElevatedButton(
                            onPressed: () => setState(() => _selectedPeriod = period),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedPeriod == period ? Colors.blue : null,
                            ),
                            child: Text(period == 'week' ? '周' : period == 'month' ? '月' : '年'),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

          // 年份月份选择器
          if (_selectedPeriod == 'year' || _selectedPeriod == 'month')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: () => setState(() {
                      if (_selectedPeriod == 'year') {
                        _selectedYear--;
                      } else {
                        _selectedMonth--;
                        if (_selectedMonth < 1) {
                          _selectedMonth = 12;
                          _selectedYear--;
                        }
                      }
                    }),
                  ),
                  Text(
                    _selectedPeriod == 'year' ? '$_selectedYear年' : '${_selectedYear}年${_selectedMonth}月',
                    style: const TextStyle(fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: () => setState(() {
                      if (_selectedPeriod == 'year') {
                        _selectedYear++;
                      } else {
                        _selectedMonth++;
                        if (_selectedMonth > 12) {
                          _selectedMonth = 1;
                          _selectedYear++;
                        }
                      }
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),

      // 统计区域
      SizedBox(
        height: MediaQuery.of(context).size.height - 200, // 设置适当的高度
        child: _selectedView == 'trend' ? _buildCharts() : _buildDetailView(),
      ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    final habitProvider = Provider.of<HabitProvider>(context);
    final habits = habitProvider.habits;

    if (habits.isEmpty) {
      return const Center(child: Text('暂无习惯数据'));
    }

    // 初始化习惯可见性状态
    if (_isHabitVisible == null || _isHabitVisible!.length != habits.length) {
      _isHabitVisible = List<bool>.filled(habits.length, true);
    }

    final titles = _generateXAxisTitles();

    // 为每个习惯生成次数统计数据
    final List<LineChartBarData> countData = [];
    final List<String> habitNames = [];
    final List<Color> habitColors = [];
    for (int i = 0; i < habits.length; i++) {
      final habit = habits[i];
      final color = _habitConfigs.containsKey(habit.name) ? _habitConfigs[habit.name]!.color : _colors[i % _colors.length];
      final data = _generateChartDataForType(habit, 'count');
      habitNames.add(habit.name);
      habitColors.add(color);
      countData.add(LineChartBarData(
            spots: data,
            isCurved: false, // 折线图
            color: color,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ));
    }

    // 为每个习惯生成时间统计数据
    final List<LineChartBarData> timeData = [];
    for (int i = 0; i < habits.length; i++) {
      final habit = habits[i];
      final color = _habitConfigs.containsKey(habit.name) ? _habitConfigs[habit.name]!.color : _colors[i % _colors.length];
      final data = _generateChartDataForType(habit, 'time');
      timeData.add(LineChartBarData(
            spots: data,
            isCurved: false, // 折线图
            color: color,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ));
    }

    // 创建图例组件
    Widget buildLegend() {
      List<Widget> legendItems = [];
      for (int i = 0; i < habits.length; i++) {
        final habit = habits[i];
        final color = _isHabitVisible![i] ? habitColors[i] : habitColors[i].withOpacity(0.3);
        legendItems.add(
          GestureDetector(
            onTap: () {
              setState(() {
                _isHabitVisible![i] = !_isHabitVisible![i];
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 16.0),
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                Text(habit.name, style: TextStyle(color: _isHabitVisible![i] ? Colors.black : Colors.grey.shade500)),
              ],
            ),
          ),
        );
      }
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 16.0,
        runSpacing: 8.0,
        children: legendItems,
      );
    }

    // 过滤显示的数据
    final List<LineChartBarData> filteredCountData = [];
    final List<LineChartBarData> filteredTimeData = [];
    for (int i = 0; i < habits.length; i++) {
      if (_isHabitVisible![i]) {
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
              // 图例
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildLegend(),
              ),

              // 次数统计图表
              Container(
                height: chartHeight,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 24.0, 8.0),
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text(
                            titles[value.toInt()],
                            style: TextStyle(fontSize: MediaQuery.of(context).textScaleFactor * 12),
                          ),
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: filteredCountData.isEmpty ? countData : filteredCountData,
                  ),
                ),
              ),

              // 次数统计标题
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '习惯完成次数统计',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaleFactor * 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 时间统计图表
              Container(
                height: chartHeight,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 24.0, 8.0),
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text(
                            titles[value.toInt()],
                            style: TextStyle(fontSize: MediaQuery.of(context).textScaleFactor * 12),
                          ),
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: filteredTimeData.isEmpty ? timeData : filteredTimeData,
                  ),
                ),
              ),

              // 时间统计标题
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '习惯专注时间统计 (分钟)',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaleFactor * 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 根据统计类型生成图表数据
  List<FlSpot> _generateChartDataForType(Habit habit, String statType) {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    int count = _selectedPeriod == 'week' ? 7 : _selectedPeriod == 'month' ? 4 : 12;

    for (int i = 0; i < count; i++) {
      double value = 0;

      if (_selectedPeriod == 'week') {
        // 周聚合（实际显示为"周"）
        final targetDate = DateTime(now.year, now.month, now.day - (count - 1 - i));
        final dateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);

        if (statType == 'count') {
          // 次数统计
          value = habit.dailyCompletionStatus.containsKey(dateOnly) &&
              habit.dailyCompletionStatus[dateOnly] == true ? 1 : 0;
        } else {
          // 时间统计 (分钟)
          final duration = habit.getTotalDurationForDay(targetDate);
          value = duration.inMinutes.toDouble();
        }
      } else if (_selectedPeriod == 'month') {
        // 月聚合（实际显示为"月"，按周统计）
        final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
        final lastDayOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);

        // 计算月份的第一周和最后一周
        final firstWeek = _getWeekNumber(firstDayOfMonth);
        final lastWeek = _getWeekNumber(lastDayOfMonth);

        // 确保只显示4周数据
        final displayWeekCount = 4;
        // 计算起始周数（确保显示最近的4周）
        final startWeek = lastWeek - displayWeekCount + 1;

        // 计算当前周
        final currentWeek = startWeek + i;

        // 计算当前周的起始和结束日期
        final startOfWeek = _getStartOfWeek(currentWeek, _selectedYear);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        // 确保周在当前月份内
        final actualStart = startOfWeek.isBefore(firstDayOfMonth) ? firstDayOfMonth : startOfWeek;
        final actualEnd = endOfWeek.isAfter(lastDayOfMonth) ? lastDayOfMonth : endOfWeek;

        // 检查该周是否有完成的习惯
        bool hasCompletion = false;
        if (statType == 'count') {
          // 次数统计 (每周完成次数)
          int weeklyCount = 0;
          for (DateTime date = actualStart; date.isBefore(actualEnd.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
            final dateOnly = DateTime(date.year, date.month, date.day);
            if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
                habit.dailyCompletionStatus[dateOnly] == true) {
              weeklyCount++;
              hasCompletion = true;
            }
          }
          value = hasCompletion ? weeklyCount.toDouble() : 0;
        } else {
          // 时间统计 (每周总分钟数)
          int weeklyMinutes = 0;
          for (DateTime date = actualStart; date.isBefore(actualEnd.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
            final duration = habit.getTotalDurationForDay(date);
            weeklyMinutes += duration.inMinutes;
            if (duration.inMinutes > 0) {
              hasCompletion = true;
            }
          }
          value = hasCompletion ? weeklyMinutes.toDouble() : 0;
        }
      } else { // year
        // 年聚合，固定显示1-12月
        final targetMonth = i + 1; // 从1月开始
        final targetYear = _selectedYear;

        if (statType == 'count') {
          // 月度完成次数统计
          int monthlyCount = 0;
          final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
          for (int day = 1; day <= daysInMonth; day++) {
            final dateOnly = DateTime(targetYear, targetMonth, day);
            if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
                habit.dailyCompletionStatus[dateOnly] == true) {
              monthlyCount++;
            }
          }
          value = monthlyCount.toDouble();
        } else {
          // 月度总时间统计 (分钟)
          int monthlyMinutes = 0;
          final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
          for (int day = 1; day <= daysInMonth; day++) {
            final date = DateTime(targetYear, targetMonth, day);
            final duration = habit.getTotalDurationForDay(date);
            monthlyMinutes += duration.inMinutes;
          }
          value = monthlyMinutes.toDouble();
        }
      }

      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }

  // 明细视图 - 包含日历和时间轴切换
  Widget _buildDetailView() {
    return Column(
      children: [
        // 视图类型选择
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['calendar', 'timeline'].map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _detailViewType = type;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _detailViewType == type ? Colors.blue : null,
                  ),
                  child: Text(type == 'calendar' ? '月度日历' : '时间轴'),
                ),
              );
            }).toList(),
          ),
        ),

        // 月份选择器
        if (_detailViewType == 'calendar' || _detailViewType == 'timeline')
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: () => setState(() {
                    _selectedMonth--;
                    if (_selectedMonth < 1) {
                      _selectedMonth = 12;
                      _selectedYear--;
                    }
                  }),
                ),
                Text('${_selectedYear}年${_selectedMonth}月', style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: () => setState(() {
                    _selectedMonth++;
                    if (_selectedMonth > 12) {
                      _selectedMonth = 1;
                      _selectedYear++;
                    }
                  }),
                ),
              ],
            ),
          ),

        // 显示内容
        Expanded(
          child: _detailViewType == 'calendar' ? _buildCalendarView() : _buildTimelineView(),
        ),
      ],
    );
  }

  // 月度日历视图
  Widget _buildCalendarView() {
    final habitProvider = Provider.of<HabitProvider>(context);
    final habits = habitProvider.habits;

    // 为每个习惯分配颜色
    final List<Color> habitColors = [];
    for (int i = 0; i < habits.length; i++) {
      final color = _habitConfigs.containsKey(habits[i].name) 
          ? _habitConfigs[habits[i].name]!.color 
          : _colors[i % _colors.length];
      habitColors.add(color);
    }

    // 获取当月天数
    final startDate = DateTime(_selectedYear, _selectedMonth, 1);
    final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final daysInMonth = endDate.day;

    // 计算日历所需高度
    final screenHeight = MediaQuery.of(context).size.height;
    final calendarHeight = screenHeight * 0.6; // 占屏幕高度的60%

    // 动态调整单元格宽高比
    double cellAspectRatio = 1.0;
    if (habits.length > 3) {
      // 如果习惯数量较多，减少宽高比以增加单元格高度
      cellAspectRatio = 0.8;
    }

    return Container(
      height: calendarHeight,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, // 7列，对应星期
          childAspectRatio: cellAspectRatio,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: 7 + daysInMonth, // 7天标题 + 当月天数
        itemBuilder: (context, index) {
          // 星期标题
          if (index < 7) {
            final weekDays = ['日', '一', '二', '三', '四', '五', '六'];
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(weekDays[index], style: TextStyle(fontWeight: FontWeight.bold)),
            );
          }

          // 日期单元格
          final day = index - 6; // 调整为从1开始的日期
          if (day > daysInMonth) return Container();

          final date = DateTime(_selectedYear, _selectedMonth, day);
          final dateOnly = DateTime(date.year, date.month, date.day);
          final weekday = date.weekday % 7; // 0-6，对应周日到周六

          // 检查哪些习惯在当天完成
          List<int> completedHabitIndices = [];
          for (int i = 0; i < habits.length; i++) {
            final habit = habits[i];
            if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
                habit.dailyCompletionStatus[dateOnly] == true) {
              completedHabitIndices.add(i);
            }
          }

          // 构建单元格内容
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 日期
                Container(
                  alignment: Alignment.topRight,
                  padding: EdgeInsets.all(4.0),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      color: weekday == 0 || weekday == 6 ? Colors.red : Colors.black,
                    ),
                  ),
                ),
                // 习惯完成标记
                Expanded(
                  child: completedHabitIndices.isEmpty
                      ? Container()
                      : GridView.builder(
                          shrinkWrap: true,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: completedHabitIndices.length > 3 ? 2 : 1,
                            childAspectRatio: 3.0,
                          ),
                          itemCount: completedHabitIndices.length,
                          itemBuilder: (context, i) {
                            final habitIndex = completedHabitIndices[i];
                            final color = habitColors[habitIndex];
                            return Container(
                              margin: EdgeInsets.all(2.0),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                habits[habitIndex].name.length > 4
                                    ? habits[habitIndex].name.substring(0, 4) + '...'
                                    : habits[habitIndex].name,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  
  }

  // 时间轴视图
  Widget _buildTimelineView() {
    final habitProvider = Provider.of<HabitProvider>(context);
    final habits = habitProvider.habits;

    // 获取当前月份的开始和结束日期
    final startDate = DateTime(_selectedYear, _selectedMonth, 1);
    final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0);

    // 收集所有专注记录
    List<Map<String, dynamic>> focusSessions = [];

    for (final habit in habits) {
      final color = _habitConfigs.containsKey(habit.name) 
          ? _habitConfigs[habit.name]!.color 
          : _colors[habits.indexOf(habit) % _colors.length];

      // 遍历习惯的所有专注记录
      habit.trackingDurations.forEach((startTime, durations) {
        // 检查是否在当前月份
        if (startTime.year == _selectedYear && startTime.month == _selectedMonth) {
          for (final duration in durations) {
            final endTime = startTime.add(duration);
            focusSessions.add({
              'habitName': habit.name,
              'color': color,
              'startTime': startTime,
              'endTime': endTime,
              'duration': duration,
            });
          }
        }
      });
    }

    // 按开始时间排序
    focusSessions.sort((a, b) => a['startTime'].compareTo(b['startTime']));

    // 如果没有数据，显示提示
    if (focusSessions.isEmpty) {
      return Center(
        child: Text('当月没有专注记录'),
      );
    }

    // 计算每个项目的顶部位置（用于定位）
    final itemHeights = List.generate(focusSessions.length, (index) => 120.0); // 估算每个项的高度
    final cumulativeHeights = <double>[];
    double sum = 0;
    for (final height in itemHeights) {
      cumulativeHeights.add(sum);
      sum += height + 16; // 加上padding
    }

    return Stack(
      children: [
        // 左侧时间轴（独立元素）
        Positioned(
          left: 16.0 + 12.0, // 16是ListView的padding，12是SizedBox的一半宽度
          top: 0,
          bottom: 0,
          width: 3.0,
          child: Container(
            color: Colors.grey.shade700,
          ),
        ),

        // 记录列表
        ListView.builder(
          itemCount: focusSessions.length,
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          itemBuilder: (context, index) {
            final session = focusSessions[index];
            final startTime = DateFormat('HH:mm').format(session['startTime']);
            final endTime = DateFormat('HH:mm').format(session['endTime']);
            final date = DateFormat('MM月dd日').format(session['startTime']);
            final duration = session['duration'] as Duration;
            final durationStr = '${duration.inHours}小时${duration.inMinutes % 60}分钟';
            final color = session['color'] as Color;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 时间轴圆点（覆盖在独立时间轴上）
                    SizedBox(
                      width: 24.0,
                      child: Container(
                        width: 12.0,
                        height: 12.0,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 内容
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: 12.0),
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: Colors.white.withOpacity(0.9),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 习惯名称和日期
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  session['habitName'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  date,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),

                            // 时间
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                '$startTime - $endTime',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            // 时长
                            Text(
                              durationStr,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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

  // 获取周的第一天（周一）
  DateTime _getStartOfWeek(int weekNumber, int year) {
    final firstDayOfYear = DateTime(year, 1, 1);
    final firstDayOfYearWeekday = firstDayOfYear.weekday;
    final daysToFirstMonday = firstDayOfYearWeekday == 7 ? 0 : 7 - firstDayOfYearWeekday;
    final firstMonday = firstDayOfYear.add(Duration(days: daysToFirstMonday));
    return firstMonday.add(Duration(days: (weekNumber - 1) * 7));
  }

  // 图例项构建函数
  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // 计算日期是当年的第几天
  int _getDayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  List<String> _generateXAxisTitles() {
    final titles = <String>[];
    int count = _selectedPeriod == 'week' ? 7 : _selectedPeriod == 'month' ? 4 : 12; // 月视图固定显示4周数据

    if (_selectedPeriod == 'week') {
      final now = DateTime.now();
      // 周聚合（实际显示为"周"）
      for (int i = 0; i < count; i++) {
        final date = DateTime(now.year, now.month, now.day - (count - 1 - i));
        titles.add('${date.month}/${date.day}'); // 月/日
      }
    } else if (_selectedPeriod == 'month') {
      // 月聚合（实际显示为"月"，显示周数）
      // 获取当前月份的所有周
      final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
      final lastDayOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);

      // 计算月份的第一周和最后一周
      final firstWeek = _getWeekNumber(firstDayOfMonth);
      final lastWeek = _getWeekNumber(lastDayOfMonth);

      // 确保只显示4周数据
      final displayWeekCount = 4;
      // 计算起始周数（确保显示最近的4周）
      final startWeek = lastWeek - displayWeekCount + 1;

      // 添加周标题（从startWeek开始，显示displayWeekCount个）
      for (int i = 0; i < displayWeekCount; i++) {
        final week = startWeek + i;
        titles.add('第$week周');
      }
    } else { // year
      // 年聚合，固定显示1-12月
      for (int month = 1; month <= 12; month++) {
        titles.add('$month月');
      }
    }

    return titles;
  }

  
}