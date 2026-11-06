import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/statistics/presentation/widgets/calendar_view_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/features/statistics/presentation/providers/habit_detail_statistics_provider.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_chart_widget.dart';
import 'package:contrail/shared/utils/habit_record_statistics.dart';

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

  const _HabitDetailStatisticsView({required this.habit});

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
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '活动日历',
          style: TextStyle(
            fontSize: HabitDetailStatisticsPageConstants.sectionTitleFontSize,
            fontWeight: FontWeight.w800,
            color: ThemeHelper.onBackground(context),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          '${provider.calendarSelectedYear}年${provider.calendarSelectedMonth}月 · 有记录的日期会被点亮',
          style: TextStyle(
            fontSize: AppTypographyConstants.panelSubtitleFontSize,
            color: ThemeHelper.onBackground(context).withValues(alpha: 0.56),
          ),
        ),
      ],
    );
    final navigation = Row(
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
    );

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
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 240) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    SizedBox(height: 10.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: navigation,
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: titleBlock),
                  SizedBox(width: 10.w),
                  navigation,
                ],
              );
            },
          ),
          SizedBox(
            height: HabitDetailStatisticsPageConstants.titleSectionSpacing,
          ),
          CalendarViewWidget(
            habits: habits,
            selectedYear: provider.calendarSelectedYear,
            selectedMonth: provider.calendarSelectedMonth,
            habitColors: habitColors,
            weekStartDay: Provider.of<PersonalizationProvider>(
              context,
              listen: false,
            ).weekStartDay,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendControls(BuildContext context) {
    final provider = Provider.of<HabitDetailStatisticsProvider>(context);
    final range = provider.getRollingDateRange();
    final rangeText =
        '${range.start.year}/${range.start.month}/${range.start.day} – '
        '${range.end.year}/${range.end.month}/${range.end.day}';

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ScreenUtil().setWidth(16),
        vertical: ScreenUtil().setHeight(12),
      ),
      padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
      decoration: ThemeHelper.panelDecoration(context, radius: 20.r),
      child: Column(
        children: [
          Row(
            children: [
              _buildCompactIconButton(
                context,
                icon: Icons.chevron_left_rounded,
                onTap: provider.navigateToPreviousTimeUnit,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      provider.getDisplayTimeLabel(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTypographyConstants.sectionTitleFontSize,
                        fontWeight: FontWeight.w800,
                        color: ThemeHelper.onBackground(context),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      rangeText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTypographyConstants.panelSubtitleFontSize,
                        color: ThemeHelper.onBackground(
                          context,
                        ).withValues(alpha: 0.54),
                      ),
                    ),
                  ],
                ),
              ),
              _buildCompactIconButton(
                context,
                icon: Icons.chevron_right_rounded,
                onTap: provider.canGoNextTimeUnit
                    ? provider.navigateToNextTimeUnit
                    : null,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: ThemeHelper.visualTheme(context).panelSecondaryColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: ThemeHelper.visualTheme(context).panelBorderColor,
              ),
            ),
            child: Row(
              children: [
                _buildPeriodButton(
                  context,
                  '周',
                  provider.selectedPeriod == 'week',
                  () => provider.setSelectedPeriod('week'),
                ),
                _buildPeriodButton(
                  context,
                  '月',
                  provider.selectedPeriod == 'month',
                  () => provider.setSelectedPeriod('month'),
                ),
                _buildPeriodButton(
                  context,
                  '年',
                  provider.selectedPeriod == 'year',
                  () => provider.setSelectedPeriod('year'),
                ),
              ],
            ),
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
      child: Semantics(
        button: true,
        selected: isSelected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize:
                        AppTypographyConstants.statisticsSegmentLabelFontSize,
                    color: isSelected
                        ? scheme.onPrimary
                        : ThemeHelper.onBackground(
                            context,
                          ).withValues(alpha: 0.62),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    if (totalMinutes < 60) {
      return '$totalMinutes 分';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes == 0 ? '$hours 时' : '$hours时$minutes分';
  }

  @override
  Widget build(BuildContext context) {
    // 创建只有当前习惯的列表用于日历
    final List<Habit> singleHabitList = [habit];

    // 创建习惯颜色映射
    final Map<String, Color> habitColors = {habit.id: habit.color};
    final provider = Provider.of<HabitDetailStatisticsProvider>(context);
    final rollingRange = provider.getRollingDateRange();
    final recordCount = HabitRecordStatistics.recordCountInRange(
      habit,
      rollingRange,
    );
    final trackedDuration = HabitRecordStatistics.durationInRange(
      habit,
      rollingRange,
    );
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    final heroSecondary = ThemeHelper.visualTheme(
      context,
    ).heroSecondaryForeground;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration:
            ThemeHelper.generateBackgroundDecoration(context) ??
            BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: HabitDetailStatisticsPageConstants.bodyPadding.copyWith(
              top: HeroHeaderPageConstants.topSpacing,
            ),
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
                                  '当前时间范围的记录次数与专注时长',
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
                              label: '记录次数',
                              value: '$recordCount 次',
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _buildHeroStat(
                              context,
                              label: '专注时长',
                              value: _formatDuration(trackedDuration),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildCalendarModule(context, singleHabitList, habitColors),
                _buildTrendControls(context),
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
          decoration: ThemeHelper.heroControlDecoration(context, radius: 16.r),
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
    final heroSecondary = ThemeHelper.visualTheme(
      context,
    ).heroSecondaryForeground;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: ThemeHelper.heroControlDecoration(context, radius: 18.r),
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
