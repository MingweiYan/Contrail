import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/statistics/presentation/adapters/statistics_chart_adapter.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

void main() {
  test('a month ending on Sunday does not create an extra week bucket', () {
    final titles = StatisticsChartAdapter().generateTitlesData(
      'month',
      selectedYear: 2025,
      selectedMonth: 8,
      weekStartDay: WeekStartDay.monday,
    );

    expect(titles, ['7/28-8/3', '8/4-10', '8/11-17', '8/18-24', '8/25-31']);
  });
}
