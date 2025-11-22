import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/statistics/presentation/widgets/calendar_view_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/statistics/presentation/providers/habit_detail_statistics_provider.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_chart_widget.dart';


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

  // 已不再需要自定义 TitlesData，统一由 StatisticsChartWidget 内部生成
  
  // 移除自定义次数趋势模块，统一使用 StatisticsChartWidget
  
  // 移除自定义时间趋势模块，统一使用 StatisticsChartWidget
  
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
      margin: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(16), vertical: ScreenUtil().setHeight(12)),
      padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => provider.navigateToPreviousTimeUnit(),
            icon: Icon(
              Icons.arrow_left,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          Text(
            provider.selectedPeriod == 'week'
              ? '${provider.selectedYear}年第${provider.selectedWeek}周'
              : provider.selectedPeriod == 'month'
                ? '${provider.selectedYear}年${provider.selectedMonth}月'
                : '${provider.selectedYear}年',
            style: TextStyle(
              fontSize: ScreenUtil().setSp(20),
              fontWeight: FontWeight.bold,
              color: ThemeHelper.onBackground(context)
            ),
          ),
          IconButton(
            onPressed: () => provider.navigateToNextTimeUnit(),
            icon: Icon(
              Icons.arrow_right,
              color: ThemeHelper.onBackground(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final provider = Provider.of<HabitDetailStatisticsProvider>(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(16), vertical: ScreenUtil().setHeight(12)),
      padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPeriodButton(context, '周', provider.selectedPeriod == 'week', () {
            provider.setSelectedPeriod('week');
          }),
          SizedBox(width: ScreenUtil().setWidth(16)),
          _buildPeriodButton(context, '月', provider.selectedPeriod == 'month', () {
            provider.setSelectedPeriod('month');
          }),
          SizedBox(width: ScreenUtil().setWidth(16)),
          _buildPeriodButton(context, '年', provider.selectedPeriod == 'year', () {
            provider.setSelectedPeriod('year');
          }),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(BuildContext context, String label, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
        foregroundColor: isSelected ? ThemeHelper.onPrimary(context) : ThemeHelper.onBackground(context),
        padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(20), vertical: ScreenUtil().setHeight(12)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ScreenUtil().setWidth(24)),
        ),
        elevation: isSelected ? 3 : 1,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: ScreenUtil().setSp(20),
        ),
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
              
              _buildTimeRangeSelector(context),
              _buildPeriodSelector(context),
              
              // 统一图表组件（次数+时间），与趋势视图完全一致
              Container(
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
                child: StatisticsChartWidget(
                  habits: [habit],
                  selectedPeriod: Provider.of<HabitDetailStatisticsProvider>(context, listen: false).selectedPeriod,
                  selectedYear: Provider.of<HabitDetailStatisticsProvider>(context, listen: false).selectedYear,
                  selectedMonth: Provider.of<HabitDetailStatisticsProvider>(context, listen: false).selectedMonth,
                  selectedWeek: Provider.of<HabitDetailStatisticsProvider>(context, listen: false).selectedWeek,
                  isHabitVisible: const [true],
                  weekStartDay: Provider.of<PersonalizationProvider>(context, listen: false).weekStartDay,
                ),
              ),
              
              SizedBox(height: HabitDetailStatisticsPageConstants.bottomSpacing),
            ],
          ),
        ),
      ),
    );
  }
}
