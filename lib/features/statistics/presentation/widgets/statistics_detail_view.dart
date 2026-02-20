import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final List<bool> isHabitVisible;
  final List<Habit> allHabits;

  const StatisticsDetailView({
    super.key,
    required this.visibleHabits,
    required this.statisticsProvider,
    required this.habitColors,
    required this.isHabitVisible,
    required this.allHabits,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 明细视图时间选择器（固定为月份选择）
        _buildMonthSelector(context),

        // 明细视图的图例选择部分
        _buildLegendSelector(context),

        // 主体内容：日历视图和时间轴视图
        _buildDetailContent(context),
      ],
    );
  }

  // 构建月份选择器
  Widget _buildMonthSelector(BuildContext context) {
    return Container(
      margin: StatisticsDetailViewConstants.containerMargin,
      padding: StatisticsDetailViewConstants.containerPadding,
      decoration: BoxDecoration(
        color: Colors.white, // 与其他卡片保持一致的背景色
        borderRadius: BorderRadius.circular(
          StatisticsDetailViewConstants.containerBorderRadius,
        ),
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

  // 构建图例选择器
  Widget _buildLegendSelector(BuildContext context) {
    return Container(
      margin: StatisticsDetailViewConstants.containerMargin,
      padding: StatisticsDetailViewConstants.containerPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          StatisticsDetailViewConstants.containerBorderRadius,
        ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: StatisticsDetailViewConstants.legendItemSpacing,
              runSpacing: StatisticsDetailViewConstants.legendRunSpacing,
              children: allHabits.asMap().entries.map((entry) {
                final index = entry.key;
                final habit = entry.value;
                final isVisible =
                    index < isHabitVisible.length && isHabitVisible[index];

                return Semantics(
                  label: '切换显示: ${habit.name}',
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      statisticsProvider.toggleHabitVisibility(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.symmetric(
                        horizontal: ScreenUtil().setWidth(12),
                        vertical: ScreenUtil().setHeight(6),
                      ),
                      decoration: BoxDecoration(
                        color: isVisible ? habit.color : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(
                          ScreenUtil().setWidth(20),
                        ),
                        border: Border.all(
                          color: isVisible ? habit.color : Colors.grey.shade300,
                          width: ScreenUtil().setWidth(2),
                        ),
                        boxShadow: isVisible
                            ? [
                                BoxShadow(
                                  color: habit.color.withOpacity(0.25),
                                  spreadRadius: 2,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      constraints: BoxConstraints(
                        minHeight: ScreenUtil().setWidth(40),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: ScreenUtil().setWidth(12),
                            height: ScreenUtil().setHeight(12),
                            decoration: BoxDecoration(
                              color: isVisible
                                  ? ThemeHelper.onPrimary(context)
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: ScreenUtil().setWidth(8)),
                          Text(
                            habit.name,
                            style: TextStyle(
                              color: isVisible
                                  ? ThemeHelper.onPrimary(context)
                                  : ThemeHelper.onBackground(
                                      context,
                                    ).withOpacity(0.8),
                              fontSize:
                                  StatisticsDetailViewConstants.legendFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // 确保容器宽度充足，即使习惯数量较少
          allHabits.length < 3
              ? Container(width: ScreenUtil().setWidth(80))
              : Container(),
        ],
      ),
    );
  }

  // 构建明细内容（日历和时间轴）
  Widget _buildDetailContent(BuildContext context) {
    return Column(
      children: [
        // 日历视图 - 独立的白色块
        Container(
          margin: StatisticsDetailViewConstants.containerMargin,
          decoration: BoxDecoration(
            color: Colors.white, // 使用纯白色背景
            borderRadius: BorderRadius.circular(
              StatisticsDetailViewConstants.containerBorderRadius,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
        Container(
          margin: StatisticsDetailViewConstants.containerMargin,
          decoration: BoxDecoration(
            color: Colors.white, // 使用纯白色背景
            borderRadius: BorderRadius.circular(
              StatisticsDetailViewConstants.containerBorderRadius,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
}
