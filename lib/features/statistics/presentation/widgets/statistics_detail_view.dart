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
    return Column(
      children: [
        // 明细视图时间选择器（固定为月份选择）
        _buildMonthSelector(context),

        // 主体内容：日历视图和时间轴视图
        _buildDetailContent(context),
      ],
    );
  }

  // 构建月份选择器
  Widget _buildMonthSelector(BuildContext context) {
    return _buildPanel(
      context,
      secondary: true,
      margin: StatisticsDetailViewConstants.containerMargin,
      padding: StatisticsDetailViewConstants.containerPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => statisticsProvider.navigateToDetailPreviousMonth(),
            icon: Icon(
              Icons.arrow_left,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          Text(
            '${statisticsProvider.detailSelectedYear}年${statisticsProvider.detailSelectedMonth}月',
            style: TextStyle(
              fontSize: StatisticsDetailViewConstants.subtitleFontSize,
              fontWeight: FontWeight.bold,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          IconButton(
            onPressed: () => statisticsProvider.navigateToDetailNextMonth(),
            icon: Icon(
              Icons.arrow_right,
              color: ThemeHelper.onBackground(context),
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
        _buildPanel(
          context,
          margin: StatisticsDetailViewConstants.containerMargin,
          padding: StatisticsDetailViewConstants.containerPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '完成日历',
                style: TextStyle(
                  fontSize: StatisticsDetailViewConstants.titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.onBackground(context),
                ),
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
        // 时间轴视图 - 独立的白色块
        _buildPanel(
          context,
          margin: StatisticsDetailViewConstants.containerMargin,
          padding: StatisticsDetailViewConstants.containerPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '活动时间轴',
                style: TextStyle(
                  fontSize: StatisticsDetailViewConstants.titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.onBackground(context),
                ),
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
