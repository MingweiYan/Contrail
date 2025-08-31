import 'package:flutter/material.dart';
import '../pages/habit_management_page.dart';
import '../pages/habit_tracking_page.dart';
import '../pages/statistics_page.dart';
import '../pages/profile_page.dart';
import '../pages/add_habit_page.dart';
import '../models/habit.dart';
import '../navigation/main_tab_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const MainTabPage());
      case '/statistics':
        return MaterialPageRoute(builder: (_) => const StatisticsPage());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case '/add-habit':
        return MaterialPageRoute(builder: (_) => const AddHabitPage());
      case '/tracking':
        final habit = settings.arguments as Habit;
        return MaterialPageRoute(
          builder: (_) => HabitTrackingPage(habit: habit),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}