import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/features/statistics/presentation/adapters/statistics_chart_adapter.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

class StatisticsChartWidget extends StatefulWidget {
  final List<Habit> habits;
  final String selectedPeriod;
  final DateTimeRange rollingRange;
  final List<bool> isHabitVisible;
  final WeekStartDay weekStartDay;

  const StatisticsChartWidget({
    super.key,
    required this.habits,
    required this.selectedPeriod,
    required this.rollingRange,
    required this.isHabitVisible,
    required this.weekStartDay,
  });

  @override
  State<StatisticsChartWidget> createState() => _StatisticsChartWidgetState();
}

class _StatisticsChartWidgetState extends State<StatisticsChartWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.habits.isEmpty) {
      return Center(
        child: Text(
          '暂无习惯数据',
          style: TextStyle(color: ThemeHelper.onBackground(context)),
        ),
      );
    }

    // 获取习惯的颜色
    final List<String> habitNames = widget.habits
        .map((habit) => habit.name)
        .toList();
    final List<Color> habitColors = widget.habits
        .map((habit) => habit.color)
        .toList();

    final chartAdapter = StatisticsChartAdapter();
    final titles = chartAdapter.generateRollingTitles(
      widget.selectedPeriod,
      endDate: widget.rollingRange.end,
    );
    final completionTitles = chartAdapter.generateCompletionRateTitles(
      widget.selectedPeriod,
      range: widget.rollingRange,
      weekStartDay: widget.weekStartDay,
    );
    final visibleHabitCount = widget.isHabitVisible
        .where((isVisible) => isVisible)
        .length;
    final visibleTimedHabitCount = widget.habits
        .asMap()
        .entries
        .where(
          (entry) => widget.isHabitVisible[entry.key] && entry.value.trackTime,
        )
        .length;
    final visibleGoalHabitCount = widget.habits
        .asMap()
        .entries
        .where(
          (entry) =>
              widget.isHabitVisible[entry.key] &&
              entry.value.targetDays != null &&
              entry.value.targetDays! > 0,
        )
        .length;

    // 为每个习惯生成次数统计数据
    final List<LineChartBarData> countData = widget.habits.asMap().entries.map((
      entry,
    ) {
      final habit = entry.value;
      final data = chartAdapter.generateRollingTrendSpots(
        habit,
        'count',
        widget.selectedPeriod,
        endDate: widget.rollingRange.end,
      );
      return _createLineChartBarData(
        data,
        habit.color,
        showArea: visibleHabitCount == 1,
      );
    }).toList();

    final List<LineChartBarData> timeData = widget.habits.asMap().entries.map((
      entry,
    ) {
      final habit = entry.value;
      final data = chartAdapter.generateRollingTrendSpots(
        habit,
        'time',
        widget.selectedPeriod,
        endDate: widget.rollingRange.end,
      );
      return _createLineChartBarData(
        data,
        habit.color,
        showArea: visibleTimedHabitCount == 1,
      );
    }).toList();

    final List<LineChartBarData> completionData = widget.habits.map((habit) {
      final data = chartAdapter.generateRollingCompletionRateSpots(
        habit,
        widget.selectedPeriod,
        range: widget.rollingRange,
        weekStartDay: widget.weekStartDay,
      );
      return _createLineChartBarData(
        data,
        habit.color,
        showArea: visibleGoalHabitCount == 1,
      );
    }).toList();

    final bool hasTrackTime = widget.habits.any((h) => h.trackTime);

    // 过滤显示的数据
    final List<LineChartBarData> filteredCountData = [];
    final List<LineChartBarData> filteredTimeData = [];
    final List<LineChartBarData> filteredCompletionData = [];
    final List<String> filteredHabitNames = [];
    final List<Color> filteredHabitColors = [];
    final List<String> filteredGoalHabitNames = [];
    final List<Color> filteredGoalHabitColors = [];
    for (int i = 0; i < widget.habits.length; i++) {
      if (widget.isHabitVisible[i]) {
        filteredCountData.add(countData[i]);
        filteredHabitNames.add(habitNames[i]);
        filteredHabitColors.add(habitColors[i]);
        if (widget.habits[i].trackTime) {
          filteredTimeData.add(timeData[i]);
        }
        if (widget.habits[i].targetDays != null &&
            widget.habits[i].targetDays! > 0) {
          filteredCompletionData.add(completionData[i]);
          filteredGoalHabitNames.add(habitNames[i]);
          filteredGoalHabitColors.add(habitColors[i]);
        }
      }
    }

    final chartHeight = (MediaQuery.sizeOf(context).height * 0.25).clamp(
      210.0,
      250.0,
    );

    return Column(
      children: [
        _buildChartPanel(
          context,
          icon: Icons.show_chart_rounded,
          accentColor: Theme.of(context).colorScheme.primary,
          title: '记录趋势',
          subtitle: '每个时间段内的记录次数',
          tooltip: '点击或悬停曲线查看具体次数',
          semanticsLabel: '习惯记录次数折线图，点击数据点查看提示',
          chartHeight: chartHeight,
          chartData: _createLineChartData(
            filteredCountData,
            titles,
            'count',
            filteredHabitNames,
            filteredHabitColors,
          ),
        ),
        if (hasTrackTime)
          _buildChartPanel(
            context,
            icon: Icons.timer_outlined,
            accentColor: Theme.of(context).colorScheme.secondary,
            title: '专注时长',
            subtitle: '每个时间段内累计的分钟数',
            tooltip: '点击或悬停曲线查看具体时长',
            semanticsLabel: '习惯专注时长折线图，点击数据点查看提示',
            chartHeight: chartHeight,
            chartData: _createLineChartData(
              filteredTimeData,
              titles,
              'time',
              filteredHabitNames,
              filteredHabitColors,
            ),
          ),
        if (filteredCompletionData.isNotEmpty)
          _buildChartPanel(
            context,
            icon: Icons.track_changes_rounded,
            accentColor: Theme.of(context).colorScheme.tertiary,
            title: '目标达成率',
            subtitle: '实际记录与阶段目标的比例',
            tooltip: '点击或悬停曲线查看具体完成率',
            semanticsLabel: '习惯目标达成率折线图，点击数据点查看提示',
            chartHeight: chartHeight,
            chartData: _createLineChartData(
              filteredCompletionData,
              completionTitles,
              'completionRate',
              filteredGoalHabitNames,
              filteredGoalHabitColors,
            ),
          ),
      ],
    );
  }

  Widget _buildChartPanel(
    BuildContext context, {
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required String tooltip,
    required String semanticsLabel,
    required double chartHeight,
    required LineChartData chartData,
  }) {
    return Container(
      margin: StatisticsChartWidgetConstants.containerMargin,
      padding: StatisticsChartWidgetConstants.containerPadding,
      decoration: ThemeHelper.panelDecoration(
        context,
        radius: StatisticsChartWidgetConstants.containerBorderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 20.sp, color: accentColor),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize:
                            StatisticsChartWidgetConstants.chartTitleFontSize,
                        fontWeight: FontWeight.w800,
                        color: ThemeHelper.onBackground(context),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypographyConstants.panelSubtitleFontSize,
                        color: ThemeHelper.onBackground(
                          context,
                        ).withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: tooltip,
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18.sp,
                  color: ThemeHelper.onBackground(
                    context,
                  ).withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
          SizedBox(height: StatisticsChartWidgetConstants.titleChartSpacing),
          if (chartData.lineBarsData.isEmpty)
            SizedBox(
              height: chartHeight,
              width: double.infinity,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_off_outlined,
                      size: 28.sp,
                      color: ThemeHelper.onBackground(
                        context,
                      ).withValues(alpha: 0.28),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '选择至少一个习惯以查看趋势',
                      style: TextStyle(
                        fontSize: AppTypographyConstants.panelSubtitleFontSize,
                        color: ThemeHelper.onBackground(
                          context,
                        ).withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: chartHeight,
              width: double.infinity,
              child: Semantics(
                label: semanticsLabel,
                child: LineChart(chartData),
              ),
            ),
        ],
      ),
    );
  }

  // 创建线条数据
  LineChartBarData _createLineChartBarData(
    List<FlSpot> spots,
    Color color, {
    required bool showArea,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.28,
      preventCurveOverShooting: true,
      preventCurveOvershootingThreshold: 1,
      color: color,
      barWidth: StatisticsChartWidgetConstants.lineWidth,
      isStrokeCapRound: true,
      isStrokeJoinRound: true,
      dotData: FlDotData(
        show: true,
        checkToShowDot: (spot, barData) =>
            spots.length <= 7 || spot.x == spots.last.x,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: spots.length <= 7 ? 1.9.r : 2.3.r,
          color: color,
          strokeWidth: 0,
          strokeColor: Colors.transparent,
        ),
      ),
      belowBarData: BarAreaData(
        show: showArea,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // 创建图表数据
  LineChartData _createLineChartData(
    List<LineChartBarData> lineBarsData,
    List<String> titles,
    String chartType,
    List<String> habitNames,
    List<Color> habitColors,
  ) {
    // 计算Y轴的最大值
    double maxY = 0;
    for (final barData in lineBarsData) {
      for (final spot in barData.spots) {
        if (spot.y > maxY) {
          maxY = spot.y;
        }
      }
    }

    late final double leftInterval;
    if (chartType == 'completionRate') {
      maxY = 100;
      leftInterval = 25;
    } else {
      maxY = maxY == 0 ? (chartType == 'count' ? 4 : 60) : maxY * 1.14;
      final calculatedInterval = _niceInterval(maxY / 4);
      leftInterval = chartType == 'count'
          ? math.max(1, calculatedInterval.ceilToDouble()).toDouble()
          : calculatedInterval;
      maxY = (maxY / leftInterval).ceil() * leftInterval;
    }

    return LineChartData(
      // 启用交互功能
      lineTouchData: LineTouchData(
        enabled: true,
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> indicators) {
              return indicators.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: barData.color != null
                        ? barData.color!.withValues(alpha: 0.3)
                        : ThemeHelper.outline(context),
                    strokeWidth: ScreenUtil().setWidth(1),
                    dashArray: const [4, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, data, index) {
                      final color =
                          barData.color ??
                          Theme.of(context).colorScheme.primary;
                      return FlDotCirclePainter(
                        radius:
                            StatisticsChartWidgetConstants.dotRadiusSelected,
                        color: Theme.of(context).colorScheme.surface,
                        strokeWidth:
                            StatisticsChartWidgetConstants.dotStrokeWidth,
                        strokeColor: color,
                      );
                    },
                  ),
                );
              }).toList();
            },
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipRoundedRadius: ScreenUtil().setWidth(12),
          tooltipPadding: EdgeInsets.symmetric(
            horizontal: ScreenUtil().setWidth(10),
            vertical: ScreenUtil().setHeight(8),
          ),
          tooltipBorder: BorderSide(
            color: ThemeHelper.outline(context).withValues(alpha: 0.16),
          ),
          getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
          getTooltipItems: (touchedSpots) {
            final chartAdapter = StatisticsChartAdapter();
            return touchedSpots.map((touchedSpot) {
              final habitName = habitNames[touchedSpot.barIndex];
              final text = chartType == 'completionRate'
                  ? chartAdapter.getCompletionRateTooltipLabel(
                      touchedSpot.x.toInt(),
                      touchedSpot.y,
                      widget.selectedPeriod,
                      range: widget.rollingRange,
                      weekStartDay: widget.weekStartDay,
                    )
                  : chartAdapter.getRollingTooltipLabel(
                      chartType,
                      touchedSpot.x.toInt(),
                      touchedSpot.y,
                      widget.selectedPeriod,
                      endDate: widget.rollingRange.end,
                    );
              return LineTooltipItem(
                '$habitName  $text\n',
                TextStyle(
                  color: habitColors[touchedSpot.barIndex],
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
              );
            }).toList();
          },
          // 在0.68.0版本中，我们使用默认的tooltip样式
        ),
      ),
      // 标题配置
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: ScreenUtil().setHeight(30),
            getTitlesWidget: (value, meta) {
              if (value.toInt() < titles.length) {
                return Padding(
                  padding: EdgeInsets.only(top: ScreenUtil().setHeight(8)),
                  child: Text(
                    titles[value.toInt()],
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: ThemeHelper.onSurfaceVariant(context),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
            interval: 1,
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: ScreenUtil().setWidth(36),
            interval: leftInterval,
            getTitlesWidget: (value, meta) {
              if (value == meta.min ||
                  value == meta.max ||
                  value % leftInterval < 0.01) {
                return Text(
                  chartType == 'count'
                      ? value.toInt().toString()
                      : chartType == 'completionRate'
                      ? '${value.toInt()}%'
                      : value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: ThemeHelper.onSurfaceVariant(context),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: leftInterval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: ThemeHelper.outline(context).withValues(alpha: 0.1),
          strokeWidth: ScreenUtil().setWidth(1),
        ),
      ),
      borderData: FlBorderData(show: false),
      clipData: const FlClipData(
        top: true,
        bottom: true,
        left: true,
        right: true,
      ),
      // 限制范围
      minX: 0,
      maxX: (titles.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      // 线条数据
      lineBarsData: lineBarsData,
    );
  }

  double _niceInterval(double value) {
    if (!value.isFinite || value <= 0) {
      return 1;
    }
    final exponent = (math.log(value) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final fraction = value / magnitude;
    final double niceFraction;
    if (fraction <= 1) {
      niceFraction = 1;
    } else if (fraction <= 2) {
      niceFraction = 2;
    } else if (fraction <= 2.5) {
      niceFraction = 2.5;
    } else if (fraction <= 5) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
    return niceFraction * magnitude;
  }
}
