import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_result_provider.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/services/habit_color_registry.dart';

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
  late final StatisticsResultProvider _statisticsResultProvider;
  late final HabitStatisticsService _statisticsService;
  String _periodType = 'month';
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    logger.debug('📊  StatsResultPage 初始化');
    logger.debug('🔧  构造参数: statisticsData=${widget.statisticsData != null ? '有数据' : '无数据'}, periodType=${widget.periodType}');
    _statisticsService = sl<HabitStatisticsService>();
    _statisticsResultProvider = StatisticsResultProvider();
    _loadStatistics();
  }

  @override
  void dispose() {
    _statisticsResultProvider.dispose();
    super.dispose();
  }

  // 加载统计数据
  Future<void> _loadStatistics() async {
    try {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      await _statisticsResultProvider.loadStatistics(
        preloadedData: widget.statisticsData,
        periodType: _periodType,
        habits: habitProvider.habits,
        selectedYear: _selectedYear,
        selectedMonth: _periodType == 'month' ? _selectedMonth : null,
      );
    } catch (e) {
      logger.error('❌  加载统计数据失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加载统计数据失败')),
      );
    }
  }


  // 获取当前月的习惯完成次数数据（用于饼状图）
  Map<String, int> _getMonthlyHabitCompletionCounts() {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    if (_periodType == 'year') {
      return _statisticsService.getYearlyHabitCompletionCountsFor(habitProvider.habits, year: _selectedYear);
    }
    return _statisticsService.getMonthlyHabitCompletionCountsFor(
      habitProvider.habits,
      year: _selectedYear,
      month: _selectedMonth,
    );
  }

  // 获取当前月的习惯完成时间数据（用于饼状图）
  Map<String, int> _getMonthlyHabitCompletionMinutes() {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    if (_periodType == 'year') {
      return _statisticsService.getYearlyHabitCompletionMinutesFor(habitProvider.habits, year: _selectedYear);
    }
    return _statisticsService.getMonthlyHabitCompletionMinutesFor(
      habitProvider.habits,
      year: _selectedYear,
      month: _selectedMonth,
    );
  }



  // 获取有目标的习惯及其完成度数据（用于柱状图）
  List<Map<String, dynamic>> _getHabitGoalCompletionData() {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    DateTime startDate, endDate;
    if (_periodType == 'month') {
      startDate = DateTime(_selectedYear, _selectedMonth, 1);
      endDate = DateTime(_selectedYear, _selectedMonth + 1, 0);
    } else if (_periodType == 'year') {
      startDate = DateTime(_selectedYear, 1, 1);
      endDate = DateTime(_selectedYear, 12, 31);
    } else {
      final now = DateTime.now();
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
    }
    return _statisticsService.getHabitGoalCompletionDataFor(
      habitProvider.habits,
      startDate: startDate,
      endDate: endDate,
    );
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
              width: ScreenUtil().setWidth(20),
              borderRadius: BorderRadius.all(Radius.circular(ScreenUtil().setWidth(4))),
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
          Text('习惯目标完成度', style: TextStyle(fontSize: StatsShareResultPageConstants.sectionTitleFontSize, fontWeight: FontWeight.bold)),
          SizedBox(height: StatsShareResultPageConstants.titleChartSpacing),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
            child: SizedBox(
            height: StatsShareResultPageConstants.chartHeight,
            child: Semantics(
              label: '习惯目标完成度柱状图',
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
                            width: ScreenUtil().setWidth(72),
                            child: Text(
                              goalCompletionData[index]['name'].toString(),
                              style: TextStyle(fontSize: StatsShareResultPageConstants.axisLabelFontSize, color: ThemeHelper.onBackground(context)),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: ScreenUtil().setWidth(48),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: StatsShareResultPageConstants.axisLabelFontSize, color: ThemeHelper.onBackground(context)),
                        );
                      },
                      reservedSize: ScreenUtil().setWidth(48),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false, horizontalInterval: 0.25, getDrawingHorizontalLine: (value) => FlLine(color: Colors.black.withOpacity(0.06), strokeWidth: ScreenUtil().setWidth(1))),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final name = goalCompletionData[group.x]['name'];
                      final pct = (rod.toY * 100).toStringAsFixed(0);
                      return BarTooltipItem(
                        '$name\n$pct%',
                        TextStyle(color: ThemeHelper.onBackground(context), fontSize: ScreenUtil().setSp(14), fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              ),
            ),
            ),
          ),
          ),
        ],
    );
  }

  Widget _buildPeriodControls() {
    return Padding(
      padding: EdgeInsets.all(ScreenUtil().setWidth(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('月'),
                selected: _periodType == 'month',
                onSelected: (_) => setState(() { _periodType = 'month'; _loadStatistics(); }),
              ),
              SizedBox(width: ScreenUtil().setWidth(8)),
              ChoiceChip(
                label: const Text('年'),
                selected: _periodType == 'year',
                onSelected: (_) => setState(() { _periodType = 'year'; _loadStatistics(); }),
              ),
            ],
          ),
          SizedBox(height: ScreenUtil().setHeight(12)),
          if (_periodType == 'month')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () { setState(() { final m = _selectedMonth - 1; if (m >= 1) { _selectedMonth = m; } else { _selectedYear -= 1; _selectedMonth = 12; } _loadStatistics(); }); }, icon: const Icon(Icons.chevron_left)),
                Text('${_selectedYear}年${_selectedMonth}月', style: TextStyle(fontSize: StatsShareResultPageConstants.sectionTitleFontSize)),
                IconButton(onPressed: () { setState(() { final m = _selectedMonth + 1; final now = DateTime.now(); final nextYear = m > 12 ? _selectedYear + 1 : _selectedYear; final nextMonth = m > 12 ? 1 : m; final notFuture = DateTime(nextYear, nextMonth, 1).isBefore(DateTime(now.year, now.month, 2)); if (notFuture) { _selectedYear = nextYear; _selectedMonth = nextMonth; } _loadStatistics(); }); }, icon: const Icon(Icons.chevron_right)),
              ],
            )
          else if (_periodType == 'year')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () { setState(() { _selectedYear -= 1; _loadStatistics(); }); }, icon: const Icon(Icons.chevron_left)),
                Text('${_selectedYear}年', style: TextStyle(fontSize: StatsShareResultPageConstants.sectionTitleFontSize)),
                IconButton(onPressed: () { setState(() { final now = DateTime.now(); if (_selectedYear < now.year) { _selectedYear += 1; } _loadStatistics(); }); }, icon: const Icon(Icons.chevron_right)),
              ],
            ),
        ],
      ),
    );
  }

  // 饼状图部分 - 用于显示习惯完成次数
  Widget _buildCompletionCountPieChart() {
    final completionCounts = _getMonthlyHabitCompletionCounts();
    final totalCount = completionCounts.values.fold(0, (sum, count) => sum + count);
    
    if (totalCount == 0) {
      return const Center(child: Text('本月暂无专注记录'));
    }
    
    // 创建饼图数据点
    final List<PieChartSectionData> sections = [];
    Color colorFor(String name) => sl<HabitColorRegistry>().getColor(name, fallback: Theme.of(context).colorScheme.primary);
    
    for (final entry in completionCounts.entries) {
      if (entry.value > 0) {
        final percentage = (entry.value / totalCount) * 100;
        sections.add(
          PieChartSectionData(
            color: colorFor(entry.key),
            value: entry.value.toDouble(),
            title: '${percentage.toStringAsFixed(0)}%',
            radius: StatsShareResultPageConstants.pieChartRadius,
            titleStyle: TextStyle(fontSize: StatsShareResultPageConstants.pieChartTitleFontSize, fontWeight: FontWeight.bold),
          )
        );
      }
    }
    
    // 创建图例
    final List<Widget> legendItems = [];
    for (final entry in completionCounts.entries) {
      if (entry.value > 0) {
        legendItems.add(
          Padding(
            padding: StatsShareResultPageConstants.pieChartTitlePadding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children:
                  [
                    Container(
                      width: StatsShareResultPageConstants.pieChartLegendIconSize,
                      height: StatsShareResultPageConstants.pieChartLegendIconSize,
                      color: colorFor(entry.key),
                    ),
                    SizedBox(width: StatsShareResultPageConstants.pieChartLegendIconSpacing),
                    Text(
                      '${entry.key}: ${entry.value}次',
                      style: TextStyle(fontSize: StatsShareResultPageConstants.pieChartLegendFontSize),
                    ),
                ],
            ),
          ),
        );
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
                  height: StatsShareResultPageConstants.pieChartHeight,
                  child: PieChart(
                  PieChartData(
                    sections: sections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final isTouched = index == touchedIndex;
                      // 增加缩放效果的差异，使变化更明显
                      final radius = isTouched ? StatsShareResultPageConstants.activePieChartRadius : StatsShareResultPageConstants.pieChartRadius;
                        
                      return PieChartSectionData(
                        color: data.color,
                        value: data.value,
                        title: data.title,
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: isTouched ? StatsShareResultPageConstants.activePieChartTitleFontSize : StatsShareResultPageConstants.pieChartTitleFontSize, 
                          fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                          color: isTouched ? Colors.white : Colors.black,
                        ),
                        // 增加更明显的边框效果
                        borderSide: isTouched 
                          ? BorderSide(color: Colors.black, width: StatsShareResultPageConstants.pieChartBorderWidth) 
                          : BorderSide.none,
                      );
                    }).toList(),
                    centerSpaceRadius: StatsShareResultPageConstants.centerSpaceRadius,
                    sectionsSpace: StatsShareResultPageConstants.sectionsSpace,
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
                SizedBox(height: StatsShareResultPageConstants.pieChartPadding),
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(10)), // 增加左右内边距
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: ScreenUtil().setWidth(20), // 增加图例项之间的水平间距
                      runSpacing: ScreenUtil().setHeight(12), // 增加图例项之间的垂直间距
                      children: legendItems,
                    ),
                  ),
                ),
                // 最后显示标题（标题放在图例下面）
                SizedBox(height: ScreenUtil().setHeight(20)), // 增加图例和标题之间的间距
                Text(
                      '本月习惯完成次数分布', 
                      style: ThemeHelper.textStyleWithTheme(
                        context,
                        fontSize: StatsShareResultPageConstants.sectionTitleFontSize, 
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
    Color colorFor(String name) => sl<HabitColorRegistry>().getColor(name, fallback: Theme.of(context).colorScheme.primary);
    final totalMinutes = completionMinutes.values.fold(0, (sum, minutes) => sum + minutes);
    
    if (totalMinutes == 0) {
      return const Center(child: Text('本月暂无时间记录'));
    }
    
    // 创建饼图数据点
    final List<PieChartSectionData> sections = [];
    
    for (final entry in completionMinutes.entries) {
      if (entry.value > 0) {
        final percentage = (entry.value / totalMinutes) * 100;
        sections.add(
          PieChartSectionData(
            color: colorFor(entry.key),
            value: entry.value.toDouble(),
            title: '${percentage.toStringAsFixed(0)}%',
            radius: StatsShareResultPageConstants.pieChartRadius,
            titleStyle: TextStyle(fontSize: StatsShareResultPageConstants.pieChartTitleFontSize, fontWeight: FontWeight.bold),
          )
        );
      }
    }
    
    // 创建图例
    final List<Widget> legendItems = [];
    for (final entry in completionMinutes.entries) {
      if (entry.value > 0) {
        final hours = entry.value ~/ 60;
        final minutes = entry.value % 60;
        final timeDisplay = hours > 0 ? '$hours时$minutes分' : '$minutes分';
        
        legendItems.add(
          Padding(
            padding: StatsShareResultPageConstants.pieChartTitlePadding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children:
                  [
                    Container(
                      width: ScreenUtil().setWidth(12),
                      height: ScreenUtil().setHeight(12),
                      color: colorFor(entry.key),
                    ),
                    SizedBox(width: ScreenUtil().setWidth(6)),
                    Text(
                      '${entry.key}: $timeDisplay',
                      style: TextStyle(fontSize: ScreenUtil().setSp(16)),
                    ),
                ],
            ),
          ),
        );
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
                  height: ScreenUtil().setHeight(220), // 增加饼图高度，提供更多空间
                  child: PieChart(
                  PieChartData(
                    sections: sections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final isTouched = index == touchedIndex;
                      // 增加缩放效果的差异，使变化更明显
                      final radius = isTouched ? ScreenUtil().setWidth(100) : ScreenUtil().setWidth(80);
                        
                      return PieChartSectionData(
                        color: data.color,
                        value: data.value,
                        title: data.title,
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: isTouched ? ScreenUtil().setSp(18) : ScreenUtil().setSp(16), 
                          fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                          color: isTouched ? Colors.white : Colors.black,
                        ),
                        // 增加更明显的边框效果
                        borderSide: isTouched 
                          ? BorderSide(color: Colors.black, width: ScreenUtil().setWidth(3)) 
                          : BorderSide.none,
                      );
                    }).toList(),
                    centerSpaceRadius: ScreenUtil().setWidth(50),
                    sectionsSpace: ScreenUtil().setWidth(2),
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
                SizedBox(height: ScreenUtil().setHeight(20)), // 增加饼图和图例之间的间距
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(10)), // 增加左右内边距
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: ScreenUtil().setWidth(20), // 增加图例项之间的水平间距
                      runSpacing: ScreenUtil().setHeight(12), // 增加图例项之间的垂直间距
                      children: legendItems,
                    ),
                  ),
                ),
                // 最后显示标题（标题放在图例下面）
                SizedBox(height: ScreenUtil().setHeight(20)), // 增加图例和标题之间的间距
                Text(
                  '本月习惯完成时间分布', 
                  style: ThemeHelper.textStyleWithTheme(
                    context,
                    fontSize: ScreenUtil().setSp(20), 
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
    return ChangeNotifierProvider.value(
      value: _statisticsResultProvider,
      child: Consumer<StatisticsResultProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('月度统计报告'),
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            body: Container(
              decoration: ThemeHelper.generateBackgroundDecoration(context) ?? BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor, // 与主题颜色联动
              ),
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                      ? Center(child: Text(provider.errorMessage!))
                      : _buildContent(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    final goalCompletionData = _getHabitGoalCompletionData();

    return SingleChildScrollView(
      padding: EdgeInsets.all(ScreenUtil().setWidth(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
          [
            _buildPeriodControls(),
            // 移除了日期范围显示，因为当前只统计当前月的结果
            SizedBox(height: ScreenUtil().setHeight(10)),

            // 结果统计
            ThemeHelper.gradientText(
              context,
              '结果统计',
              style: ThemeHelper.textStyleWithTheme(
                context,
                fontSize: ScreenUtil().setSp(22),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ScreenUtil().setHeight(16)),

            // 饼状图部分（使用一个大的背景块）
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16))),
                color: Theme.of(context).cardColor,
                child: Padding(
                  // 增加顶部和底部内边距，特别是顶部内边距以避免饼图超出
                  padding: EdgeInsets.fromLTRB(
                    ScreenUtil().setWidth(16), 
                    ScreenUtil().setHeight(30), // 增大顶部内边距
                    ScreenUtil().setWidth(16), 
                    ScreenUtil().setHeight(24)  // 增大底部内边距
                  ),
                  child: Column(
                    children: 
                      [
                        // 完成次数饼状图
                        _buildCompletionCountPieChart(),
                        SizedBox(height: ScreenUtil().setHeight(60)), // 增大次数和时间统计之间的间隔
                        // 完成时间饼状图
                        _buildCompletionTimePieChart(),
                      ],
                  ),
                ),
              ),
            ),
            SizedBox(height: ScreenUtil().setHeight(30)),

            // 目标追踪
            if (goalCompletionData.isNotEmpty) ...[
              ThemeHelper.gradientText(
                context,
                '目标追踪',
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: ScreenUtil().setSp(22),
                fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ScreenUtil().setHeight(16)),
              
              // 习惯目标完成度柱状图
              SizedBox(
                width: double.infinity,
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16))),
                  child: Padding(
                    padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
                    child: _buildGoalCompletionBarChart(),
                  ),
                ),
              ),
            ],
          ],
      ),
    );
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
