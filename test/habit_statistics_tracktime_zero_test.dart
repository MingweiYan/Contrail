import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';

void main() {
  test('Time trend returns zeros when trackTime is false', () {
    final svc = HabitStatisticsService();
    final habit = Habit(id: 'h', name: 'no-time', trackTime: false, cycleType: CycleType.monthly);
    final spotsWeek = svc.generateTrendSpots(habit, 'time', 'week', DateTime.now().year, DateTime.now().month, 1, WeekStartDay.monday);
    final spotsMonth = svc.generateTrendSpots(habit, 'time', 'month', DateTime.now().year, DateTime.now().month, 1, WeekStartDay.monday);
    final spotsYear = svc.generateTrendSpots(habit, 'time', 'year', DateTime.now().year, DateTime.now().month, 1, WeekStartDay.monday);
    expect(spotsWeek.every((s) => s.y == 0.0), true);
    expect(spotsMonth.every((s) => s.y == 0.0), true);
    expect(spotsYear.every((s) => s.y == 0.0), true);
  });
}
