import 'package:flutter/material.dart';

import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

class CalendarViewWidget extends StatelessWidget {
  final List<Habit> habits;
  final int selectedYear;
  final int selectedMonth;
  final Map<String, Color> habitColors;
  final WeekStartDay weekStartDay;

  const CalendarViewWidget({
    super.key,
    required this.habits,
    required this.selectedYear,
    required this.selectedMonth,
    required this.habitColors,
    required this.weekStartDay,
  });

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime(selectedYear, selectedMonth, 1);
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    final today = DateTime.now();
    final firstWeekdayOffset = weekStartDay == WeekStartDay.monday
        ? startDate.weekday - DateTime.monday
        : startDate.weekday % 7;
    final weeksInMonth = ((daysInMonth + firstWeekdayOffset) / 7).ceil();
    final daysToDisplay = weeksInMonth * 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        const markerDiameter = 16.0;
        const markerSpacing = 2.0;
        const gridSpacing = 3.0;
        const dayCellHorizontalPadding = 2.0;
        final cellWidth = (constraints.maxWidth - gridSpacing * 6) / 7;
        final markerAreaWidth = cellWidth - dayCellHorizontalPadding;
        final estimatedMarkerColumns =
            ((markerAreaWidth + markerSpacing) /
                    (markerDiameter + markerSpacing))
                .floor();
        final markerColumns = estimatedMarkerColumns < 1
            ? 1
            : estimatedMarkerColumns;
        final markerRows = habits.isEmpty
            ? 0
            : (habits.length + markerColumns - 1) ~/ markerColumns;
        final dayCellExtent = habits.isEmpty
            ? 40.0
            : 60.0 + (markerRows - 1) * (markerDiameter + markerSpacing + 1);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWeekdayHeader(context),
            const SizedBox(height: 7),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: dayCellExtent,
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing: 6,
              ),
              itemCount: daysToDisplay,
              itemBuilder: (context, index) {
                final day = index - firstWeekdayOffset + 1;
                if (day < 1 || day > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final date = DateTime(selectedYear, selectedMonth, day);
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isWeekend =
                    date.weekday == DateTime.saturday ||
                    date.weekday == DateTime.sunday;
                final completedHabits = habits
                    .where((habit) => _hasRecordOnDay(habit, date))
                    .toList();

                return _buildDayCell(
                  context,
                  date: date,
                  isToday: isToday,
                  isWeekend: isWeekend,
                  completedHabits: completedHabits,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekdayHeader(BuildContext context) {
    final weekdays = weekStartDay == WeekStartDay.monday
        ? const ['一', '二', '三', '四', '五', '六', '日']
        : const ['日', '一', '二', '三', '四', '五', '六'];

    return Row(
      children: weekdays.asMap().entries.map((entry) {
        final index = entry.key;
        final isWeekend = weekStartDay == WeekStartDay.monday
            ? index >= 5
            : index == 0 || index == 6;
        return Expanded(
          child: Center(
            child: Text(
              entry.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant
                    .withValues(alpha: isWeekend ? 0.58 : 0.78),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCell(
    BuildContext context, {
    required DateTime date,
    required bool isToday,
    required bool isWeekend,
    required List<Habit> completedHabits,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final activityColor = completedHabits.isEmpty
        ? null
        : habitColors[completedHabits.first.id] ??
              habitColors[completedHabits.first.name] ??
              completedHabits.first.color;
    final activityStrength = completedHabits.isEmpty
        ? 0.0
        : (0.10 + completedHabits.length.clamp(1, 4) * 0.035);
    final backgroundColor = activityColor == null
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.28)
        : activityColor.withValues(alpha: activityStrength);

    return Semantics(
      label: '${date.month}月${date.day}日，${completedHabits.length}个习惯有记录',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(11),
          border: isToday
              ? Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.75),
                  width: 1.4,
                )
              : Border.all(
                  color: colorScheme.outline.withValues(
                    alpha: completedHabits.isEmpty ? 0.08 : 0.04,
                  ),
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(1, 6, 1, 5),
          child: Column(
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 12,
                  height: 1,
                  fontWeight: isToday || completedHabits.isNotEmpty
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: isToday
                      ? colorScheme.primary
                      : isWeekend
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                      : colorScheme.onSurface.withValues(
                          alpha: completedHabits.isEmpty ? 0.72 : 0.9,
                        ),
                ),
              ),
              const Spacer(),
              if (completedHabits.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    for (final habit in completedHabits)
                      Container(
                        key: ValueKey(
                          'calendar-marker-${date.day}-${habit.id}',
                        ),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              habitColors[habit.id] ??
                              habitColors[habit.name] ??
                              habit.color,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (habitColors[habit.id] ??
                                          habitColors[habit.name] ??
                                          habit.color)
                                      .withValues(alpha: 0.32),
                              blurRadius: 3.5,
                              spreadRadius: 0.3,
                            ),
                          ],
                        ),
                      ),
                  ],
                )
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasRecordOnDay(Habit habit, DateTime date) {
    return habit.dailyCompletionStatus.entries.any(
      (entry) =>
          entry.value &&
          entry.key.year == date.year &&
          entry.key.month == date.month &&
          entry.key.day == date.day,
    );
  }
}
