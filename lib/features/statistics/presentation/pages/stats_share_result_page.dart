import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:quill_native_bridge/quill_native_bridge.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_result_provider.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/services/habit_color_registry.dart';
import 'package:contrail/features/statistics/presentation/utils/distribution_sort.dart';
import 'package:contrail/features/statistics/presentation/utils/report_image_downloader.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

class StatsResultPage extends StatefulWidget {
  // 可选的参数，用于接收统计数据
  final Map<String, dynamic>? statisticsData;
  final String? periodType; // 'week', 'month', 'year'
  final DateTime? anchorDate;

  const StatsResultPage({
    super.key,
    this.statisticsData,
    this.periodType,
    this.anchorDate,
  });

  @override
  State<StatsResultPage> createState() => _StatsResultPageState();
}

class _StatsResultPageState extends State<StatsResultPage> {
  late final StatisticsResultProvider _statisticsResultProvider;
  late final HabitStatisticsService _statisticsService;
  final GlobalKey _reportHeaderBoundaryKey = GlobalKey();
  final GlobalKey _reportBodyBoundaryKey = GlobalKey();
  final QuillNativeBridge _nativeBridge = QuillNativeBridge();
  String _periodType = 'month';
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  DateTime _weekAnchor = DateTime.now();
  int? _touchedCountSectionIndex;
  int? _touchedTimeSectionIndex;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    logger.debug('📊  StatsResultPage 初始化');
    logger.debug(
      '🔧  构造参数: statisticsData=${widget.statisticsData != null ? '有数据' : '无数据'}, periodType=${widget.periodType}',
    );
    _periodType = switch (widget.periodType) {
      'week' => 'week',
      'year' => 'year',
      _ => 'month',
    };
    final anchor = widget.anchorDate ?? DateTime.now();
    _selectedYear = anchor.year;
    _selectedMonth = anchor.month;
    _weekAnchor = anchor;
    _statisticsService = sl<HabitStatisticsService>();
    _statisticsResultProvider = StatisticsResultProvider();
    _loadStatistics();
  }

  @override
  void dispose() {
    _statisticsResultProvider.dispose();
    super.dispose();
  }

  // 加载统计数据
  Future<void> _loadStatistics() async {
    try {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      await _statisticsResultProvider.loadStatistics(
        preloadedData: widget.statisticsData,
        periodType: _periodType,
        habits: habitProvider.habits,
        selectedYear: _selectedYear,
        selectedMonth: _periodType == 'month' ? _selectedMonth : null,
      );
    } catch (e) {
      logger.error('❌  加载统计数据失败: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('加载统计数据失败')));
    }
  }

  // 获取当前月的习惯完成次数数据（用于饼状图）
  Map<String, int> _getMonthlyHabitCompletionCounts() {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final range = _selectedRange();
    return _statisticsService.getHabitCompletionCountsForRangeByHabitId(
      habitProvider.habits,
      startDate: range.start,
      endDate: range.end,
    );
  }

  // 获取当前月的习惯完成时间数据（用于饼状图）
  Map<String, int> _getMonthlyHabitCompletionMinutes() {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final range = _selectedRange();
    return _statisticsService.getHabitCompletionMinutesForRangeByHabitId(
      habitProvider.habits,
      startDate: range.start,
      endDate: range.end,
    );
  }

  List<Map<String, dynamic>> _getHabitGoalCompletionData() {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final range = _selectedRange();
    return _statisticsService.getHabitGoalCompletionDataFor(
      habitProvider.habits,
      startDate: range.start,
      endDate: range.end,
    );
  }

  DateTimeRange _selectedRange() {
    if (_periodType == 'year') {
      return DateTimeRange(
        start: DateTime(_selectedYear, 1, 1),
        end: DateTime(_selectedYear, 12, 31),
      );
    }
    if (_periodType == 'week') {
      final weekStartDay = Provider.of<PersonalizationProvider>(
        context,
        listen: false,
      ).weekStartDay;
      final start = TimeManagementUtil.getWeekStartDate(
        _weekAnchor,
        weekStartDay: weekStartDay,
      );
      return DateTimeRange(
        start: start,
        end: TimeManagementUtil.addCalendarDays(start, 6),
      );
    }
    return DateTimeRange(
      start: DateTime(_selectedYear, _selectedMonth, 1),
      end: DateTime(_selectedYear, _selectedMonth + 1, 0),
    );
  }

  String get _periodLabel => switch (_periodType) {
    'week' => '本周',
    'year' => '本年',
    _ => '本月',
  };

  String get _selectedRangeLabel {
    final range = _selectedRange();
    if (_periodType == 'year') return '${range.start.year}年';
    if (_periodType == 'month') {
      return '${range.start.year}年${range.start.month}月';
    }
    return '${range.start.year}年${range.start.month}月${range.start.day}日 – '
        '${range.end.month}月${range.end.day}日';
  }

  Future<Uint8List> _captureReportImage() async {
    final deviceRatio = View.of(context).devicePixelRatio;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    await WidgetsBinding.instance.endOfFrame;
    final pixelRatio = deviceRatio.clamp(1.5, 2.0).toDouble();
    ui.Image? headerImage;
    ui.Image? bodyImage;
    ui.Picture? picture;
    ui.Image? image;
    try {
      headerImage = await _captureBoundary(
        _reportHeaderBoundaryKey,
        pixelRatio,
      );
      bodyImage = await _captureBoundary(_reportBodyBoundaryKey, pixelRatio);
      final gap = (StatsShareResultPageConstants.sectionSpacing * pixelRatio)
          .round();
      final outputWidth = math.max(headerImage.width, bodyImage.width);
      final outputHeight = headerImage.height + gap + bodyImage.height;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(backgroundColor, BlendMode.src);
      canvas.drawImage(
        headerImage,
        Offset((outputWidth - headerImage.width) / 2, 0),
        Paint(),
      );
      canvas.drawImage(
        bodyImage,
        Offset(
          (outputWidth - bodyImage.width) / 2,
          (headerImage.height + gap).toDouble(),
        ),
        Paint(),
      );
      picture = recorder.endRecording();
      image = await picture.toImage(outputWidth, outputHeight);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('无法生成分享图片');
      }
      return bytes.buffer.asUint8List();
    } finally {
      image?.dispose();
      picture?.dispose();
      headerImage?.dispose();
      bodyImage?.dispose();
    }
  }

  Future<ui.Image> _captureBoundary(GlobalKey key, double pixelRatio) async {
    final boundary = key.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('分享报告尚未完成渲染');
    }
    return boundary.toImage(pixelRatio: pixelRatio);
  }

  Future<void> _saveReportImage() async {
    await _runExport(() async {
      final imageBytes = await _captureReportImage();
      if (kIsWeb) {
        await downloadReportPng(imageBytes, _reportFileName);
        _showExportMessage('报告图片已下载');
        return;
      }
      final isMobile =
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
      if (isMobile) {
        final supported = await _nativeBridge.isSupported(
          QuillNativeBridgeFeature.saveImageToGallery,
        );
        if (!supported) {
          throw UnsupportedError('当前设备不支持保存图片到相册');
        }
        await _nativeBridge.saveImageToGallery(
          imageBytes,
          options: GalleryImageSaveOptions(
            name: _reportFileName,
            fileExtension: 'png',
            albumName: null,
          ),
        );
        _showExportMessage('报告图片已保存到相册');
        return;
      }

      final supported = await _nativeBridge.isSupported(
        QuillNativeBridgeFeature.saveImage,
      );
      if (!supported) {
        throw UnsupportedError('当前平台不支持保存图片');
      }
      final result = await _nativeBridge.saveImage(
        imageBytes,
        options: ImageSaveOptions(name: _reportFileName, fileExtension: 'png'),
      );
      if (!kIsWeb && result.filePath == null) {
        _showExportMessage('已取消保存');
        return;
      }
      _showExportMessage('报告图片已保存');
    });
  }

  Future<void> _copyReportImage() async {
    await _runExport(() async {
      final supported = await _nativeBridge.isSupported(
        QuillNativeBridgeFeature.copyImageToClipboard,
      );
      if (!supported) {
        throw UnsupportedError('当前平台不支持复制图片到剪贴板');
      }
      final imageBytes = await _captureReportImage();
      await _nativeBridge.copyImageToClipboard(imageBytes);
      _showExportMessage('报告图片已复制到剪贴板');
    });
  }

  Future<void> _runExport(Future<void> Function() operation) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      await operation();
    } catch (error, stackTrace) {
      logger.error('导出分享报告失败: $error\n$stackTrace');
      _showExportMessage(
        error is UnsupportedError ? error.message.toString() : '生成图片失败，请稍后重试',
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String get _reportFileName {
    final range = _selectedRange();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return 'Contrail_${_periodType}_${range.start.year}'
        '${twoDigits(range.start.month)}${twoDigits(range.start.day)}';
  }

  void _showExportMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildGoalCompletionBarChart(
    List<Map<String, dynamic>> goalCompletionData,
  ) {
    const maxValue = 1.0;
    final barGroups = <BarChartGroupData>[
      for (int index = 0; index < goalCompletionData.length; index++)
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: goalCompletionData[index]['completionRate'] as double,
              color: goalCompletionData[index]['color'] as Color,
              width: ScreenUtil().setWidth(20),
              borderRadius: BorderRadius.all(
                Radius.circular(ScreenUtil().setWidth(4)),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxValue,
                color: ThemeHelper.surfaceVariant(context),
              ),
            ),
          ],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '习惯目标完成度',
          style: TextStyle(
            fontSize: StatsShareResultPageConstants.sectionTitleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: StatsShareResultPageConstants.titleChartSpacing),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: SizedBox(
            height: StatsShareResultPageConstants.chartHeight,
            child: Semantics(
              label: '习惯目标完成度柱状图',
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= goalCompletionData.length) {
                            return const SizedBox.shrink();
                          }
                          return SizedBox(
                            width: ScreenUtil().setWidth(72),
                            child: Text(
                              goalCompletionData[index]['name'].toString(),
                              style: TextStyle(
                                fontSize: StatsShareResultPageConstants
                                    .axisLabelFontSize,
                                color: ThemeHelper.onBackground(context),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                        reservedSize: ScreenUtil().setWidth(48),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 0.25,
                        getTitlesWidget: (value, meta) => Text(
                          '${(value * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize:
                                StatsShareResultPageConstants.axisLabelFontSize,
                            color: ThemeHelper.onBackground(context),
                          ),
                        ),
                        reservedSize: ScreenUtil().setWidth(48),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.25,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: ThemeHelper.outline(
                        context,
                      ).withValues(alpha: 0.35),
                      strokeWidth: ScreenUtil().setWidth(1),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final name = goalCompletionData[group.x]['name'];
                        final percent = (rod.toY * 100).toStringAsFixed(0);
                        return BarTooltipItem(
                          '$name\n$percent%',
                          TextStyle(
                            color: ThemeHelper.onBackground(context),
                            fontSize:
                                AppTypographyConstants.chartLegendFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodControls() {
    return Container(
      key: const ValueKey('share-report-period-controls'),
      padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
      decoration: ThemeHelper.panelDecoration(
        context,
        radius: ScreenUtil().setWidth(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: '周',
                  selected: _periodType == 'week',
                  onTap: () {
                    setState(() => _periodType = 'week');
                    _loadStatistics();
                  },
                ),
              ),
              SizedBox(width: ScreenUtil().setWidth(8)),
              Expanded(
                child: _buildFilterChip(
                  label: '月',
                  selected: _periodType == 'month',
                  onTap: () {
                    setState(() => _periodType = 'month');
                    _loadStatistics();
                  },
                ),
              ),
              SizedBox(width: ScreenUtil().setWidth(8)),
              Expanded(
                child: _buildFilterChip(
                  label: '年',
                  selected: _periodType == 'year',
                  onTap: () {
                    setState(() => _periodType = 'year');
                    _loadStatistics();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: StatsShareResultPageConstants.sectionSpacing),
          if (_periodType == 'week')
            Builder(
              builder: (context) {
                final range = _selectedRange();
                return Row(
                  children: [
                    _buildCompactNavButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () {
                        setState(() {
                          _weekAnchor = TimeManagementUtil.addCalendarDays(
                            _weekAnchor,
                            -7,
                          );
                        });
                        _loadStatistics();
                      },
                    ),
                    Expanded(
                      child: Text(
                        '${range.start.month}月${range.start.day}日 – '
                        '${range.end.month}月${range.end.day}日',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: StatsShareResultPageConstants
                              .sectionTitleFontSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _buildCompactNavButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: () {
                        final nextAnchor = TimeManagementUtil.addCalendarDays(
                          _weekAnchor,
                          7,
                        );
                        final weekStartDay = context
                            .read<PersonalizationProvider>()
                            .weekStartDay;
                        final nextStart = TimeManagementUtil.getWeekStartDate(
                          nextAnchor,
                          weekStartDay: weekStartDay,
                        );
                        final currentStart =
                            TimeManagementUtil.getWeekStartDate(
                              DateTime.now(),
                              weekStartDay: weekStartDay,
                            );
                        if (nextStart.isAfter(currentStart)) return;
                        setState(() => _weekAnchor = nextAnchor);
                        _loadStatistics();
                      },
                    ),
                  ],
                );
              },
            )
          else if (_periodType == 'month')
            Row(
              children: [
                _buildCompactNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () {
                    setState(() {
                      final m = _selectedMonth - 1;
                      if (m >= 1) {
                        _selectedMonth = m;
                      } else {
                        _selectedYear -= 1;
                        _selectedMonth = 12;
                      }
                    });
                    _loadStatistics();
                  },
                ),
                Expanded(
                  child: Text(
                    '$_selectedYear年$_selectedMonth月',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:
                          StatsShareResultPageConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _buildCompactNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () {
                    setState(() {
                      final m = _selectedMonth + 1;
                      final now = DateTime.now();
                      final nextYear = m > 12
                          ? _selectedYear + 1
                          : _selectedYear;
                      final nextMonth = m > 12 ? 1 : m;
                      final notFuture = DateTime(
                        nextYear,
                        nextMonth,
                        1,
                      ).isBefore(DateTime(now.year, now.month, 2));
                      if (notFuture) {
                        _selectedYear = nextYear;
                        _selectedMonth = nextMonth;
                      }
                    });
                    _loadStatistics();
                  },
                ),
              ],
            )
          else if (_periodType == 'year')
            Row(
              children: [
                _buildCompactNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () {
                    setState(() {
                      _selectedYear -= 1;
                    });
                    _loadStatistics();
                  },
                ),
                Expanded(
                  child: Text(
                    '$_selectedYear年',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:
                          StatsShareResultPageConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _buildCompactNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () {
                    setState(() {
                      final now = DateTime.now();
                      if (_selectedYear < now.year) {
                        _selectedYear += 1;
                      }
                    });
                    _loadStatistics();
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  // 饼状图部分 - 用于显示习惯完成次数
  Widget _buildCompletionCountPieChart() {
    final completionCounts = _getMonthlyHabitCompletionCounts();
    final habits = Provider.of<HabitProvider>(context, listen: false).habits;
    final habitsById = {for (final habit in habits) habit.id: habit};
    final totalCount = completionCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );

    if (totalCount == 0) {
      return Center(child: Text('$_periodLabel暂无记录'));
    }

    Color colorFor(String habitId) => sl<HabitColorRegistry>().getColorById(
      habitId,
      fallback: Theme.of(context).colorScheme.primary,
    );
    String nameFor(String habitId) => habitsById[habitId]?.name ?? habitId;
    final items = [
      for (final entry in sortPositiveDistributionEntries(completionCounts))
        _DistributionItem(
          name: nameFor(entry.key),
          value: entry.value.toDouble(),
          displayValue: '${entry.value} 次',
          color: colorFor(entry.key),
        ),
    ];

    return _buildDistributionDonut(
      title: '记录次数分布',
      subtitle: '$_periodLabel各习惯记录占比',
      centerValue: '$totalCount',
      centerLabel: '次记录',
      items: items,
      touchedIndex: _touchedCountSectionIndex,
      onTouched: (index) {
        setState(() => _touchedCountSectionIndex = index);
      },
    );
  }

  // 饼状图部分 - 用于显示习惯完成时间
  Widget _buildCompletionTimePieChart() {
    final completionMinutes = _getMonthlyHabitCompletionMinutes();
    final habits = Provider.of<HabitProvider>(context, listen: false).habits;
    final habitsById = {for (final habit in habits) habit.id: habit};
    Color colorFor(String habitId) => sl<HabitColorRegistry>().getColorById(
      habitId,
      fallback: Theme.of(context).colorScheme.primary,
    );
    String nameFor(String habitId) => habitsById[habitId]?.name ?? habitId;
    final totalMinutes = completionMinutes.values.fold(
      0,
      (sum, minutes) => sum + minutes,
    );

    if (totalMinutes == 0) {
      return Center(child: Text('$_periodLabel暂无时间记录'));
    }

    final items = [
      for (final entry in sortPositiveDistributionEntries(completionMinutes))
        _DistributionItem(
          name: nameFor(entry.key),
          value: entry.value.toDouble(),
          displayValue: entry.value >= 60
              ? '${entry.value ~/ 60}时${entry.value % 60}分'
              : '${entry.value} 分',
          color: colorFor(entry.key),
        ),
    ];
    final totalText = totalMinutes >= 60
        ? '${totalMinutes ~/ 60}时${totalMinutes % 60}分'
        : '$totalMinutes 分';

    return _buildDistributionDonut(
      title: '专注时长分布',
      subtitle: '$_periodLabel各习惯投入时长占比',
      centerValue: totalText,
      centerLabel: '总专注',
      items: items,
      touchedIndex: _touchedTimeSectionIndex,
      onTouched: (index) {
        setState(() => _touchedTimeSectionIndex = index);
      },
    );
  }

  Widget _buildDistributionDonut({
    required String title,
    required String subtitle,
    required String centerValue,
    required String centerLabel,
    required List<_DistributionItem> items,
    required int? touchedIndex,
    required ValueChanged<int?> onTouched,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ThemeHelper.visualTheme(context).panelSecondaryColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: ThemeHelper.visualTheme(context).panelBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppTypographyConstants.panelTitleFontSize,
              fontWeight: FontWeight.w800,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: AppTypographyConstants.panelSubtitleFontSize,
              color: ThemeHelper.onBackground(context).withValues(alpha: 0.56),
            ),
          ),
          SizedBox(height: StatsShareResultPageConstants.sectionSpacing),
          Center(
            child: SizedBox(
              width: 190.w,
              height: 190.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      centerSpaceRadius: 58.r,
                      sectionsSpace: 4.r,
                      sections: [
                        for (int index = 0; index < items.length; index++)
                          PieChartSectionData(
                            color: items[index].color,
                            value: items[index].value,
                            title: '',
                            radius: touchedIndex == index ? 23.r : 18.r,
                          ),
                      ],
                      pieTouchData: PieTouchData(
                        enabled: true,
                        touchCallback: (event, response) {
                          final index =
                              response?.touchedSection?.touchedSectionIndex;
                          if (event is FlPointerExitEvent || index == null) {
                            onTouched(null);
                          } else if (event is FlTapUpEvent) {
                            onTouched(touchedIndex == index ? null : index);
                          } else if (event is FlPointerHoverEvent) {
                            onTouched(index);
                          }
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 42.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            centerValue,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: ThemeHelper.onBackground(context),
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          centerLabel,
                          style: TextStyle(
                            fontSize:
                                AppTypographyConstants.panelSubtitleFontSize,
                            color: ThemeHelper.onBackground(
                              context,
                            ).withValues(alpha: 0.54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: StatsShareResultPageConstants.sectionSpacing),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final item in items)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999.r),
                    border: Border.all(
                      color: item.color.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '${item.name}  ${item.displayValue}',
                        style: TextStyle(
                          fontSize: AppTypographyConstants.chartLegendFontSize,
                          fontWeight: FontWeight.w700,
                          color: ThemeHelper.onBackground(context),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _statisticsResultProvider,
      child: Consumer<StatisticsResultProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            body: Container(
              decoration:
                  ThemeHelper.generateBackgroundDecoration(context) ??
                  BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor, // 与主题颜色联动
                  ),
              child: SafeArea(
                bottom: false,
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.errorMessage != null
                    ? Center(child: Text(provider.errorMessage!))
                    : _buildContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    final goalCompletionData = _getHabitGoalCompletionData();
    final hasGoalHabits = goalCompletionData.isNotEmpty;
    final completionCounts = _getMonthlyHabitCompletionCounts();
    final completionMinutes = _getMonthlyHabitCompletionMinutes();
    final totalCount = completionCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final totalMinutes = completionMinutes.values.fold(
      0,
      (sum, minutes) => sum + minutes,
    );
    final minutesText = totalMinutes >= 60
        ? '${totalMinutes ~/ 60}时${totalMinutes % 60}分'
        : '$totalMinutes 分';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        ScreenUtil().setWidth(16),
        HeroHeaderPageConstants.topSpacing,
        ScreenUtil().setWidth(16),
        ScreenUtil().setHeight(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMergedPageHeader(
            hasGoalHabits: hasGoalHabits,
            totalCount: totalCount,
            minutesText: minutesText,
            goalCount: goalCompletionData.length,
          ),
          _buildContentSection(_buildExportToolbar()),
          _buildContentSection(_buildPeriodControls()),
          _buildContentSection(
            RepaintBoundary(
              key: _reportBodyBoundaryKey,
              child: Container(
                key: const ValueKey('share-report-body'),
                width: double.infinity,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: ThemeHelper.panelDecoration(
                        context,
                        radius: ScreenUtil().setWidth(16),
                      ),
                      padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '结果统计',
                            style: ThemeHelper.textStyleWithTheme(
                              context,
                              fontSize:
                                  AppTypographyConstants.appBarTitleFontSize,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(
                            height:
                                StatsShareResultPageConstants.sectionSpacing,
                          ),
                          _buildCompletionCountPieChart(),
                          SizedBox(
                            height:
                                StatsShareResultPageConstants.sectionSpacing,
                          ),
                          _buildCompletionTimePieChart(),
                        ],
                      ),
                    ),
                    if (hasGoalHabits) ...[
                      SizedBox(
                        height: StatsShareResultPageConstants.sectionSpacing,
                      ),
                      Container(
                        width: double.infinity,
                        decoration: ThemeHelper.panelDecoration(
                          context,
                          radius: ScreenUtil().setWidth(16),
                        ),
                        padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '目标追踪',
                              style: ThemeHelper.textStyleWithTheme(
                                context,
                                fontSize:
                                    AppTypographyConstants.appBarTitleFontSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(
                              height:
                                  StatsShareResultPageConstants.sectionSpacing,
                            ),
                            _buildGoalCompletionBarChart(goalCompletionData),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergedPageHeader({
    required bool hasGoalHabits,
    required int totalCount,
    required String minutesText,
    required int goalCount,
  }) {
    final visualTheme = ThemeHelper.visualTheme(context);
    return Stack(
      children: [
        RepaintBoundary(
          key: _reportHeaderBoundaryKey,
          child: AnimatedContainer(
            key: const ValueKey('share-report-page-header'),
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: EdgeInsets.all(ScreenUtil().setWidth(18)),
            decoration: ThemeHelper.heroDecoration(
              context,
              radius: ScreenUtil().setWidth(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: _isExporting ? 0 : ScreenUtil().setWidth(94),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '分享报告',
                        key: const ValueKey('share-report-title'),
                        style: TextStyle(
                          fontSize:
                              AppTypographyConstants.secondaryHeroTitleFontSize,
                          fontWeight: FontWeight.w900,
                          color: visualTheme.heroForeground,
                        ),
                      ),
                      SizedBox(height: ScreenUtil().setHeight(5)),
                      Text(
                        hasGoalHabits ? '汇总记录次数、专注时长与目标达成率' : '汇总记录次数与专注时长',
                        style: TextStyle(
                          fontSize: AppTypographyConstants
                              .secondaryHeroSubtitleFontSize,
                          color: visualTheme.heroSecondaryForeground,
                        ),
                      ),
                      SizedBox(height: ScreenUtil().setHeight(6)),
                      Text(
                        _selectedRangeLabel,
                        style: TextStyle(
                          fontSize:
                              AppTypographyConstants.sectionSubtitleFontSize,
                          fontWeight: FontWeight.w700,
                          color: visualTheme.heroForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: StatsShareResultPageConstants.sectionSpacing),
                Row(
                  children: [
                    Expanded(
                      child: _buildHeroStat(
                        label: '记录次数',
                        value: '$totalCount 次',
                      ),
                    ),
                    SizedBox(width: ScreenUtil().setWidth(10)),
                    Expanded(
                      child: _buildHeroStat(label: '专注时长', value: minutesText),
                    ),
                    if (hasGoalHabits) ...[
                      SizedBox(width: ScreenUtil().setWidth(10)),
                      Expanded(
                        child: _buildHeroStat(
                          label: '目标项',
                          value: '$goalCount 个',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!_isExporting)
          Positioned(
            top: ScreenUtil().setHeight(18),
            left: ScreenUtil().setWidth(18),
            child: _buildHeaderBackButton(),
          ),
      ],
    );
  }

  Widget _buildHeaderBackButton() {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('share-report-back-button'),
        onTap: () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: ThemeHelper.heroControlDecoration(context, radius: 16.r),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 18.sp,
                color: heroForeground,
              ),
              SizedBox(width: 6.w),
              Text(
                '返回',
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

  Widget _buildContentSection(Widget child) {
    return Padding(
      padding: StatsShareResultPageConstants.contentMargin,
      child: child,
    );
  }

  Widget _buildExportToolbar() {
    return Container(
      key: const ValueKey('share-report-export-toolbar'),
      width: double.infinity,
      padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
      decoration: ThemeHelper.panelDecoration(
        context,
        secondary: true,
        radius: ScreenUtil().setWidth(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '图片操作',
            style: TextStyle(
              fontSize: AppTypographyConstants.panelTitleFontSize,
              fontWeight: FontWeight.w800,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '下方预览确认无误后，可复制到剪贴板或保存到本地',
            style: TextStyle(
              fontSize: AppTypographyConstants.panelSubtitleFontSize,
              color: ThemeHelper.onBackground(context).withValues(alpha: 0.58),
            ),
          ),
          SizedBox(height: StatsShareResultPageConstants.cardMargin),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : _copyReportImage,
                  icon: const Icon(Icons.content_copy_rounded),
                  label: const Text('复制图片'),
                ),
              ),
              SizedBox(width: ScreenUtil().setWidth(12)),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isExporting ? null : _saveReportImage,
                  icon: _isExporting
                      ? SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(_isExporting ? '生成中' : '保存图片'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat({required String label, required String value}) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    final heroSecondary = ThemeHelper.visualTheme(
      context,
    ).heroSecondaryForeground;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenUtil().setWidth(12),
        vertical: ScreenUtil().setHeight(12),
      ),
      decoration: ThemeHelper.heroControlDecoration(
        context,
        radius: ScreenUtil().setWidth(18),
      ),
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
          SizedBox(height: ScreenUtil().setHeight(6)),
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

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(18)),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: ScreenUtil().setWidth(14),
            vertical: ScreenUtil().setHeight(12),
          ),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.15)
                : ThemeHelper.visualTheme(context).panelSecondaryColor,
            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(18)),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.45)
                  : ThemeHelper.visualTheme(context).panelBorderColor,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTypographyConstants.statisticsSegmentLabelFontSize,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? scheme.primary
                    : ThemeHelper.onBackground(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(14)),
        child: Ink(
          width: ScreenUtil().setWidth(36),
          height: ScreenUtil().setWidth(36),
          decoration: BoxDecoration(
            color: ThemeHelper.visualTheme(context).panelSecondaryColor,
            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(14)),
            border: Border.all(
              color: ThemeHelper.visualTheme(context).panelBorderColor,
            ),
          ),
          child: Icon(
            icon,
            size: ScreenUtil().setSp(18),
            color: ThemeHelper.onBackground(context),
          ),
        ),
      ),
    );
  }
}

class _DistributionItem {
  final String name;
  final double value;
  final String displayValue;
  final Color color;

  const _DistributionItem({
    required this.name,
    required this.value,
    required this.displayValue,
    required this.color,
  });
}

// 创建一个缓存页面的包装器
class KeepAliveStatsResultPage extends StatefulWidget {
  final Map<String, dynamic>? statisticsData;
  final String? periodType;
  final DateTime? anchorDate;

  const KeepAliveStatsResultPage({
    super.key,
    this.statisticsData,
    this.periodType,
    this.anchorDate,
  });

  @override
  State<KeepAliveStatsResultPage> createState() =>
      _KeepAliveStatsResultPageState();
}

class _KeepAliveStatsResultPageState extends State<KeepAliveStatsResultPage>
    with AutomaticKeepAliveClientMixin<KeepAliveStatsResultPage> {
  @override
  void initState() {
    super.initState();
    logger.debug('💾  KeepAliveStatsResultPage 初始化');
    logger.debug(
      '🔧  构造参数: statisticsData=${widget.statisticsData != null ? '有数据' : '无数据'}, periodType=${widget.periodType}',
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    logger.debug('🏗️  KeepAliveStatsResultPage 构建，传递参数给 StatsResultPage');
    return StatsResultPage(
      statisticsData: widget.statisticsData,
      periodType: widget.periodType,
      anchorDate: widget.anchorDate,
    );
  }
}
