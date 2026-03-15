void main() {
  // 测试 2026 年 1 月，周起始日为周一
  testCalendar(2026, 1, WeekStartDay.monday);
  
  // 测试 2026 年 1 月，周起始日为周日
  testCalendar(2026, 1, WeekStartDay.sunday);
}

enum WeekStartDay { monday, sunday }

void testCalendar(int year, int month, WeekStartDay weekStartDay) {
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0);
  final daysInMonth = endDate.day;
  
  // 计算月份的第一天是星期几（0-6，对应周日到周六）
  int firstDayOfMonthWeekday = startDate.weekday % 7;
  
  // 根据周起始日调整星期计算
  if (weekStartDay == WeekStartDay.monday) {
    firstDayOfMonthWeekday = (firstDayOfMonthWeekday - 1) % 7;
    if (firstDayOfMonthWeekday < 0) firstDayOfMonthWeekday += 7;
  }
  
  // 计算需要显示的行数
  final weeksInMonth = ((firstDayOfMonthWeekday + daysInMonth - 1) / 7).ceil();
  final daysToDisplay = weeksInMonth * 7;
  
  print('2026 年 1 月 (周起始日：${weekStartDay == WeekStartDay.monday ? "周一" : "周日"})');
  print('  firstDayOfMonthWeekday (调整后): $firstDayOfMonthWeekday');
  print('  需要 $weeksInMonth 行，共 $daysToDisplay 个格子');
  print('');
  
  // 打印日历
  List<String> weekDays;
  if (weekStartDay == WeekStartDay.monday) {
    weekDays = ['一', '二', '三', '四', '五', '六', '日'];
  } else {
    weekDays = ['日', '一', '二', '三', '四', '五', '六'];
  }
  
  print('  ${weekDays.join('  ')}');
  
  int day = 1;
  for (int week = 0; week < weeksInMonth; week++) {
    String line = '  ';
    for (int weekday = 0; weekday < 7; weekday++) {
      if ((week == 0 && weekday < firstDayOfMonthWeekday) || day > daysInMonth) {
        line += '    ';
      } else {
        line += '${day.toString().padLeft(2)} ';
        day++;
      }
    }
    print(line);
  }
  print('');
}
