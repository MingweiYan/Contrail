void main() {
  // 测试 2026 年 1 月
  testMonth(2026, 1, "2026 年 1 月");
  
  // 测试 2026 年 2 月
  testMonth(2026, 2, "2026 年 2 月");
  
  // 测试 2026 年 3 月
  testMonth(2026, 3, "2026 年 3 月");
  
  // 测试 2026 年 4 月
  testMonth(2026, 4, "2026 年 4 月");
  
  // 测试 2026 年 5 月
  testMonth(2026, 5, "2026 年 5 月");
  
  // 测试 2026 年 6 月
  testMonth(2026, 6, "2026 年 6 月");
  
  // 测试 2026 年 7 月
  testMonth(2026, 7, "2026 年 7 月");
  
  // 测试 2026 年 8 月
  testMonth(2026, 8, "2026 年 8 月");
  
  // 测试 2026 年 9 月
  testMonth(2026, 9, "2026 年 9 月");
  
  // 测试 2026 年 10 月
  testMonth(2026, 10, "2026 年 10 月");
  
  // 测试 2026 年 11 月
  testMonth(2026, 11, "2026 年 11 月");
  
  // 测试 2026 年 12 月
  testMonth(2026, 12, "2026 年 12 月");
}

void testMonth(int year, int month, String label) {
  // 获取当月天数
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0);
  final daysInMonth = endDate.day;
  
  // 计算月份的第一天是星期几（0-6，对应周日到周六）
  int firstDayOfMonthWeekday = startDate.weekday % 7;
  
  // 计算需要显示的行数（新公式）
  final weeksInMonth = ((firstDayOfMonthWeekday + daysInMonth - 1) / 7).ceil();
  final daysToDisplay = weeksInMonth * 7;
  
  // 计算需要显示的行数（旧公式）
  final oldWeeksInMonth = (daysInMonth + firstDayOfMonthWeekday - 1) ~/ 7 + 1;
  final oldDaysToDisplay = oldWeeksInMonth * 7;
  
  print('$label:');
  print('  天数：$daysInMonth, 第一天 weekday: $firstDayOfMonthWeekday');
  print('  新公式：需要 $weeksInMonth 行，共 $daysToDisplay 个格子');
  print('  旧公式：需要 $oldWeeksInMonth 行，共 $oldDaysToDisplay 个格子');
  print('  差异：${weeksInMonth - oldWeeksInMonth} 行');
  print('');
}
