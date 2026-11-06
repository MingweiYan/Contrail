import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/icon_helper.dart';
import 'package:contrail/shared/utils/theme_helper.dart';

class TimelineViewWidget extends StatefulWidget {
  final List<Habit> habits;
  final int selectedYear;
  final int selectedMonth;

  const TimelineViewWidget({
    super.key,
    required this.habits,
    required this.selectedYear,
    required this.selectedMonth,
  });

  @override
  State<TimelineViewWidget> createState() => _TimelineViewWidgetState();
}

class _TimelineViewWidgetState extends State<TimelineViewWidget> {
  static const int _pageSize = 20;
  static const double _loadMoreThreshold = 260;

  int _visibleSessionCount = _pageSize;
  ScrollPosition? _ancestorScrollPosition;
  bool _isExpanding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextPosition = Scrollable.maybeOf(context)?.position;
    if (identical(nextPosition, _ancestorScrollPosition)) {
      return;
    }
    _ancestorScrollPosition?.removeListener(_handleAncestorScroll);
    _ancestorScrollPosition = nextPosition;
    _ancestorScrollPosition?.addListener(_handleAncestorScroll);
  }

  @override
  void didUpdateWidget(covariant TimelineViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear ||
        oldWidget.selectedMonth != widget.selectedMonth ||
        !identical(oldWidget.habits, widget.habits)) {
      _visibleSessionCount = _pageSize;
    }
  }

  @override
  void dispose() {
    _ancestorScrollPosition?.removeListener(_handleAncestorScroll);
    super.dispose();
  }

  void _handleAncestorScroll() {
    final position = _ancestorScrollPosition;
    if (position == null ||
        !position.hasContentDimensions ||
        position.extentAfter > _loadMoreThreshold) {
      return;
    }
    _loadNextPage();
  }

  void _loadNextPage() {
    if (_isExpanding || !mounted) {
      return;
    }
    final totalCount = _collectSessions().length;
    if (_visibleSessionCount >= totalCount) {
      return;
    }

    _isExpanding = true;
    setState(() {
      _visibleSessionCount = math.min(
        totalCount,
        _visibleSessionCount + _pageSize,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isExpanding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _collectSessions();
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timeline_rounded,
                size: 32.sp,
                color: Theme.of(context).colorScheme.outline,
              ),
              SizedBox(height: 10.h),
              Text(
                '当前月份及此前没有专注记录',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final visibleSessions = sessions
        .take(math.min(_visibleSessionCount, sessions.length))
        .toList();
    final hasMore = visibleSessions.length < sessions.length;
    final grouped = <DateTime, List<_TimelineEntry>>{};
    for (final session in visibleSessions) {
      final day = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      grouped.putIfAbsent(day, () => []).add(session);
    }
    final groupedEntries = grouped.entries.toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHistorySummary(
            context,
            visibleCount: visibleSessions.length,
            totalCount: sessions.length,
          ),
          SizedBox(height: 12.h),
          Stack(
            children: [
              Positioned(
                left: 26.5.w,
                top: 14.h,
                bottom: 14.h,
                child: Container(
                  key: const ValueKey('timeline-continuous-rail'),
                  width: 3.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999.r),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.52),
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.22),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < groupedEntries.length; index++)
                    _buildDateGroup(
                      context,
                      day: groupedEntries[index].key,
                      sessions: groupedEntries[index].value,
                      isLast: index == groupedEntries.length - 1,
                    ),
                ],
              ),
            ],
          ),
          if (hasMore)
            _buildLoadMoreIndicator(
              context,
              remainingCount: sessions.length - visibleSessions.length,
            )
          else if (sessions.length > _pageSize)
            _buildAllLoadedIndicator(context, sessions.length),
        ],
      ),
    );
  }

  List<_TimelineEntry> _collectSessions() {
    final sessions = <_TimelineEntry>[];
    final selectedMonthEnd = DateTime(
      widget.selectedYear,
      widget.selectedMonth + 1,
      1,
    );
    final now = DateTime.now();
    final effectiveEnd = selectedMonthEnd.isAfter(now)
        ? now.add(const Duration(microseconds: 1))
        : selectedMonthEnd;
    var ordinal = 0;
    for (final habit in widget.habits) {
      habit.trackingDurations.forEach((startTime, durations) {
        if (!startTime.isBefore(effectiveEnd)) {
          return;
        }
        for (final duration in durations) {
          sessions.add(
            _TimelineEntry(
              habit: habit,
              startTime: startTime,
              duration: duration,
              ordinal: ordinal++,
            ),
          );
        }
      });
    }
    sessions.sort((first, second) {
      final timeComparison = second.startTime.compareTo(first.startTime);
      if (timeComparison != 0) {
        return timeComparison;
      }
      return second.ordinal.compareTo(first.ordinal);
    });
    return sessions;
  }

  Widget _buildHistorySummary(
    BuildContext context, {
    required int visibleCount,
    required int totalCount,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('timeline-history-summary'),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 17.sp, color: colorScheme.primary),
          SizedBox(width: 7.w),
          Expanded(
            child: Text(
              '从 ${widget.selectedYear}年${widget.selectedMonth}月 向前 · '
              '已显示 $visibleCount/$totalCount 条',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(
    BuildContext context, {
    required DateTime day,
    required List<_TimelineEntry> sessions,
    required bool isLast,
  }) {
    return Column(
      key: ValueKey('timeline-date-group-${day.millisecondsSinceEpoch}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateHeader(context, day: day, sessionCount: sessions.length),
        for (var index = 0; index < sessions.length; index++) ...[
          _buildSession(context, session: sessions[index]),
          if (index != sessions.length - 1) SizedBox(height: 12.h),
        ],
        if (!isLast)
          Padding(
            padding: EdgeInsets.only(
              left: 68.w,
              right: 4.w,
              top: 16.h,
              bottom: 18.h,
            ),
            child: Container(
              key: ValueKey(
                'timeline-date-separator-${day.millisecondsSinceEpoch}',
              ),
              height: 1.5.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999.r),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.72),
                    Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateHeader(
    BuildContext context, {
    required DateTime day,
    required int sessionCount,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56.w,
            child: Center(
              child: Container(
                key: ValueKey(
                  'timeline-date-node-${day.millisecondsSinceEpoch}',
                ),
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                  border: Border.all(
                    color: ThemeHelper.visualTheme(context).panelColor,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.18),
                      blurRadius: 5.r,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              key: ValueKey(
                'timeline-date-header-${day.millisecondsSinceEpoch}',
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 2.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    DateFormat('MM月dd日').format(day),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _weekdayText(day),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$sessionCount 条记录',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSession(
    BuildContext context, {
    required _TimelineEntry session,
  }) {
    final habit = session.habit;
    final color = habit.color;
    final endTime = session.startTime.add(session.duration);
    final icon = IconHelper.getIconData(habit.icon, logError: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 56.w,
          child: Center(
            child: Container(
              key: ValueKey(
                'timeline-session-node-${habit.id}-${session.startTime.millisecondsSinceEpoch}-${session.ordinal}',
              ),
              width: 50.w,
              height: 50.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: ThemeHelper.visualTheme(context).panelColor,
                  width: 3,
                ),
              ),
              child: Icon(
                icon,
                size: 26.sp,
                color: ThemeHelper.getOptimalTextColor(context, color),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Dismissible(
            key: ValueKey(
              'timeline-session-${habit.id}_${session.startTime.millisecondsSinceEpoch}_${session.duration.inMicroseconds}_${session.ordinal}',
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(context),
            onDismissed: (_) => _deleteSession(context, session),
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: ThemeHelper.destructive(context),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: ThemeHelper.onDestructive(context),
              ),
            ),
            child: Container(
              key: ValueKey(
                'timeline-session-card-${habit.id}-${session.startTime.millisecondsSinceEpoch}-${session.ordinal}',
              ),
              constraints: BoxConstraints(minHeight: 58.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: Color.alphaBlend(
                    color.withValues(alpha: 0.12),
                    colorScheme.outlineVariant.withValues(alpha: 0.48),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${DateFormat('HH:mm').format(session.startTime)} – '
                          '${DateFormat('HH:mm').format(endTime)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      _durationText(session.duration),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMoreIndicator(
    BuildContext context, {
    required int remainingCount,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('timeline-load-more-indicator'),
      margin: EdgeInsets.only(left: 68.w, top: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18.sp,
            color: colorScheme.primary,
          ),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              '继续下滑，加载更早记录（剩余 $remainingCount 条）',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllLoadedIndicator(BuildContext context, int totalCount) {
    return Padding(
      padding: EdgeInsets.only(left: 68.w, top: 4.h),
      child: Text(
        '已加载全部 $totalCount 条历史记录',
        key: const ValueKey('timeline-all-loaded-indicator'),
        style: TextStyle(
          fontSize: 12.sp,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('删除记录'),
            content: const Text('确定删除这条专注记录吗？此操作不可恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: ThemeHelper.destructive(dialogContext),
                  foregroundColor: ThemeHelper.onDestructive(dialogContext),
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteSession(
    BuildContext context,
    _TimelineEntry session,
  ) async {
    await context.read<HabitProvider>().removeTrackingRecord(
      session.habit.id,
      session.startTime,
      session.duration,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已删除专注记录')));
    }
  }

  String _weekdayText(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  String _durationText(Duration duration) {
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes.remainder(60);
      return minutes == 0
          ? '${duration.inHours}小时'
          : '${duration.inHours}小时$minutes分';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟';
    }
    return '${duration.inSeconds}秒';
  }
}

class _TimelineEntry {
  const _TimelineEntry({
    required this.habit,
    required this.startTime,
    required this.duration,
    required this.ordinal,
  });

  final Habit habit;
  final DateTime startTime;
  final Duration duration;
  final int ordinal;
}
