import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:contrail/features/habit/presentation/pages/add_habit_page.dart';
import 'package:contrail/features/habit/presentation/pages/habit_management_page.dart';
import 'package:contrail/features/habit/presentation/pages/habit_tracking_page.dart';
import 'package:contrail/shared/models/habit.dart';

class HabitRoutes {
  static const String management = 'habits';
  static const String add = 'habits/add';
  static const String edit = 'habits/edit';
  static const String tracking = 'habits/tracking';

  static List<GoRoute> get routes => [
        GoRoute(
          path: management,
          builder: (context, state) => const HabitManagementPage(),
        ),
        GoRoute(
          path: add,
          builder: (context, state) => const AddHabitPage(),
        ),
        GoRoute(
          path: edit,
          builder: (context, state) {
            final habit = state.extra as Habit;
            return AddHabitPage(habitToEdit: habit);
          },
        ),
        GoRoute(
          path: tracking,
          builder: (context, state) {
            final habit = state.extra as Habit;
            return HabitTrackingPage(habit: habit);
          },
        ),
      ];
}