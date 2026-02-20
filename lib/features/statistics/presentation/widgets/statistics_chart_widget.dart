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
  final int selectedYear;
  final int selectedMonth;
  final int selectedWeek;
  final List<bool> isHabitVisible;
  final WeekStartDay weekStartDay;

  const StatisticsChartWidget({
    super.key,
    required this.habits,
    required this.selectedPeriod,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedWeek,
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
      return const Center(child: Text('暂无习惯数据'));
    }

    // 获取习惯的颜色
    final List<String> habitNames = widget.habits
        .map((habit) => habit.name)
        .toList();
    final List<Color> habitColors = widget.habits
        .map((habit) => habit.color)
        .toList();

    final chartAdapter = StatisticsChartAdapter();
    final titles = chartAdapter.generateTitlesData(
      widget.selectedPeriod,
      selectedYear: widget.selectedYear,
      selectedMonth: widget.selectedMonth,
      selectedWeek: widget.selectedWeek,
      weekStartDay: widget.weekStartDay,
    );

    // 为每个习惯生成次数统计数据
    final List<LineChartBarData> countData = widget.habits.asMap().entries.map((
      entry,
    ) {
      final index = entry.key;
      final habit = entry.value;
      final data = chartAdapter.generateTrendSpots(
        habit,
        'count',
        widget.selectedPeriod,
        widget.selectedYear,
        widget.selectedMonth,
        widget.selectedWeek,
        widget.weekStartDay,
      );
      return _createLineChartBarData(data, habit.color, index);
    }).toList();

    final List<LineChartBarData> timeData = widget.habits.asMap().entries.map((
      entry,
    ) {
      final index = entry.key;
      final habit = entry.value;
      final data = chartAdapter.generateTrendSpots(
        habit,
        'time',
        widget.selectedPeriod,
        widget.selectedYear,
        widget.selectedMonth,
        widget.selectedWeek,
        widget.weekStartDay,
      );
      return _createLineChartBarData(data, habit.color, index);
    }).toList();

    final bool hasTrackTime = widget.habits.any((h) => h.trackTime);

    // 过滤显示的数据
    final List<LineChartBarData> filteredCountData = [];
    final List<LineChartBarData> filteredTimeData = [];
    for (int i = 0; i < widget.habits.length; i++) {
      if (widget.isHabitVisible[i]) {
        filteredCountData.add(countData[i]);
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
              // 次数统计图表 - 添加独立的白色背景块
              Container(
                margin: StatisticsChartWidgetConstants.containerMargin,
                decoration: BoxDecoration(
                  color: Colors.white, // 使用纯白色背景
                  borderRadius: BorderRadius.circular(
                    StatisticsChartWidgetConstants.containerBorderRadius,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: StatisticsChartWidgetConstants.containerPadding,
                child: Column(
                  children: [
                    SizedBox(
                      height: chartHeight,
                      width: double.infinity,
                      child: Semantics(
                        label: '习惯完成次数统计折线图，点击数据点查看提示',
                        child: LineChart(
                          _createLineChartData(
                            filteredCountData.isEmpty
                                ? countData
                                : filteredCountData,
                            titles,
                            'count',
                            habitNames,
                            habitColors,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: ScreenUtil().setHeight(6)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: ScreenUtil().setSp(14),
                            color: ThemeHelper.onBackground(
                              context,
                            ).withOpacity(0.7),
                          ),
                          SizedBox(width: ScreenUtil().setWidth(6)),
                          Text(
                            '提示：点击数据点查看详细值',
                            style: TextStyle(
                              fontSize: ScreenUtil().setSp(12),
                              color: ThemeHelper.onBackground(
                                context,
                              ).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 次数统计标题
              Padding(
                padding: StatisticsChartWidgetConstants.titlePadding,
                child: Text(
                  '习惯完成次数统计',
                  style: TextStyle(
                    fontSize: StatisticsChartWidgetConstants.chartTitleFontSize,
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.onBackground(context),
                  ),
                ),
              ),

              if (hasTrackTime)
                Container(
                  margin: StatisticsChartWidgetConstants.containerMargin,
                  decoration: BoxDecoration(
                    color: Colors.white, // 使用纯白色背景
                    borderRadius: BorderRadius.circular(
                      StatisticsChartWidgetConstants.containerBorderRadius,
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
                  padding: StatisticsChartWidgetConstants.containerPadding,
                  child: Column(
                    children: [
                      SizedBox(
                        height: chartHeight,
                        width: double.infinity,
                        child: Semantics(
                          label: '习惯专注时间统计折线图，点击数据点查看提示',
                          child: LineChart(
                            _createLineChartData(
                              filteredTimeData.isEmpty ? [] : filteredTimeData,
                              titles,
                              'time',
                              habitNames,
                              habitColors,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: ScreenUtil().setHeight(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: ScreenUtil().setSp(14),
                              color: ThemeHelper.onBackground(
                                context,
                              ).withOpacity(0.7),
                            ),
                            SizedBox(width: ScreenUtil().setWidth(6)),
                            Text(
                              '提示：点击数据点查看详细值',
                              style: TextStyle(
                                fontSize: ScreenUtil().setSp(12),
                                color: ThemeHelper.onBackground(
                                  context,
                                ).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (hasTrackTime)
                Padding(
                  padding: StatisticsChartWidgetConstants.titlePadding,
                  child: Text(
                    '习惯专注时间统计 (分钟)',
                    style: TextStyle(
                      fontSize:
                          StatisticsChartWidgetConstants.chartTitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: ThemeHelper.onBackground(context),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
                ? color.withOpacity(1.0)
                : color.withOpacity(0.8),
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
        color: color.withOpacity(0.1), // 半透明背景色
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
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

    maxY = maxY == 0 ? 10 : maxY * 1.1;

    // 向上取整到整数，以获得更规整的坐标上限
    maxY = maxY.ceil().toDouble();

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
                        ? barData.color!.withOpacity(0.3)
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
              final text = chartAdapter.getTooltipLabel(
                chartType,
                touchedSpot.x.toInt(),
                touchedSpot.y,
                widget.selectedPeriod,
                selectedYear: widget.selectedYear,
                selectedMonth: widget.selectedMonth,
                selectedWeek: widget.selectedWeek,
                weekStartDay: widget.weekStartDay,
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
                      fontSize: ScreenUtil().setSp(16),
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
            interval: chartType == 'count' ? 1 : maxY / 5,
            getTitlesWidget: (value, meta) {
              if (value == meta.min ||
                  value == meta.max ||
                  value % (chartType == 'count' ? 1 : maxY / 5) < 0.01) {
                return Text(
                  chartType == 'count'
                      ? value.toInt().toString()
                      : value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaleFactor * 12,
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
        horizontalInterval: chartType == 'count' ? 1 : maxY / 5,
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
