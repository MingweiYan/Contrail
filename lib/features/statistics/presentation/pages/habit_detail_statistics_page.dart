import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/statistics/presentation/widgets/calendar_view_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/statistics/presentation/providers/habit_detail_statistics_provider.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';


// 直接使用CycleType枚举，不再需要额外的TimePeriodEnum

class HabitDetailStatisticsPage extends StatefulWidget {
  final Habit habit;

  const HabitDetailStatisticsPage({super.key, required this.habit});

  @override
  State<HabitDetailStatisticsPage> createState() => _HabitDetailStatisticsPageState();
}

class _HabitDetailStatisticsPageState extends State<HabitDetailStatisticsPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HabitDetailStatisticsProvider(widget.habit),
      child: _HabitDetailStatisticsView(habit: widget.habit),
    );
  }
}

class _HabitDetailStatisticsView extends StatelessWidget {
  final Habit habit;
  final HabitStatisticsService _statisticsService = sl<HabitStatisticsService>();
  
  _HabitDetailStatisticsView({required this.habit});

  /// 构建完成情况模块
  /// 显示当前周期内的习惯完成情况，包括饼图和详细数据
  Widget _buildCompletionStatusModule(BuildContext context) {
    final provider = Provider.of<HabitDetailStatisticsProvider>(context);
    final stats = provider.calculateHabitStats();
    final completedDays = stats['completedDays'] as int;
    final remainingDays = stats['remainingDays'] as int;
    final hasTarget = habit.targetDays != null && habit.targetDays! > 0;
    
    if (!hasTarget) return Container();
    
    return Container(
      margin: HabitDetailStatisticsPageConstants.moduleContainerMargin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HabitDetailStatisticsPageConstants.moduleContainerBorderRadius),
        boxShadow: [
          BoxShadow(
            color: ThemeHelper.outline(context).withValues(alpha: 10.0),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: HabitDetailStatisticsPageConstants.moduleContainerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.getCustomPeriodLabel()}完成情况',
                style: TextStyle(
                  fontSize: HabitDetailStatisticsPageConstants.sectionTitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.onBackground(context),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: provider.previousPeriod,
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: provider.nextPeriod,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: HabitDetailStatisticsPageConstants.titleSectionSpacing),
          Container(
            height: HabitDetailStatisticsPageConstants.chartContainerHeight,
            padding: HabitDetailStatisticsPageConstants.chartContainerPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight, // 饼图向右对齐
                    child: Padding(
                      padding: HabitDetailStatisticsPageConstants.pieChartPadding,
                      child: PieChart(
                        PieChartData(
                          sections: _statisticsService.generatePieData(completedDays, remainingDays, habit.color),
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
                    padding: EdgeInsets.only(left: HabitDetailStatisticsPageConstants.contentSpacing * 2.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: HabitDetailStatisticsPageConstants.statusIndicatorSize,
                            height: HabitDetailStatisticsPageConstants.statusIndicatorSize,
                              color: habit.color,
                            ),
                            SizedBox(width: HabitDetailStatisticsPageConstants.statusIndicatorSpacing),
                            Text('完成: $completedDays 天'),
                          ],
                        ),
                        SizedBox(height: HabitDetailStatisticsPageConstants.statusSectionSpacing),
                        Row(
                          children: [
                            Container(
                              width: HabitDetailStatisticsPageConstants.statusIndicatorSize,
                              height: HabitDetailStatisticsPageConstants.statusIndicatorSize,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(width: HabitDetailStatisticsPageConstants.statusIndicatorSpacing),
                            Text('剩余: $remainingDays 天'),
                          ],
                        ),
                        SizedBox(height: HabitDetailStatisticsPageConstants.statusSectionSpacing),
                        Text(
                          '完成率: ${(stats['completionRate'] * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: HabitDetailStatisticsPageConstants.completionRateFontSize,
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
    );
  }

  // 生成图表标题数据 - 使用服务类方法
  FlTitlesData _generateTitlesData(BuildContext context, String timeRange) {
    final titles = _statisticsService.generateTitlesData(timeRange);
        return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < titles.length) {
              return Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  titles[index],
                  style: const TextStyle(fontSize: 12),
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
            // 移除ScreenUtil的使用，直接返回简单文本
            return Text('${value.toInt()}');
          },
          reservedSize: 40,
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
  
  /// 构建习惯完成次数趋势模块
  /// 显示习惯在不同时间范围（周/月/年）内的完成次数趋势
  Widget _buildCountTrendModule(BuildContext context) {
    final provider = Provider.of<HabitDetailStatisticsProvider>(context);
    
    return Container(
      margin: HabitDetailStatisticsPageConstants.moduleContainerMargin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HabitDetailStatisticsPageConstants.moduleContainerBorderRadius),
        boxShadow: [
          BoxShadow(
            color: ThemeHelper.outline(context).withValues(alpha: 10.0),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: HabitDetailStatisticsPageConstants.moduleContainerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '习惯完成次数统计',
            style: TextStyle(
              fontSize: HabitDetailStatisticsPageConstants.sectionTitleFontSize,
              fontWeight: FontWeight.bold,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          SizedBox(height: HabitDetailStatisticsPageConstants.smallSectionSpacing),
          Container(
            height: HabitDetailStatisticsPageConstants.chartContainerHeight,
            child: LineChart(
              LineChartData(
                lineBarsData: [provider.generateCountTrendData()],
                titlesData: _generateTitlesData(context, provider.timeRange),
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
                          '${provider.getCountTooltipLabel(index, value)}',
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
    );
  }
  
  /// 构建习惯完成时间趋势模块
  /// 显示习惯在不同时间范围（周/月/年）内的完成时间趋势
  Widget _buildTimeTrendModule(BuildContext context) {
    final provider = Provider.of<HabitDetailStatisticsProvider>(context);
    
    return Container(
      margin: HabitDetailStatisticsPageConstants.moduleContainerMargin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HabitDetailStatisticsPageConstants.moduleContainerBorderRadius),
        boxShadow: [
          BoxShadow(
            color: ThemeHelper.outline(context).withValues(alpha: 10.0),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: HabitDetailStatisticsPageConstants.moduleContainerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '习惯专注时间统计 (分钟)',
            style: TextStyle(
              fontSize: HabitDetailStatisticsPageConstants.sectionTitleFontSize,
              fontWeight: FontWeight.bold,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          SizedBox(height: HabitDetailStatisticsPageConstants.smallSectionSpacing),
          Container(
            height: HabitDetailStatisticsPageConstants.chartContainerHeight,
            child: LineChart(
              LineChartData(
                lineBarsData: [provider.generateTimeTrendData()],
                titlesData: _generateTitlesData(context, provider.timeRange),
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
                          '${provider.getTimeTooltipLabel(index, value)}',
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
    );
  }
  
  /// 构建打卡日历模块
  /// 显示月度打卡记录，支持月份切换
  Widget _buildCalendarModule(BuildContext context, List<Habit> habits, Map<String, Color> habitColors) {
    final provider = Provider.of<HabitDetailStatisticsProvider>(context);
    
    return Container(
      margin: HabitDetailStatisticsPageConstants.moduleContainerMargin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HabitDetailStatisticsPageConstants.moduleContainerBorderRadius),
        boxShadow: [
          BoxShadow(
            color: ThemeHelper.outline(context).withValues(alpha: 10.0),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: HabitDetailStatisticsPageConstants.moduleContainerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.selectedYear}年${provider.selectedMonth}月专注记录',
                style: TextStyle(
                  fontSize: HabitDetailStatisticsPageConstants.sectionTitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.onBackground(context),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: provider.previousMonth,
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: provider.nextMonth,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: HabitDetailStatisticsPageConstants.titleSectionSpacing),
          Container(
            height: HabitDetailStatisticsPageConstants.calendarContainerHeight,
            child: CalendarViewWidget(
              habits: habits,
              selectedYear: provider.selectedYear,
              selectedMonth: provider.selectedMonth,
              habitColors: habitColors,
              weekStartDay: Provider.of<PersonalizationProvider>(context, listen: false).weekStartDay,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 创建统一的时间范围选择器组件
  /// 包含年、月、周三个选项，用于控制次数统计和时间统计的显示范围
  Widget _buildTimeRangeSelector(BuildContext context) {
    final provider = Provider.of<HabitDetailStatisticsProvider>(context);
    
    return Container(
      margin: HabitDetailStatisticsPageConstants.moduleContainerMargin,
      padding: HabitDetailStatisticsPageConstants.moduleContainerPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HabitDetailStatisticsPageConstants.moduleContainerBorderRadius),
        boxShadow: [
          BoxShadow(
            color: ThemeHelper.outline(context).withValues(alpha: 10.0),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '时间范围',
            style: TextStyle(
              fontSize: HabitDetailStatisticsPageConstants.timeRangeTitleFontSize,
              fontWeight: FontWeight.bold,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          SizedBox(height: HabitDetailStatisticsPageConstants.titleSectionSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => provider.setTimeRange('week'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.timeRange == 'week' ? habit.color : Colors.grey,
                ),
                child: Text('周'),
              ),
              SizedBox(width: HabitDetailStatisticsPageConstants.buttonSpacing),
              ElevatedButton(
                onPressed: () => provider.setTimeRange('month'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.timeRange == 'month' ? habit.color : Colors.grey,
                ),
                child: Text('月'),
              ),
              SizedBox(width: HabitDetailStatisticsPageConstants.buttonSpacing),
              ElevatedButton(
                onPressed: () => provider.setTimeRange('year'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.timeRange == 'year' ? habit.color : Colors.grey,
                ),
                child: Text('年'),
              ),
            ],
          ),
          SizedBox(height: HabitDetailStatisticsPageConstants.titleSectionSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: provider.previousTimeRange, // 左边是上一个时间范围（减少偏移）
                color: habit.color,
              ),
              SizedBox(width: HabitDetailStatisticsPageConstants.contentSpacing),
              Text(
                provider.getTimeRangeLabel(),
                style: TextStyle(
                  fontSize: HabitDetailStatisticsPageConstants.timeRangeLabelFontSize,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.onBackground(context),
                ),
              ),
              SizedBox(width: HabitDetailStatisticsPageConstants.contentSpacing),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: provider.nextTimeRange, // 右边是下一个时间范围（增加偏移）
                color: habit.color,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // 创建只有当前习惯的列表用于日历
    final List<Habit> singleHabitList = [habit];
    
    // 创建习惯颜色映射
    final Map<String, Color> habitColors = {
      habit.name: habit.color,
    };
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${habit.name} 统计'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Container(
        decoration: ThemeHelper.generateBackgroundDecoration(context) ?? BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        padding: HabitDetailStatisticsPageConstants.bodyPadding,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 完成情况模块
              _buildCompletionStatusModule(context),
              
              // 月度完成日历
              _buildCalendarModule(context, singleHabitList, habitColors),
              
              // 统一的时间范围选择器
              _buildTimeRangeSelector(context),
              
              // 完成次数统计图表
              _buildCountTrendModule(context),
              
              // 专注时间统计图表
              _buildTimeTrendModule(context),
              
              SizedBox(height: HabitDetailStatisticsPageConstants.bottomSpacing),
            ],
          ),
        ),
      ),
    );
  }
}