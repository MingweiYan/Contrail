import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:contrail/features/focus/presentation/pages/focus_selection_page.dart';
import 'package:contrail/shared/models/habit.dart';

class FocusRoutes {
  static const String root = 'focus';
  static const String selection = 'focus/selection';
  static const String tracking = 'focus/tracking';

  static List<GoRoute> get routes => [
        GoRoute(
          path: selection,
          builder: (context, state) {
            final habit = state.extra as Habit;
            return FocusSelectionPage(habit: habit);
          },
        ),
      ];
}