void main() {
  // 2026 年 1 月 1 日实际是星期几
  final date = DateTime(2026, 1, 1);
  print('2026 年 1 月 1 日:');
  print('  weekday (1-7, 周一到周日): ${date.weekday}');
  print('  weekday % 7 (0-6): ${date.weekday % 7}');
  print('');
  
  // 按照代码逻辑计算
  int firstDayOfMonthWeekday = date.weekday % 7;
  print('  代码中的 firstDayOfMonthWeekday: $firstDayOfMonthWeekday');
  print('  解释：0=周日，1=周一，2=周二，3=周三，4=周四，5=周五，6=周六');
  print('  所以 2026 年 1 月 1 日是星期${['日', '一', '二', '三', '四', '五', '六'][firstDayOfMonthWeekday]}');
  print('');
  
  // 验证每个月的第一天
  for (int month = 1; month <= 12; month++) {
    final d = DateTime(2026, month, 1);
    int wd = d.weekday % 7;
    String wdStr = ['日', '一', '二', '三', '四', '五', '六'][wd];
    print('2026 年$month 月 1 日：weekday=$wd (星期$wdStr)');
  }
}
