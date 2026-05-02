import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/statistics/presentation/widgets/calendar_view_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/features/statistics/presentation/adapters/statistics_chart_adapter.dart';
import 'package:contrail/features/statistics/presentation/providers/habit_detail_statistics_provider.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_chart_widget.dart';

// 直接使用CycleType枚举，不再需要额外的TimePeriodEnum

class HabitDetailStatisticsPage extends StatefulWidget {
  final Habit habit;

  const HabitDetailStatisticsPage({super.key, required this.habit});

  @override
  State<HabitDetailStatisticsPage> createState() =>
      _HabitDetailStatisticsPageState();
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
  final StatisticsChartAdapter _chartAdapter = StatisticsChartAdapter();

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
      decoration: ThemeHelper.panelDecoration(
        context,
        radius: HabitDetailStatisticsPageConstants.moduleContainerBorderRadius,
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
                  fontSize:
                      HabitDetailStatisticsPageConstants.sectionTitleFontSize,
                  fontWeight: FontWeight.w800,
                  color: ThemeHelper.onBackground(context),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCompactIconButton(
                    context,
                    icon: Icons.chevron_left_rounded,
                    onTap: provider.previousPeriod,
                  ),
                  SizedBox(width: 8.w),
                  _buildCompactIconButton(
                    context,
                    icon: Icons.chevron_right_rounded,
                    onTap: provider.canGoNextPeriod
                        ? provider.nextPeriod
                        : null,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: HabitDetailStatisticsPageConstants.titleSectionSpacing,
          ),
          Container(
            padding: HabitDetailStatisticsPageConstants.chartContainerPadding,
            decoration: ThemeHelper.panelDecoration(
              context,
              secondary: true,
              radius: 24.r,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: HabitDetailStatisticsPageConstants.chartContainerHeight,
                    child: Padding(
                      padding:
                          HabitDetailStatisticsPageConstants.pieChartPadding,
                      child: PieChart(
                        PieChartData(
                          sections: _chartAdapter.generatePieData(
                            completedDays,
                            remainingDays,
                            habit.color,
                          ),
                          centerSpaceRadius: 40.r,
                          sectionsSpace: 0,
                          pieTouchData: PieTouchData(enabled: true),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 18.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetricRow(
                        context,
                        color: habit.color,
                        label: '完成',
                        value: '$completedDays 天',
                      ),
                      SizedBox(
                        height: HabitDetailStatisticsPageConstants
                            .statusSectionSpacing,
                      ),
                      _buildMetricRow(
                        context,
                        color: Colors.grey.shade400,
                        label: '剩余',
                        value: '$remainingDays 天',
                      ),
                      SizedBox(
                        height: HabitDetailStatisticsPageConstants
                            .statusSectionSpacing,
                      ),
                      Text(
                        '完成率: ${(stats['completionRate'] * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: HabitDetailStatisticsPageConstants
                              .completionRateFontSize,
                          fontWeight: FontWeight.w800,
                          color: ThemeHelper.onBackground(context),
                        ),
                      ),
                    ],
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
  Widget _buildCalendarModule(
    BuildContext context,
    List<Habit> habits,
    Map<String, Color> habitColors,
  ) {
    final provider = Provider.of<HabitDetailStatisticsProvider>(context);

    return Container(
      margin: HabitDetailStatisticsPageConstants.moduleContainerMargin,
      decoration: ThemeHelper.panelDecoration(
        context,
        radius: HabitDetailStatisticsPageConstants.moduleContainerBorderRadius,
      ),
      padding: HabitDetailStatisticsPageConstants.moduleContainerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.calendarSelectedYear}年${provider.calendarSelectedMonth}月专注记录',
                style: TextStyle(
                  fontSize:
                      HabitDetailStatisticsPageConstants.sectionTitleFontSize,
                  fontWeight: FontWeight.w800,
                  color: ThemeHelper.onBackground(context),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCompactIconButton(
                    context,
                    icon: Icons.chevron_left_rounded,
                    onTap: provider.previousCalendarMonth,
                  ),
                  SizedBox(width: 8.w),
                  _buildCompactIconButton(
                    context,
                    icon: Icons.chevron_right_rounded,
                    onTap: provider.nextCalendarMonth,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: HabitDetailStatisticsPageConstants.titleSectionSpacing,
          ),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: ThemeHelper.panelDecoration(
              context,
              secondary: true,
              radius: 24.r,
            ),
            child: CalendarViewWidget(
              habits: habits,
              selectedYear: provider.calendarSelectedYear,
              selectedMonth: provider.calendarSelectedMonth,
              habitColors: habitColors,
              weekStartDay: Provider.of<PersonalizationProvider>(
                context,
                listen: false,
              ).weekStartDay,
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
      margin: EdgeInsets.symmetric(
        horizontal: ScreenUtil().setWidth(16),
        vertical: ScreenUtil().setHeight(12),
      ),
      padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
      decoration: ThemeHelper.panelDecoration(context, radius: 20.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCompactIconButton(
            context,
            icon: Icons.arrow_left_rounded,
            onTap: provider.navigateToPreviousTimeUnit,
          ),
          Expanded(
            child: Text(
              provider.getDisplayTimeLabel(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypographyConstants.sectionTitleFontSize,
                fontWeight: FontWeight.w800,
                color: ThemeHelper.onBackground(context),
              ),
            ),
          ),
          _buildCompactIconButton(
            context,
            icon: Icons.arrow_right_rounded,
            onTap: provider.canGoNextTimeUnit
                ? provider.navigateToNextTimeUnit
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final provider = Provider.of<HabitDetailStatisticsProvider>(context);
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ScreenUtil().setWidth(16),
        vertical: ScreenUtil().setHeight(12),
      ),
      padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
      decoration: ThemeHelper.panelDecoration(context, radius: 20.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPeriodButton(
            context,
            '周',
            provider.selectedPeriod == 'week',
            () {
              provider.setSelectedPeriod('week');
            },
          ),
          SizedBox(width: ScreenUtil().setWidth(16)),
          _buildPeriodButton(
            context,
            '月',
            provider.selectedPeriod == 'month',
            () {
              provider.setSelectedPeriod('month');
            },
          ),
          SizedBox(width: ScreenUtil().setWidth(16)),
          _buildPeriodButton(
            context,
            '年',
            provider.selectedPeriod == 'year',
            () {
              provider.setSelectedPeriod('year');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(ScreenUtil().setWidth(24)),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: ScreenUtil().setWidth(20),
              vertical: ScreenUtil().setHeight(12),
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.16)
                  : ThemeHelper.visualTheme(context).panelSecondaryColor,
              borderRadius: BorderRadius.circular(ScreenUtil().setWidth(24)),
              border: Border.all(
                color: isSelected
                    ? scheme.primary.withValues(alpha: 0.45)
                    : ThemeHelper.visualTheme(context).panelBorderColor,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: AppTypographyConstants.panelTitleFontSize,
                  color: isSelected
                      ? scheme.primary
                      : ThemeHelper.onBackground(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 创建只有当前习惯的列表用于日历
    final List<Habit> singleHabitList = [habit];

    // 创建习惯颜色映射
    final Map<String, Color> habitColors = {habit.name: habit.color};
    final provider = Provider.of<HabitDetailStatisticsProvider>(context);
    final stats = provider.calculateHabitStats();
    final completedDays = stats['completedDays'] as int;
    final completionRate = (stats['completionRate'] as double) * 100;
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    final heroSecondary = ThemeHelper.visualTheme(context).heroSecondaryForeground;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration:
            ThemeHelper.generateBackgroundDecoration(context) ??
            BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: SingleChildScrollView(
          padding: HabitDetailStatisticsPageConstants.bodyPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: ThemeHelper.heroDecoration(context, radius: 28.r),
                padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildTopAction(
                          context,
                          icon: Icons.arrow_back_rounded,
                          label: '返回',
                          onTap: () => Navigator.pop(context),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppTypographyConstants
                                      .secondaryHeroTitleFontSize,
                                  fontWeight: FontWeight.w800,
                                  color: heroForeground,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                '习惯详情统计面板',
                                style: TextStyle(
                                  fontSize: AppTypographyConstants
                                      .secondaryHeroSubtitleFontSize,
                                  color: heroSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 14.w,
                          height: 14.w,
                          decoration: BoxDecoration(
                            color: habit.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeroStat(
                            context,
                            label: '已完成',
                            value: '$completedDays 天',
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildHeroStat(
                            context,
                            label: '完成率',
                            value: '${completionRate.toStringAsFixed(1)}%',
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildHeroStat(
                            context,
                            label: '目标',
                            value: '${habit.targetDays ?? 0} 天',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCompletionStatusModule(context),
              _buildCalendarModule(context, singleHabitList, habitColors),
              _buildTimeRangeSelector(context),
              _buildPeriodSelector(context),
              StatisticsChartWidget(
                habits: [habit],
                selectedPeriod: provider.selectedPeriod,
                rollingRange: provider.getRollingDateRange(),
                isHabitVisible: const [true],
                weekStartDay: Provider.of<PersonalizationProvider>(
                  context,
                  listen: false,
                ).weekStartDay,
              ),
              SizedBox(
                height: HabitDetailStatisticsPageConstants.bottomSpacing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: ThemeHelper.visualTheme(context).panelSecondaryColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isEnabled
                  ? ThemeHelper.visualTheme(context).panelBorderColor
                  : ThemeHelper.visualTheme(
                      context,
                    ).panelBorderColor.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            icon,
            size: 18.sp,
            color: isEnabled
                ? ThemeHelper.onBackground(context)
                : ThemeHelper.onBackground(context).withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: HabitDetailStatisticsPageConstants.statusIndicatorSize,
          height: HabitDetailStatisticsPageConstants.statusIndicatorSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(
          width: HabitDetailStatisticsPageConstants.statusIndicatorSpacing,
        ),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: AppTypographyConstants.chartLegendFontSize,
            fontWeight: FontWeight.w600,
            color: ThemeHelper.onBackground(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTopAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18.sp, color: heroForeground),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypographyConstants.secondaryHeroButtonFontSize,
                  fontWeight: FontWeight.w700,
                  color: heroForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStat(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    final heroSecondary = ThemeHelper.visualTheme(context).heroSecondaryForeground;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypographyConstants.chartStatLabelFontSize,
              fontWeight: FontWeight.w600,
              color: heroSecondary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypographyConstants.chartStatValueFontSize,
              fontWeight: FontWeight.w800,
              color: heroForeground,
            ),
          ),
        ],
      ),
    );
  }
}
