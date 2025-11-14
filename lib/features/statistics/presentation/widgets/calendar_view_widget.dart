import 'package:flutter/material.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';

// 日历视图中习惯点大小分析：
// 1. 当某天完成的习惯数量 <= 2 个时，使用 Row 布局（一行显示），习惯点大小固定为 12.0 x 12.0
// 2. 当某天完成的习惯数量 > 2 个时，使用 GridView.builder 布局（多行显示，每行2个），习惯点大小由GridView自动计算
// 3. 这导致了超过一行后习惯点变大的现象，因为GridView的习惯点大小没有明确设置为与Row布局相同的尺寸

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
    // 获取当月天数
    final startDate = DateTime(selectedYear, selectedMonth, 1);
    final endDate = DateTime(selectedYear, selectedMonth + 1, 0);
    final daysInMonth = endDate.day;
    final today = DateTime.now();
    final isTodayInCurrentMonth = today.year == selectedYear && today.month == selectedMonth;

    // 直接使用从父组件传入的周起始日参数
    
    // 计算月份的第一天是星期几（0-6，对应周日到周六）
    int firstDayOfMonthWeekday = startDate.weekday % 7;
    
    // 根据周起始日调整星期计算
    if (weekStartDay == WeekStartDay.monday) {
      // 对于周一为起始日，将周一作为0
      firstDayOfMonthWeekday = (firstDayOfMonthWeekday - 1) % 7;
      if (firstDayOfMonthWeekday < 0) firstDayOfMonthWeekday += 7;
    }
    
    // 计算需要显示的行数
    final weeksInMonth = (daysInMonth + firstDayOfMonthWeekday - 1) ~/ 7 + 1;
    final daysToDisplay = weeksInMonth * 7;

    // 动态调整单元格宽高比，增加高度以便显示更多习惯
    double cellAspectRatio = 0.7; 
    if (habits.isEmpty) {
      // 如果没有习惯，可以使用更小的高度
      cellAspectRatio = 0.9;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // 7列，对应星期
        childAspectRatio: cellAspectRatio,
        crossAxisSpacing: ScreenUtil().setWidth(2), // 减小间距，使布局更紧凑
        mainAxisSpacing: ScreenUtil().setHeight(2),
      ),
      itemCount: 7 + daysToDisplay, // 7天标题 + 显示的日期数量
      itemBuilder: (context, index) {
        // 星期标题
        if (index < 7) {
          
          // 根据周起始日生成星期标题数组
          List<String> weekDays;
          if (weekStartDay == WeekStartDay.monday) {
            weekDays = ['一', '二', '三', '四', '五', '六', '日'];
          } else {
            weekDays = ['日', '一', '二', '三', '四', '五', '六'];
          }
          
          // 计算是否为周末
          bool isWeekend;
          if (weekStartDay == WeekStartDay.monday) {
            // 周一为起始日时，周六和周日是周末
            isWeekend = index == 5 || index == 6;
          } else {
            // 周日为起始日时，周六和周日是周末
            isWeekend = index == 0 || index == 6;
          }
          
          return Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: ScreenUtil().setHeight(12)),
            child: Text(
              weekDays[index], 
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                color: isWeekend 
                  ? ThemeHelper.error(context) 
                  : ThemeHelper.onSurface(context),
                fontSize: ScreenUtil().setSp(18),
              ),
            ),
          );
        }

        // 日期单元格
        final displayIndex = index - 7;
        final dayOffset = displayIndex - firstDayOfMonthWeekday + 1;
        
        // 当前月份的日期
        final isCurrentMonthDate = dayOffset > 0 && dayOffset <= daysInMonth;
        final day = isCurrentMonthDate ? dayOffset : 0;
        
        // 今天的日期
        final isToday = isTodayInCurrentMonth && isCurrentMonthDate && day == today.day;
        // 计算星期几
        int weekday = 0;
        bool isWeekend = false;
        if (isCurrentMonthDate) {
          // 获取实际的星期几
          weekday = DateTime(selectedYear, selectedMonth, day).weekday % 7;
          
          // 根据周起始日确定是否为周末
          if (weekStartDay == WeekStartDay.monday) {
            // 周一为起始日时，周六和周日是周末
            isWeekend = weekday == 6 || weekday == 0; // 0是周日，6是周六
          } else {
            // 周日为起始日时，周六和周日是周末
            isWeekend = weekday == 0 || weekday == 6;
          }
        }

        // 检查哪些习惯在当天完成
        List<int> completedHabitIndices = [];
        if (isCurrentMonthDate) {
          final date = DateTime(selectedYear, selectedMonth, day);
          final dateOnly = DateTime(date.year, date.month, date.day);
          
          for (int i = 0; i < habits.length; i++) {
            final habit = habits[i];
            if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
                habit.dailyCompletionStatus[dateOnly] == true) {
              completedHabitIndices.add(i);
            }
          }
        }

        // 构建单元格内容
        return Container(
          decoration: BoxDecoration(
            color: isToday 
              ? ThemeHelper.primary(context).withOpacity(0.1) // 今天的特殊背景色
              : isCurrentMonthDate 
                ? ThemeHelper.surface(context) 
                : Colors.transparent, // 非当前月份不显示背景
            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)), // 圆角更美观
            border: isToday 
              ? Border.all(color: ThemeHelper.primary(context), width: ScreenUtil().setWidth(2)) // 今天边框高亮
              : null,
            boxShadow: isToday 
              ? [
                  BoxShadow(
                    color: ThemeHelper.primary(context).withOpacity(0.2),
                    blurRadius: ScreenUtil().setWidth(4),
                    offset: Offset(0, ScreenUtil().setHeight(2)),
                  ),
                ] 
              : null,
          ),
          child: Stack(
            children: [
              // 日期
              if (isCurrentMonthDate)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(ScreenUtil().setWidth(6)),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(18),
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday 
                          ? ThemeHelper.primary(context) // 今天日期特殊颜色
                          : isWeekend 
                            ? ThemeHelper.error(context)
                            : ThemeHelper.onSurface(context),
                      ),
                    ),
                  ),
                ),
              
              // 习惯完成标记 - 统一使用GridView来确保大小一致
              if (isCurrentMonthDate && completedHabitIndices.isNotEmpty)
                Positioned(
                  bottom: ScreenUtil().setHeight(4),
                  left: ScreenUtil().setWidth(4),
                  right: ScreenUtil().setWidth(4),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 总是使用2列，确保单个习惯点大小与两个习惯点时的大小对齐
                      mainAxisSpacing: ScreenUtil().setHeight(2),
                      crossAxisSpacing: ScreenUtil().setWidth(2),
                    ),
                    itemCount: completedHabitIndices.length,
                    itemBuilder: (context, i) {
                      final habitIndex = completedHabitIndices[i];
                      final color = habitColors[habits[habitIndex].name] ?? Colors.grey;
                      return Container(
                        width: ScreenUtil().setWidth(12),
                        height: ScreenUtil().setHeight(12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ThemeHelper.surface(context),
                            width: ScreenUtil().setWidth(1),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}