import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_chart_widget.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';

/// 统计趋势视图组件
/// 显示趋势图表和相关控件
class StatisticsTrendView extends StatelessWidget {
  static const double _minimumSwipeDistance = 42;
  static const double _minimumSwipeVelocity = 300;

  final List<Habit> habits;
  final List<bool> isHabitVisible;
  final StatisticsProvider statisticsProvider;

  const StatisticsTrendView({
    super.key,
    required this.habits,
    required this.isHabitVisible,
    required this.statisticsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return _buildPeriodSwipeSurface(
      key: const ValueKey('statistics-trend-period-swipe'),
      onPrevious: statisticsProvider.navigateToPreviousTimeUnit,
      onNext: statisticsProvider.canGoNextTimeUnit
          ? statisticsProvider.navigateToNextTimeUnit
          : null,
      child: Column(
        children: [_buildTrendControls(context), _buildChart(context)],
      ),
    );
  }

  Widget _buildPeriodSwipeSurface({
    required Key key,
    required Widget child,
    required VoidCallback onPrevious,
    required VoidCallback? onNext,
  }) {
    var dragDistance = 0.0;
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => dragDistance = 0,
      onHorizontalDragUpdate: (details) {
        dragDistance += details.primaryDelta ?? 0;
      },
      onHorizontalDragCancel: () => dragDistance = 0,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final gestureDelta = dragDistance.abs() >= _minimumSwipeDistance
            ? dragDistance
            : velocity.abs() >= _minimumSwipeVelocity
            ? velocity
            : 0;
        dragDistance = 0;
        if (gestureDelta > 0) {
          onPrevious();
        } else if (gestureDelta < 0) {
          onNext?.call();
        }
      },
      child: child,
    );
  }

  Widget _buildTrendControls(BuildContext context) {
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

    final String titleText = statisticsProvider.getDisplayTimeLabel();

    return _buildPanel(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: '上一个周期',
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: ThemeHelper.onBackground(context),
                ),
                onPressed: () =>
                    statisticsProvider.navigateToPreviousTimeUnit(),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTypographyConstants.sectionTitleFontSize,
                        fontWeight: FontWeight.w800,
                        color: ThemeHelper.onBackground(context),
                      ),
                    ),
                    SizedBox(height: ScreenUtil().setHeight(3)),
                    Text(
                      isRolling
                          ? '$rangeText · 持续更新'
                          : '$rangeText · $days 天窗口',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTypographyConstants.chartLegendFontSize,
                        color: ThemeHelper.onBackground(
                          context,
                        ).withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: statisticsProvider.canGoNextTimeUnit
                    ? '下一个周期'
                    : '已经是最新周期',
                icon: Icon(
                  Icons.chevron_right_rounded,
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
          SizedBox(height: ScreenUtil().setHeight(14)),
          Container(
            padding: EdgeInsets.all(ScreenUtil().setWidth(4)),
            decoration: BoxDecoration(
              color: ThemeHelper.visualTheme(context).panelSecondaryColor,
              borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16)),
              border: Border.all(
                color: ThemeHelper.visualTheme(context).panelBorderColor,
              ),
            ),
            child: Row(
              children: [
                _buildPeriodButton(
                  context,
                  '周',
                  statisticsProvider.trendSelectedPeriod == 'week',
                  () => statisticsProvider.setTrendSelectedPeriod('week'),
                ),
                _buildPeriodButton(
                  context,
                  '月',
                  statisticsProvider.trendSelectedPeriod == 'month',
                  () => statisticsProvider.setTrendSelectedPeriod('month'),
                ),
                _buildPeriodButton(
                  context,
                  '年',
                  statisticsProvider.trendSelectedPeriod == 'year',
                  () => statisticsProvider.setTrendSelectedPeriod('year'),
                ),
              ],
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

  // 创建维度切换按钮
  Widget _buildPeriodButton(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: ScreenUtil().setWidth(14),
              vertical: ScreenUtil().setHeight(10),
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: AppTypographyConstants.statisticsSegmentLabelFontSize,
                color: isSelected
                    ? ThemeHelper.onPrimary(context)
                    : ThemeHelper.onBackground(context).withValues(alpha: 0.62),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建图表
  Widget _buildChart(BuildContext context) {
    return StatisticsChartWidget(
      habits: habits,
      selectedPeriod: statisticsProvider.trendSelectedPeriod,
      rollingRange: statisticsProvider.getRollingDateRange(),
      isHabitVisible: isHabitVisible,
      weekStartDay: Provider.of<PersonalizationProvider>(
        context,
        listen: false,
      ).weekStartDay,
    );
  }
}
