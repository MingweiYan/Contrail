import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/features/statistics/domain/models/period_review_data.dart';
import 'package:contrail/features/statistics/domain/services/period_review_service.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/time_management_util.dart';
import 'package:contrail/shared/widgets/scroll_to_top_fab.dart';

class PeriodReviewPage extends StatefulWidget {
  const PeriodReviewPage({
    super.key,
    this.reviewService,
    this.initialPeriod = PeriodReviewPeriod.week,
    this.initialAnchor,
  });

  final PeriodReviewService? reviewService;
  final PeriodReviewPeriod initialPeriod;
  final DateTime? initialAnchor;

  @override
  State<PeriodReviewPage> createState() => _PeriodReviewPageState();
}

class _PeriodReviewPageState extends State<PeriodReviewPage> {
  final ScrollController _scrollController = ScrollController();
  late final PeriodReviewService _reviewService;
  late PeriodReviewPeriod _period;
  late DateTime _anchor;
  bool _distributionByTime = false;
  bool _rhythmByTime = false;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _anchor = widget.initialAnchor ?? DateTime.now();
    _reviewService =
        widget.reviewService ??
        PeriodReviewService(statisticsService: sl<HabitStatisticsService>());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().habits;
    final weekStartDay = context.watch<PersonalizationProvider>().weekStartDay;
    final data = _reviewService.build(
      habits,
      period: _period,
      anchor: _anchor,
      weekStartDay: weekStartDay,
    );

    return Scaffold(
      floatingActionButton: ScrollToTopFab(controller: _scrollController),
      body: Container(
        decoration:
            ThemeHelper.generateBackgroundDecoration(context) ??
            BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: HeroHeaderPageConstants.mainPagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildContentSection(
                  _buildPeriodControls(context, data, weekStartDay),
                ),
                _buildContentSection(_buildSummary(context, data)),
                _buildContentSection(_buildAutomaticSummary(context, data)),
                _buildContentSection(_buildComparison(context, data)),
                _buildContentSection(_buildInvestmentStructure(context, data)),
                _buildContentSection(_buildTimePattern(context, data)),
                if (data.goals.isNotEmpty)
                  _buildContentSection(_buildGoalReview(context, data)),
                SizedBox(height: PeriodReviewPageConstants.bottomSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final visualTheme = ThemeHelper.visualTheme(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: ThemeHelper.heroDecoration(context, radius: 28.r),
      child: Row(
        children: [
          _buildHeaderAction(
            context,
            icon: Icons.arrow_back_rounded,
            label: '返回',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '周期回顾',
                  style: TextStyle(
                    fontSize: AppTypographyConstants.secondaryHeroTitleFontSize,
                    fontWeight: FontWeight.w900,
                    color: visualTheme.heroForeground,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  '看见这一周期真实发生的记录与变化',
                  style: TextStyle(
                    fontSize:
                        AppTypographyConstants.secondaryHeroSubtitleFontSize,
                    color: visualTheme.heroSecondaryForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(Widget child) {
    return Padding(
      padding: PeriodReviewPageConstants.contentMargin,
      child: child,
    );
  }

  Widget _buildHeaderAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final color = ThemeHelper.visualTheme(context).heroForeground;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
          decoration: ThemeHelper.heroControlDecoration(context, radius: 15.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18.sp, color: color),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypographyConstants.secondaryHeroButtonFontSize,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodControls(
    BuildContext context,
    PeriodReviewData data,
    WeekStartDay weekStartDay,
  ) {
    return _buildPanel(
      context,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSegment(
                  context,
                  label: '周',
                  selected: _period == PeriodReviewPeriod.week,
                  onTap: () => _setPeriod(PeriodReviewPeriod.week),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildSegment(
                  context,
                  label: '月',
                  selected: _period == PeriodReviewPeriod.month,
                  onTap: () => _setPeriod(PeriodReviewPeriod.month),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildSegment(
                  context,
                  label: '年',
                  selected: _period == PeriodReviewPeriod.year,
                  onTap: () => _setPeriod(PeriodReviewPeriod.year),
                ),
              ),
            ],
          ),
          SizedBox(height: PeriodReviewPageConstants.sectionSpacing),
          Row(
            children: [
              _buildSquareButton(
                context,
                icon: Icons.chevron_left_rounded,
                tooltip: '上一个周期',
                onTap: () => _navigatePeriod(-1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _periodTitle(data.range),
                      style: TextStyle(
                        fontSize: AppTypographyConstants.sectionTitleFontSize,
                        fontWeight: FontWeight.w900,
                        color: ThemeHelper.onBackground(context),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _rangeLabel(data.range),
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
              _buildSquareButton(
                context,
                icon: Icons.chevron_right_rounded,
                tooltip: '下一个周期',
                onTap: _canNavigateNext(weekStartDay)
                    ? () => _navigatePeriod(1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, PeriodReviewData data) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            icon: Icons.edit_note_rounded,
            label: '记录次数',
            value: '${data.totalRecordCount} 次',
          ),
        ),
        SizedBox(width: PeriodReviewPageConstants.itemSpacing),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: Icons.timer_outlined,
            label: '专注时长',
            value: _durationText(data.totalFocusDuration),
          ),
        ),
        SizedBox(width: PeriodReviewPageConstants.itemSpacing),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: Icons.av_timer_rounded,
            label: '单次平均',
            value: _durationText(data.averageFocusDuration),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
      decoration: ThemeHelper.panelDecoration(
        context,
        secondary: true,
        radius: 20.r,
      ),
      child: Column(
        children: [
          Icon(icon, size: 21.sp, color: scheme.primary),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: AppTypographyConstants.chartStatValueFontSize,
                fontWeight: FontWeight.w900,
                color: ThemeHelper.onBackground(context),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: AppTypographyConstants.chartStatLabelFontSize,
              color: ThemeHelper.onBackground(context).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomaticSummary(BuildContext context, PeriodReviewData data) {
    return _buildPanel(
      context,
      secondary: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.auto_awesome_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 21.sp,
            ),
          ),
          SizedBox(width: 13.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '这一周期',
                  style: TextStyle(
                    fontSize: AppTypographyConstants.panelTitleFontSize,
                    fontWeight: FontWeight.w900,
                    color: ThemeHelper.onBackground(context),
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  _summaryText(data),
                  style: TextStyle(
                    height: 1.55,
                    fontSize: AppTypographyConstants.panelSubtitleFontSize,
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

  Widget _buildComparison(BuildContext context, PeriodReviewData data) {
    return _buildPanel(
      context,
      title: '上一周期对比',
      subtitle: '对比 ${_rangeLabel(data.previousRange)} 的相同进度',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDeltaTile(
                  context,
                  label: '记录次数',
                  current: '${data.totalRecordCount} 次',
                  delta: _countDeltaText(data.recordCountDelta),
                  positive: data.recordCountDelta > 0,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildDeltaTile(
                  context,
                  label: '专注时长',
                  current: _durationText(data.totalFocusDuration),
                  delta: _durationDeltaText(data.focusDurationDelta),
                  positive: data.focusDurationDelta > Duration.zero,
                ),
              ),
            ],
          ),
          if (data.habits.any(
            (habit) =>
                habit.recordCountDelta != 0 ||
                habit.focusDurationDelta != Duration.zero,
          )) ...[
            SizedBox(height: PeriodReviewPageConstants.itemSpacing),
            Divider(color: ThemeHelper.visualTheme(context).panelBorderColor),
            SizedBox(height: PeriodReviewPageConstants.itemSpacing),
            ..._withItemSpacing(
              _mostChangedHabits(
                data,
              ).map((habit) => _buildHabitChangeRow(context, habit)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeltaTile(
    BuildContext context, {
    required String label,
    required String current,
    required String delta,
    required bool positive,
  }) {
    final deltaColor = positive
        ? Theme.of(context).colorScheme.primary
        : ThemeHelper.onBackground(context).withValues(alpha: 0.62);
    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: ThemeHelper.visualTheme(context).panelSecondaryColor,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(
          color: ThemeHelper.visualTheme(context).panelBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypographyConstants.chartStatLabelFontSize,
              color: ThemeHelper.onBackground(context).withValues(alpha: 0.58),
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            current,
            style: TextStyle(
              fontSize: AppTypographyConstants.chartStatValueFontSize,
              fontWeight: FontWeight.w900,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            delta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppTypographyConstants.panelSubtitleFontSize,
              fontWeight: FontWeight.w700,
              color: deltaColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitChangeRow(
    BuildContext context,
    PeriodReviewHabitData habit,
  ) {
    final parts = <String>[];
    if (habit.recordCountDelta != 0) {
      parts.add(_countDeltaText(habit.recordCountDelta));
    }
    if (habit.tracksTime && habit.focusDurationDelta != Duration.zero) {
      parts.add(_durationDeltaText(habit.focusDurationDelta));
    }
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(color: habit.color, shape: BoxShape.circle),
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: Text(
            habit.name,
            style: TextStyle(
              fontSize: AppTypographyConstants.chartLegendFontSize,
              fontWeight: FontWeight.w800,
              color: ThemeHelper.onBackground(context),
            ),
          ),
        ),
        Flexible(
          child: Text(
            parts.join(' · '),
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: AppTypographyConstants.chartLegendFontSize,
              color: ThemeHelper.onBackground(context).withValues(alpha: 0.62),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentStructure(
    BuildContext context,
    PeriodReviewData data,
  ) {
    final items = data.habits.where((habit) {
      return _distributionByTime
          ? habit.focusDuration > Duration.zero
          : habit.recordCount > 0;
    }).toList();
    items.sort((first, second) {
      if (_distributionByTime) {
        return second.focusDuration.compareTo(first.focusDuration);
      }
      return second.recordCount.compareTo(first.recordCount);
    });
    final maxValue = items.isEmpty
        ? 0.0
        : items
              .map(
                (habit) => _distributionByTime
                    ? habit.focusDuration.inSeconds.toDouble()
                    : habit.recordCount.toDouble(),
              )
              .reduce(math.max);

    return _buildPanel(
      context,
      title: '投入结构',
      subtitle: '按占比从高到低查看注意力主要投入在哪里',
      trailing: _buildTwoWayToggle(
        context,
        first: '次数',
        second: '时间',
        secondSelected: _distributionByTime,
        onChanged: (value) => setState(() => _distributionByTime = value),
      ),
      child: items.isEmpty
          ? _buildEmpty(context, _distributionByTime ? '本周期暂无专注时长' : '本周期暂无记录')
          : Column(
              children: _withItemSpacing(
                items.map(
                  (habit) => _buildProgressRow(
                    context,
                    color: habit.color,
                    label: habit.name,
                    value: _distributionByTime
                        ? habit.focusDuration.inSeconds.toDouble()
                        : habit.recordCount.toDouble(),
                    maxValue: maxValue,
                    displayValue: _distributionByTime
                        ? _durationText(habit.focusDuration)
                        : '${habit.recordCount} 次',
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTimePattern(BuildContext context, PeriodReviewData data) {
    final weekdayBuckets = data.weekdayBuckets.where(_bucketHasValue).toList();
    final dayPartBuckets = data.dayPartBuckets.where(_bucketHasValue).toList();
    return _buildPanel(
      context,
      title: '时间规律',
      subtitle: '描述记录实际发生的时间，不评价是否连续',
      trailing: _buildTwoWayToggle(
        context,
        first: '次数',
        second: '时间',
        secondSelected: _rhythmByTime,
        onChanged: (value) => setState(() => _rhythmByTime = value),
      ),
      child: weekdayBuckets.isEmpty && dayPartBuckets.isEmpty
          ? _buildEmpty(context, '本周期暂无可分析的时间记录')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (weekdayBuckets.isNotEmpty) ...[
                  _buildSubheading(context, '星期分布'),
                  SizedBox(height: PeriodReviewPageConstants.itemSpacing),
                  _buildBucketBars(context, weekdayBuckets),
                ],
                if (dayPartBuckets.isNotEmpty) ...[
                  if (weekdayBuckets.isNotEmpty)
                    SizedBox(height: PeriodReviewPageConstants.sectionSpacing),
                  _buildSubheading(context, '时段分布'),
                  SizedBox(height: PeriodReviewPageConstants.itemSpacing),
                  _buildBucketBars(context, dayPartBuckets),
                ],
              ],
            ),
    );
  }

  bool _bucketHasValue(PeriodReviewTimeBucket bucket) {
    return _rhythmByTime
        ? bucket.focusDuration > Duration.zero
        : bucket.recordCount > 0;
  }

  Widget _buildBucketBars(
    BuildContext context,
    List<PeriodReviewTimeBucket> buckets,
  ) {
    final maxValue = buckets
        .map(
          (bucket) => _rhythmByTime
              ? bucket.focusDuration.inSeconds.toDouble()
              : bucket.recordCount.toDouble(),
        )
        .fold<double>(0, math.max);
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      children: _withItemSpacing(
        buckets.map(
          (bucket) => _buildProgressRow(
            context,
            color: color,
            label: bucket.label,
            value: _rhythmByTime
                ? bucket.focusDuration.inSeconds.toDouble()
                : bucket.recordCount.toDouble(),
            maxValue: maxValue,
            displayValue: _rhythmByTime
                ? _durationText(bucket.focusDuration)
                : '${bucket.recordCount} 次',
            compact: true,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalReview(BuildContext context, PeriodReviewData data) {
    return _buildPanel(
      context,
      title: '目标追踪',
      subtitle: '仅展示已设置目标的习惯，并按当前达成率排序',
      child: Column(
        children: _withItemSpacing(
          data.goals.map((goal) => _buildGoalRow(context, goal)),
        ),
      ),
    );
  }

  Widget _buildGoalRow(BuildContext context, PeriodReviewGoalData goal) {
    final percent = (goal.completionRate * 100).round();
    final deltaPoints = (goal.completionRateDelta * 100).round();
    final deltaText = deltaPoints == 0
        ? '与上一周期持平'
        : deltaPoints > 0
        ? '较上一周期高 $deltaPoints 个百分点'
        : '较上一周期低 ${deltaPoints.abs()} 个百分点';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.name,
                style: TextStyle(
                  fontSize: AppTypographyConstants.chartLegendFontSize,
                  fontWeight: FontWeight.w800,
                  color: ThemeHelper.onBackground(context),
                ),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: AppTypographyConstants.chartLegendFontSize,
                fontWeight: FontWeight.w900,
                color: goal.color,
              ),
            ),
          ],
        ),
        SizedBox(height: 7.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(999.r),
          child: LinearProgressIndicator(
            minHeight: 8.h,
            value: goal.completionRate.clamp(0, 1),
            color: goal.color,
            backgroundColor: goal.color.withValues(alpha: 0.12),
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          deltaText,
          style: TextStyle(
            fontSize: AppTypographyConstants.panelSubtitleFontSize,
            color: ThemeHelper.onBackground(context).withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow(
    BuildContext context, {
    required Color color,
    required String label,
    required double value,
    required double maxValue,
    required String displayValue,
    bool compact = false,
  }) {
    final ratio = maxValue <= 0 ? 0.0 : value / maxValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!compact) ...[
              Container(
                width: 9.w,
                height: 9.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 7.w),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTypographyConstants.chartLegendFontSize,
                  fontWeight: FontWeight.w700,
                  color: ThemeHelper.onBackground(context),
                ),
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: AppTypographyConstants.chartLegendFontSize,
                fontWeight: FontWeight.w800,
                color: ThemeHelper.onBackground(context),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(999.r),
          child: LinearProgressIndicator(
            minHeight: compact ? 7.h : 9.h,
            value: ratio.clamp(0, 1),
            color: color,
            backgroundColor: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildSubheading(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: AppTypographyConstants.panelTitleFontSize,
        fontWeight: FontWeight.w800,
        color: ThemeHelper.onBackground(context),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 18.h),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: AppTypographyConstants.panelSubtitleFontSize,
            color: ThemeHelper.onBackground(context).withValues(alpha: 0.54),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context, {
    required Widget child,
    String? title,
    String? subtitle,
    Widget? trailing,
    bool secondary = false,
  }) {
    return Container(
      width: double.infinity,
      padding: PeriodReviewPageConstants.panelPadding,
      decoration: ThemeHelper.panelDecoration(
        context,
        secondary: secondary,
        radius: 16.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppTypographyConstants.sectionTitleFontSize,
                          fontWeight: FontWeight.w900,
                          color: ThemeHelper.onBackground(context),
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize:
                                AppTypographyConstants.panelSubtitleFontSize,
                            height: 1.4,
                            color: ThemeHelper.onBackground(
                              context,
                            ).withValues(alpha: 0.56),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[SizedBox(width: 12.w), trailing],
              ],
            ),
            SizedBox(height: PeriodReviewPageConstants.sectionSpacing),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 11.h),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.14)
                : ThemeHelper.visualTheme(context).panelSecondaryColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.38)
                  : ThemeHelper.visualTheme(context).panelBorderColor,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTypographyConstants.statisticsSegmentLabelFontSize,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
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

  Widget _buildTwoWayToggle(
    BuildContext context, {
    required String first,
    required String second,
    required bool secondSelected,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: ThemeHelper.visualTheme(context).panelSecondaryColor,
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(
          color: ThemeHelper.visualTheme(context).panelBorderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMiniToggle(
            context,
            label: first,
            selected: !secondSelected,
            onTap: () => onChanged(false),
          ),
          _buildMiniToggle(
            context,
            label: second,
            selected: secondSelected,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniToggle(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTypographyConstants.panelSubtitleFontSize,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : ThemeHelper.onBackground(context).withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildSquareButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon),
      color: ThemeHelper.onBackground(context),
      disabledColor: ThemeHelper.onBackground(context).withValues(alpha: 0.22),
      style: IconButton.styleFrom(
        backgroundColor: ThemeHelper.visualTheme(context).panelSecondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(
            color: ThemeHelper.visualTheme(context).panelBorderColor,
          ),
        ),
      ),
    );
  }

  void _setPeriod(PeriodReviewPeriod value) {
    if (_period == value) return;
    setState(() {
      _period = value;
      _anchor = DateTime.now();
    });
  }

  void _navigatePeriod(int direction) {
    setState(() {
      switch (_period) {
        case PeriodReviewPeriod.week:
          _anchor = TimeManagementUtil.addCalendarDays(_anchor, 7 * direction);
        case PeriodReviewPeriod.month:
          _anchor = DateTime(_anchor.year, _anchor.month + direction, 1);
        case PeriodReviewPeriod.year:
          _anchor = DateTime(_anchor.year + direction, 1, 1);
      }
    });
  }

  bool _canNavigateNext(WeekStartDay weekStartDay) {
    final now = DateTime.now();
    switch (_period) {
      case PeriodReviewPeriod.week:
        final currentStart = TimeManagementUtil.getWeekStartDate(
          now,
          weekStartDay: weekStartDay,
        );
        final nextStart = TimeManagementUtil.getWeekStartDate(
          TimeManagementUtil.addCalendarDays(_anchor, 7),
          weekStartDay: weekStartDay,
        );
        return !nextStart.isAfter(currentStart);
      case PeriodReviewPeriod.month:
        final next = DateTime(_anchor.year, _anchor.month + 1, 1);
        return !next.isAfter(DateTime(now.year, now.month, 1));
      case PeriodReviewPeriod.year:
        return _anchor.year < now.year;
    }
  }

  List<Widget> _withItemSpacing(Iterable<Widget> widgets) {
    final items = widgets.toList();
    return [
      for (var index = 0; index < items.length; index++) ...[
        items[index],
        if (index != items.length - 1)
          SizedBox(height: PeriodReviewPageConstants.itemSpacing),
      ],
    ];
  }

  String _periodTitle(DateTimeRange range) {
    switch (_period) {
      case PeriodReviewPeriod.week:
        return '${range.start.month}月${range.start.day}日所在周';
      case PeriodReviewPeriod.month:
        return '${range.start.year}年${range.start.month}月';
      case PeriodReviewPeriod.year:
        return '${range.start.year}年';
    }
  }

  String _rangeLabel(DateTimeRange range) {
    if (range.start.year == range.end.year) {
      return '${range.start.year}/${range.start.month}/${range.start.day} – '
          '${range.end.month}/${range.end.day}';
    }
    return '${range.start.year}/${range.start.month}/${range.start.day} – '
        '${range.end.year}/${range.end.month}/${range.end.day}';
  }

  String _summaryText(PeriodReviewData data) {
    if (data.totalRecordCount == 0 &&
        data.totalFocusDuration == Duration.zero) {
      return '当前周期还没有记录。这里会在有数据后总结次数、时间与主要投入方向。';
    }
    final parts = <String>[
      '共记录 ${data.totalRecordCount} 次，专注 ${_durationText(data.totalFocusDuration)}',
    ];
    final countLeader = data.habits
        .where((habit) => habit.recordCount > 0)
        .firstOrNull;
    final focusLeaders =
        data.habits
            .where((habit) => habit.focusDuration > Duration.zero)
            .toList()
          ..sort(
            (first, second) =>
                second.focusDuration.compareTo(first.focusDuration),
          );
    if (countLeader != null) {
      parts.add('${countLeader.name}的记录次数最多');
    }
    if (focusLeaders.isNotEmpty) {
      parts.add('${focusLeaders.first.name}的专注投入最多');
    }
    return '${parts.join('；')}。';
  }

  List<PeriodReviewHabitData> _mostChangedHabits(PeriodReviewData data) {
    final changed = data.habits
        .where(
          (habit) =>
              habit.recordCountDelta != 0 ||
              habit.focusDurationDelta != Duration.zero,
        )
        .toList();
    changed.sort((first, second) {
      final firstScore =
          first.recordCountDelta.abs() * 60 +
          first.focusDurationDelta.inMinutes.abs();
      final secondScore =
          second.recordCountDelta.abs() * 60 +
          second.focusDurationDelta.inMinutes.abs();
      final scoreComparison = secondScore.compareTo(firstScore);
      if (scoreComparison != 0) return scoreComparison;
      return first.habitId.compareTo(second.habitId);
    });
    return changed.take(3).toList();
  }

  String _countDeltaText(int delta) {
    if (delta == 0) return '与上一周期持平';
    return delta > 0 ? '较上一周期多 $delta 次' : '较上一周期少 ${delta.abs()} 次';
  }

  String _durationDeltaText(Duration delta) {
    if (delta == Duration.zero) return '与上一周期持平';
    final prefix = delta > Duration.zero ? '较上一周期多 ' : '较上一周期少 ';
    return '$prefix${_durationText(delta.abs())}';
  }

  String _durationText(Duration duration) {
    if (duration <= Duration.zero) return '0 分';
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes.remainder(60);
      return minutes == 0
          ? '${duration.inHours} 小时'
          : '${duration.inHours}时$minutes分';
    }
    if (duration.inMinutes > 0) return '${duration.inMinutes} 分';
    return '${duration.inSeconds} 秒';
  }
}
