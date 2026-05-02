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
  // 存储当前选中的数据点信息
  FlSpot? touchedSpot;
  // 存储当前选中的线条索引
  int? touchedBarIndex;

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

    // 为每个习惯生成次数统计数据
    final List<LineChartBarData> countData = widget.habits.asMap().entries.map((
      entry,
    ) {
      final index = entry.key;
      final habit = entry.value;
      final data = chartAdapter.generateRollingTrendSpots(
        habit,
        'count',
        widget.selectedPeriod,
        endDate: widget.rollingRange.end,
      );
      return _createLineChartBarData(data, habit.color, index);
    }).toList();

    final List<LineChartBarData> timeData = widget.habits.asMap().entries.map((
      entry,
    ) {
      final index = entry.key;
      final habit = entry.value;
      final data = chartAdapter.generateRollingTrendSpots(
        habit,
        'time',
        widget.selectedPeriod,
        endDate: widget.rollingRange.end,
      );
      return _createLineChartBarData(data, habit.color, index);
    }).toList();

    final List<LineChartBarData> completionData = widget.habits.asMap().entries.map((
      entry,
    ) {
      final index = entry.key;
      final habit = entry.value;
      final data = chartAdapter.generateRollingCompletionRateSpots(
        habit,
        widget.selectedPeriod,
        range: widget.rollingRange,
        weekStartDay: widget.weekStartDay,
      );
      return _createLineChartBarData(data, habit.color, index);
    }).toList();

    final bool hasTrackTime = widget.habits.any((h) => h.trackTime);

    // 过滤显示的数据
    final List<LineChartBarData> filteredCountData = [];
    final List<LineChartBarData> filteredTimeData = [];
    final List<LineChartBarData> filteredCompletionData = [];
    final List<String> filteredHabitNames = [];
    final List<Color> filteredHabitColors = [];
    for (int i = 0; i < widget.habits.length; i++) {
      if (widget.isHabitVisible[i]) {
        filteredCountData.add(countData[i]);
        filteredCompletionData.add(completionData[i]);
        filteredHabitNames.add(habitNames[i]);
        filteredHabitColors.add(habitColors[i]);
        if (widget.habits[i].trackTime) {
          filteredTimeData.add(timeData[i]);
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算图表高度，根据屏幕高度的一定比例
        final screenHeight = MediaQuery.of(context).size.height;
        final chartHeight = screenHeight * 0.25; // 图表高度为屏幕高度的25%

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildChartPanel(
                context,
                title: '习惯完成次数统计',
                helperText: '提示：点击数据点查看详细值',
                semanticsLabel: '习惯完成次数统计折线图，点击数据点查看提示',
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
                  title: '习惯专注时间统计 (分钟)',
                  helperText: '提示：点击数据点查看详细值',
                  semanticsLabel: '习惯专注时间统计折线图，点击数据点查看提示',
                  chartHeight: chartHeight,
                  chartData: _createLineChartData(
                    filteredTimeData,
                    titles,
                    'time',
                    filteredHabitNames,
                    filteredHabitColors,
                  ),
                ),
              _buildChartPanel(
                context,
                title: '习惯完成率趋势',
                helperText: '提示：点击数据点查看完成率',
                semanticsLabel: '习惯完成率趋势折线图，点击数据点查看提示',
                chartHeight: chartHeight,
                chartData: _createLineChartData(
                  filteredCompletionData,
                  completionTitles,
                  'completionRate',
                  filteredHabitNames,
                  filteredHabitColors,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartPanel(
    BuildContext context, {
    required String title,
    required String helperText,
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
          Text(
            title,
            style: TextStyle(
              fontSize: StatisticsChartWidgetConstants.chartTitleFontSize,
              fontWeight: FontWeight.w800,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          SizedBox(height: StatisticsChartWidgetConstants.titleChartSpacing),
          if (chartData.lineBarsData.isEmpty)
            SizedBox(
              height: chartHeight,
              width: double.infinity,
              child: Center(
                child: Text(
                  '当前没有选中的习惯',
                  style: TextStyle(
                    fontSize: AppTypographyConstants.panelSubtitleFontSize,
                    color: ThemeHelper.onBackground(
                      context,
                    ).withValues(alpha: 0.6),
                  ),
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
          Padding(
            padding: EdgeInsets.only(
              top: StatisticsChartWidgetConstants.helperTopSpacing,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: StatisticsChartWidgetConstants.helperIconSize,
                  color: ThemeHelper.onBackground(context).withValues(alpha: 0.7),
                ),
                SizedBox(
                  width: StatisticsChartWidgetConstants.helperIconTextSpacing,
                ),
                Text(
                  helperText,
                  style: TextStyle(
                    fontSize: StatisticsChartWidgetConstants.helperFontSize,
                    color: ThemeHelper.onBackground(
                      context,
                    ).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 创建线条数据
  LineChartBarData _createLineChartBarData(
    List<FlSpot> spots,
    Color color,
    int index,
  ) {
    return LineChartBarData(
      spots: spots,
      isCurved: true, // 曲线样式
      curveSmoothness: 0.3, // 降低平滑度以减少过冲
      color: color,
      barWidth: StatisticsChartWidgetConstants.lineWidth,
      isStrokeCapRound: true, // 线条两端为圆形
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          // 根据是否选中显示不同样式的点
          return FlDotCirclePainter(
            radius: touchedSpot == spot && touchedBarIndex == index
                ? StatisticsChartWidgetConstants.dotRadiusSelected
                : StatisticsChartWidgetConstants.dotRadiusNormal,
            color: touchedSpot == spot && touchedBarIndex == index
                ? color.withValues(alpha: 1)
                : color.withValues(alpha: 0.8),
            strokeWidth: touchedSpot == spot && touchedBarIndex == index
                ? StatisticsChartWidgetConstants.dotStrokeWidth
                : 0,
            strokeColor: ThemeHelper.onBackground(context),
          );
        },
      ),
      // 添加背景填充
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1), // 半透明背景色
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0),
          ],
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

    // 根据图表类型和最大值设置不同的边距策略

    if (chartType == 'completionRate') {
      maxY = 125;
    } else {
      maxY = maxY == 0 ? 10 : maxY * 1.2;

      // 向上取整到整数，以获得更规整的坐标上限
    }

    final leftInterval = chartType == 'count'
        ? 1.0
        : chartType == 'completionRate'
            ? 25.0
            : maxY / 5;

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
                        : Colors.grey.shade300,
                    strokeWidth: ScreenUtil().setWidth(2),
                  ),
                  FlDotData(show: false),
                );
              }).toList();
            },
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipRoundedRadius: ScreenUtil().setWidth(6),
          tooltipPadding: EdgeInsets.symmetric(
            horizontal: ScreenUtil().setWidth(8),
            vertical: ScreenUtil().setHeight(6),
          ),
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
                '$habitName: $text\n',
                TextStyle(color: habitColors[touchedSpot.barIndex]),
              );
            }).toList();
          },
          // 在0.68.0版本中，我们使用默认的tooltip样式
        ),
        // 设置触摸回调
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          setState(() {
            if (event is FlTapUpEvent || event is FlPanEndEvent) {
              // 触摸结束，重置选中状态
              touchedSpot = null;
              touchedBarIndex = null;
            } else if (touchResponse != null &&
                touchResponse.lineBarSpots != null &&
                touchResponse.lineBarSpots!.isNotEmpty) {
              // 触摸中，更新选中状态
              final spot = touchResponse.lineBarSpots![0];
              touchedSpot = FlSpot(spot.x, spot.y);
              touchedBarIndex = spot.barIndex;
            }
          });
        },
      ),
      // 标题配置
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: ScreenUtil().setWidth(36),
            getTitlesWidget: (value, meta) {
              if (value.toInt() < titles.length) {
                return Padding(
                  padding: EdgeInsets.only(top: ScreenUtil().setHeight(8)),
                  child: Text(
                    titles[value.toInt()],
                    style: TextStyle(
                      fontSize: AppTypographyConstants.formSectionTitleFontSize,
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
            reservedSize: ScreenUtil().setWidth(48),
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
                    fontSize: MediaQuery.textScalerOf(context).scale(12),
                    color: ThemeHelper.onSurfaceVariant(context),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      // 网格线配置 - 关闭背景虚线
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: leftInterval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: ThemeHelper.outline(context).withValues(alpha: 0.06),
          strokeWidth: ScreenUtil().setWidth(1),
        ),
      ),
      // 边框配置 - 只显示底部和左侧边框
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
            color: ThemeHelper.outline(context),
            width: ScreenUtil().setWidth(1),
          ),
          left: BorderSide(
            color: ThemeHelper.outline(context),
            width: ScreenUtil().setWidth(1),
          ),
          top: BorderSide.none,
          right: BorderSide.none,
        ),
      ),
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
}
