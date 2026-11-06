import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:contrail/features/statistics/presentation/widgets/calendar_view_widget.dart';
import 'package:contrail/features/statistics/presentation/widgets/timeline_view_widget.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

/// 统计明细视图组件
/// 显示日历视图和时间轴视图
class StatisticsDetailView extends StatelessWidget {
  static const double _minimumSwipeDistance = 42;
  static const double _minimumSwipeVelocity = 300;

  final List<Habit> visibleHabits;
  final StatisticsProvider statisticsProvider;
  final Map<String, Color> habitColors;

  const StatisticsDetailView({
    super.key,
    required this.visibleHabits,
    required this.statisticsProvider,
    required this.habitColors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [_buildDetailContent(context)]);
  }

  Widget _buildMonthNavigator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: ThemeHelper.visualTheme(context).panelSecondaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ThemeHelper.visualTheme(context).panelBorderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '上个月',
            visualDensity: VisualDensity.compact,
            onPressed: statisticsProvider.navigateToDetailPreviousMonth,
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '${statisticsProvider.detailSelectedYear}年${statisticsProvider.detailSelectedMonth}月',
            style: TextStyle(
              fontSize: StatisticsDetailViewConstants.subtitleFontSize,
              fontWeight: FontWeight.w800,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          IconButton(
            tooltip: '下个月',
            visualDensity: VisualDensity.compact,
            onPressed: statisticsProvider.navigateToDetailNextMonth,
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // 构建明细内容（日历和时间轴）
  Widget _buildDetailContent(BuildContext context) {
    return Column(
      children: [
        // 日历视图 - 独立的白色块
        _buildPeriodSwipeSurface(
          key: const ValueKey('statistics-calendar-period-swipe'),
          onPrevious: statisticsProvider.navigateToDetailPreviousMonth,
          onNext: statisticsProvider.navigateToDetailNextMonth,
          child: _buildPanel(
            context,
            margin: StatisticsDetailViewConstants.containerMargin,
            padding: StatisticsDetailViewConstants.containerPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '活动日历',
                            style: TextStyle(
                              fontSize:
                                  StatisticsDetailViewConstants.titleFontSize,
                              fontWeight: FontWeight.w800,
                              color: ThemeHelper.onBackground(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '颜色越丰富，表示当天记录的习惯越多',
                            style: TextStyle(
                              fontSize:
                                  AppTypographyConstants.panelSubtitleFontSize,
                              color: ThemeHelper.onBackground(
                                context,
                              ).withValues(alpha: 0.56),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildMonthNavigator(context),
                  ],
                ),
                SizedBox(height: StatisticsDetailViewConstants.titleSpacing),
                CalendarViewWidget(
                  habits: visibleHabits,
                  selectedYear: statisticsProvider.detailSelectedYear,
                  selectedMonth: statisticsProvider.detailSelectedMonth,
                  habitColors: habitColors,
                  weekStartDay: Provider.of<PersonalizationProvider>(
                    context,
                    listen: false,
                  ).weekStartDay,
                ),
              ],
            ),
          ),
        ),
        // 时间轴视图 - 独立的白色块
        _buildPanel(
          context,
          margin: StatisticsDetailViewConstants.containerMargin,
          padding: StatisticsDetailViewConstants.containerPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '活动时间轴',
                    style: TextStyle(
                      fontSize: StatisticsDetailViewConstants.titleFontSize,
                      fontWeight: FontWeight.w800,
                      color: ThemeHelper.onBackground(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '从选中月份开始，向下滚动会继续加载更早的专注记录',
                    style: TextStyle(
                      fontSize: AppTypographyConstants.panelSubtitleFontSize,
                      color: ThemeHelper.onBackground(
                        context,
                      ).withValues(alpha: 0.56),
                    ),
                  ),
                ],
              ),
              SizedBox(height: StatisticsDetailViewConstants.titleSpacing),
              TimelineViewWidget(
                habits: visibleHabits,
                selectedYear: statisticsProvider.detailSelectedYear,
                selectedMonth: statisticsProvider.detailSelectedMonth,
              ),
            ],
          ),
        ),
        // 添加底部内边距，确保内容不会贴在底部
        SizedBox(height: StatisticsDetailViewConstants.bottomSpacing),
      ],
    );
  }

  Widget _buildPeriodSwipeSurface({
    required Key key,
    required Widget child,
    required VoidCallback onPrevious,
    required VoidCallback onNext,
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
          onNext();
        }
      },
      child: child,
    );
  }

  Widget _buildPanel(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    bool secondary = false,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: ThemeHelper.panelDecoration(
        context,
        secondary: secondary,
        radius: StatisticsDetailViewConstants.containerBorderRadius,
      ),
      child: child,
    );
  }
}
