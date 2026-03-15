void main() {
  // 模拟日历组件的逻辑
  testMonth(2026, 1, "2026 年 1 月");
  testMonth(2026, 2, "2026 年 2 月");
  testMonth(2026, 3, "2026 年 3 月");
}

void testMonth(int year, int month, String label) {
  // 获取当月天数
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0);
  final daysInMonth = endDate.day;
  
  print('$label:');
  print('  daysInMonth = $daysInMonth');
  
  // 模拟 GridView 的 itemBuilder 逻辑
  int firstDayOfMonthWeekday = startDate.weekday % 7;
  final weeksInMonth = ((firstDayOfMonthWeekday + daysInMonth - 1) / 7).ceil();
  final daysToDisplay = weeksInMonth * 7;
  
  print('  需要显示的格子数：$daysToDisplay');
  print('  实际日期显示:');
  
  for (int displayIndex = 0; displayIndex < daysToDisplay; displayIndex++) {
    final dayOffset = displayIndex - firstDayOfMonthWeekday + 1;
    final isCurrentMonthDate = dayOffset > 0 && dayOffset <= daysInMonth;
    final day = isCurrentMonthDate ? dayOffset : 0;
    
    if (displayIndex % 7 == 0) {
      print('');
      print('  第${(displayIndex / 7).floor() + 1}行: ');
    }
    
    if (isCurrentMonthDate) {
      print('    $day(有效) ');
    } else {
      print('    $day(无效) ');
    }
  }
  print('');
}
