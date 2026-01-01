import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/shared/models/habit.dart';

void main() {
  group('HabitStatisticsService time trends', () {
    late HabitStatisticsService service;
    late Habit habit;

    setUp(() {
      service = HabitStatisticsService();
      habit = Habit(id: 'h1', name: 'Test', trackTime: true);
    });

    test('Week view aggregates seconds by day', () {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);
      habit.trackingDurations[dt] = [Duration(seconds: 30)];

      final spots = service.generateTimeTrendDataWithOffset(habit, 'week', 0);
      expect(spots.length, 7);
      expect(spots.any((s) => s.y > 0), true);
    });

    test('Month view aggregates weekly buckets using seconds', () {
      final now = DateTime.now();
      final dt1 = DateTime(now.year, now.month, now.day, 10, 0, 0);
      final dt2 = DateTime(now.year, now.month, now.day, 22, 0, 0);
      habit.trackingDurations[dt1] = [Duration(seconds: 45)];
      habit.trackingDurations[dt2] = [Duration(seconds: 30)];

      final spots = service.generateTimeTrendDataWithOffset(habit, 'month', 0);
      expect(spots.isNotEmpty, true);
      expect(spots.any((s) => s.y > 0), true);
    });

    test('Year view aggregates by month using seconds', () {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, 15, 8, 0, 0);
      habit.trackingDurations[dt] = [Duration(seconds: 45)];

      final spots = service.generateTimeTrendDataWithOffset(habit, 'year', 0);
      expect(spots.length, 12);
      final index = 12 - now.month;
      expect(spots[index].y > 0, true);
    });
  });
}
