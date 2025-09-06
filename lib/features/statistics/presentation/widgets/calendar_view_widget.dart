import 'package:flutter/material.dart';
import 'package:contrail/shared/models/habit.dart';

class CalendarViewWidget extends StatelessWidget {
  final List<Habit> habits;
  final int selectedYear;
  final int selectedMonth;
  final Map<String, Color> habitColors;

  const CalendarViewWidget({
    super.key,
    required this.habits,
    required this.selectedYear,
    required this.selectedMonth,
    required this.habitColors,
  });

  @override
  Widget build(BuildContext context) {
    // 获取当月天数
    final startDate = DateTime(selectedYear, selectedMonth, 1);
    final endDate = DateTime(selectedYear, selectedMonth + 1, 0);
    final daysInMonth = endDate.day;

    // 计算日历所需高度
    final screenHeight = MediaQuery.of(context).size.height;
    final calendarHeight = screenHeight * 0.6; // 占屏幕高度的60%

    // 动态调整单元格宽高比
    double cellAspectRatio = 1.0;
    if (habits.length > 3) {
      // 如果习惯数量较多，减少宽高比以增加单元格高度
      cellAspectRatio = 0.8;
    }

    return Container(
      height: calendarHeight,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, // 7列，对应星期
          childAspectRatio: cellAspectRatio,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: 7 + daysInMonth, // 7天标题 + 当月天数
        itemBuilder: (context, index) {
          // 星期标题
          if (index < 7) {
            final weekDays = ['日', '一', '二', '三', '四', '五', '六'];
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(weekDays[index], style: TextStyle(fontWeight: FontWeight.bold)),
            );
          }

          // 日期单元格
          final day = index - 6; // 调整为从1开始的日期
          if (day > daysInMonth) return Container();

          final date = DateTime(selectedYear, selectedMonth, day);
          final dateOnly = DateTime(date.year, date.month, date.day);
          final weekday = date.weekday % 7; // 0-6，对应周日到周六

          // 检查哪些习惯在当天完成
          List<int> completedHabitIndices = [];
          for (int i = 0; i < habits.length; i++) {
            final habit = habits[i];
            if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
                habit.dailyCompletionStatus[dateOnly] == true) {
              completedHabitIndices.add(i);
            }
          }

          // 构建单元格内容
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 日期
                Container(
                  alignment: Alignment.topRight,
                  padding: EdgeInsets.all(4.0),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      color: weekday == 0 || weekday == 6 ? Colors.red : Colors.black,
                    ),
                  ),
                ),
                // 习惯完成标记
                Expanded(
                  child: completedHabitIndices.isEmpty
                      ? Container()
                      : GridView.builder(
                          shrinkWrap: true,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: completedHabitIndices.length > 3 ? 2 : 1,
                            childAspectRatio: 3.0,
                          ),
                          itemCount: completedHabitIndices.length,
                          itemBuilder: (context, i) {
                            final habitIndex = completedHabitIndices[i];
                            final color = habitColors[habits[habitIndex].name] ?? Colors.grey;
                            return Container(
                              margin: EdgeInsets.all(2.0),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                habits[habitIndex].name.length > 4
                                    ? habits[habitIndex].name.substring(0, 4) + '...'
                                    : habits[habitIndex].name,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}