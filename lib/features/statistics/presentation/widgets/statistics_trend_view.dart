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
  final Map<String, Color> habitColors;
  final List<bool> isHabitVisible;
  final List<Habit> allHabits;

  const StatisticsTrendView({
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
        // 趋势视图时间选择器（可切换周/月/年）
        _buildTimeSelector(context),
        
        // 周/月/年维度切换控件
        _buildPeriodSelector(context),
        
        // 趋势视图的图例选择部分
        _buildLegendSelector(context),
        
        // 图表组件
        _buildChart(context),
      ],
    );
  }

  // 构建时间选择器
  Widget _buildTimeSelector(BuildContext context) {
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
            onPressed: () => statisticsProvider.navigateToPreviousTimeUnit(),
            icon: Icon(
              Icons.arrow_left,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          Text(
            statisticsProvider.trendSelectedPeriod == 'week'
              ? '${statisticsProvider.trendSelectedYear}年第${statisticsProvider.trendSelectedWeek}周'
              : statisticsProvider.trendSelectedPeriod == 'month'
                ? '${statisticsProvider.trendSelectedYear}年${statisticsProvider.trendSelectedMonth}月'
                : '${statisticsProvider.trendSelectedYear}年',
            style: TextStyle(
              fontSize: ScreenUtil().setSp(20),
              fontWeight: FontWeight.bold,
              color: ThemeHelper.onBackground(context)
            ),
          ),
          IconButton(
            onPressed: () => statisticsProvider.navigateToNextTimeUnit(),
            icon: Icon(
              Icons.arrow_right,
              color: ThemeHelper.onBackground(context),
            ),
          ),
        ],
      ),
    );
  }

  // 构建维度选择器（周/月/年）
  Widget _buildPeriodSelector(BuildContext context) {
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
          _buildPeriodButton(context, '周', statisticsProvider.trendSelectedPeriod == 'week', () {
            statisticsProvider.setTrendSelectedPeriod('week');
          }),
          SizedBox(width: ScreenUtil().setWidth(16)),
          _buildPeriodButton(context, '月', statisticsProvider.trendSelectedPeriod == 'month', () {
            statisticsProvider.setTrendSelectedPeriod('month');
          }),
          SizedBox(width: ScreenUtil().setWidth(16)),
          _buildPeriodButton(context, '年', statisticsProvider.trendSelectedPeriod == 'year', () {
            statisticsProvider.setTrendSelectedPeriod('year');
          }),
        ],
      ),
    );
  }

  // 创建维度切换按钮
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

  // 构建图例选择器
  Widget _buildLegendSelector(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: ScreenUtil().setWidth(12),
              runSpacing: ScreenUtil().setHeight(8),
              children: allHabits.asMap().entries.map((entry) {
                final index = entry.key;
                final habit = entry.value;
                final isVisible = index < isHabitVisible.length && isHabitVisible[index];
                    
                return GestureDetector(
                  onTap: () {
                    statisticsProvider.toggleHabitVisibility(index);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(12), vertical: ScreenUtil().setHeight(6)),
                    decoration: BoxDecoration(
                      color: isVisible ? habit.color : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(ScreenUtil().setWidth(20)),
                      border: Border.all(
                        color: isVisible ? habit.color : Colors.grey.shade300,
                        width: ScreenUtil().setWidth(2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: ScreenUtil().setWidth(12),
                          height: ScreenUtil().setHeight(12),
                          decoration: BoxDecoration(
                            color: isVisible ? ThemeHelper.onPrimary(context) : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: ScreenUtil().setWidth(8)),
                        Text(
                          habit.name,
                          style: TextStyle(
                            color: isVisible ? ThemeHelper.onPrimary(context) : Colors.grey.shade600,
                            fontSize: ScreenUtil().setSp(18),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // 确保容器宽度充足，即使习惯数量较少
          allHabits.length < 3 ? Container(width: ScreenUtil().setWidth(80)) : Container(),
        ],
      ),
    );
  }

  // 构建图表
  Widget _buildChart(BuildContext context) {
    return StatisticsChartWidget(
      habits: visibleHabits,
      selectedPeriod: statisticsProvider.trendSelectedPeriod,
      selectedYear: statisticsProvider.trendSelectedYear,
      selectedMonth: statisticsProvider.trendSelectedMonth,
      selectedWeek: statisticsProvider.trendSelectedWeek,
      isHabitVisible: isHabitVisible,
      weekStartDay: Provider.of<PersonalizationProvider>(context, listen: false).weekStartDay,
    );
  }
}
