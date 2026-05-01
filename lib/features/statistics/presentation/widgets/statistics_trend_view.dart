import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_chart_widget.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';

/// 统计趋势视图组件
/// 显示趋势图表和相关控件
class StatisticsTrendView extends StatelessWidget {
  final List<Habit> visibleHabits;
  final StatisticsProvider statisticsProvider;

  const StatisticsTrendView({
    super.key,
    required this.visibleHabits,
    required this.statisticsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 趋势视图时间选择器（可切换周/月/年）
        _buildTimeSelector(context),

        // 周/月/年维度切换控件
        _buildPeriodSelector(context),

        // 图表组件
        _buildChart(context),
      ],
    );
  }

  // 构建时间范围说明（自然周期标题 + 起止日期 + 左右翻页）
  Widget _buildTimeSelector(BuildContext context) {
    final period = statisticsProvider.trendSelectedPeriod;
    final isRolling = statisticsProvider.isRollingWindow;
    final int days = period == 'week'
        ? 7
        : period == 'month'
            ? 30
            : 365;
    final range = statisticsProvider.getRollingDateRange();
    final start = range.start;
    final end = range.end;
    final String rangeText = period == 'year'
        ? '${start.year}/${start.month}/${start.day} – ${end.year}/${end.month}/${end.day}'
        : '${start.month}/${start.day} – ${end.month}/${end.day}';

    // 标题：自然周期显示具体时间，滚动窗口显示"最近 N"
    final String titleText = statisticsProvider.getDisplayTimeLabel();

    return _buildPanel(
      context,
      secondary: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: ThemeHelper.onBackground(context),
                ),
                onPressed: () => statisticsProvider.navigateToPreviousTimeUnit(),
              ),
              Text(
                titleText,
                style: TextStyle(
                  fontSize: ScreenUtil().setSp(20),
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.onBackground(context),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: statisticsProvider.canGoNextTimeUnit
                      ? ThemeHelper.onBackground(context)
                      : ThemeHelper.onBackground(
                          context,
                        ).withValues(alpha: 0.25),
                ),
                onPressed: statisticsProvider.canGoNextTimeUnit
                    ? () => statisticsProvider.navigateToNextTimeUnit()
                    : null,
              ),
            ],
          ),
          SizedBox(height: ScreenUtil().setHeight(6)),
          Text(
            isRolling ? rangeText : '近 $days 天数据 · $rangeText',
            style: TextStyle(
              fontSize: ScreenUtil().setSp(14),
              color: ThemeHelper.onBackground(context).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context, {
    required Widget child,
    bool secondary = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ScreenUtil().setWidth(16),
        vertical: ScreenUtil().setHeight(12),
      ),
      padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
      decoration: ThemeHelper.panelDecoration(
        context,
        secondary: secondary,
        radius: ScreenUtil().setWidth(16),
      ),
      child: child,
    );
  }


  // 构建维度选择器（周/月/年）
  Widget _buildPeriodSelector(BuildContext context) {
    return _buildPanel(
      context,
      secondary: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPeriodButton(
            context,
            '周',
            statisticsProvider.trendSelectedPeriod == 'week',
            () {
              statisticsProvider.setTrendSelectedPeriod('week');
            },
          ),
          SizedBox(width: ScreenUtil().setWidth(16)),
          _buildPeriodButton(
            context,
            '月',
            statisticsProvider.trendSelectedPeriod == 'month',
            () {
              statisticsProvider.setTrendSelectedPeriod('month');
            },
          ),
          SizedBox(width: ScreenUtil().setWidth(16)),
          _buildPeriodButton(
            context,
            '年',
            statisticsProvider.trendSelectedPeriod == 'year',
            () {
              statisticsProvider.setTrendSelectedPeriod('year');
            },
          ),
        ],
      ),
    );
  }

  // 创建维度切换按钮
  Widget _buildPeriodButton(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    final visualTheme = ThemeHelper.visualTheme(context);
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(
            horizontal: ScreenUtil().setWidth(18),
            vertical: ScreenUtil().setHeight(12),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.92)
                : visualTheme.panelColor,
            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(18)),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.86)
                  : visualTheme.panelBorderColor,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: ScreenUtil().setSp(16),
              color: isSelected
                  ? ThemeHelper.onPrimary(context)
                  : ThemeHelper.onBackground(context),
            ),
          ),
        ),
      ),
    );
  }

  // 构建图表
  Widget _buildChart(BuildContext context) {
    return StatisticsChartWidget(
      habits: visibleHabits,
      selectedPeriod: statisticsProvider.trendSelectedPeriod,
      rollingRange: statisticsProvider.getRollingDateRange(),
      isHabitVisible: List<bool>.filled(visibleHabits.length, true),
      weekStartDay: Provider.of<PersonalizationProvider>(
        context,
        listen: false,
      ).weekStartDay,
    );
  }
}
