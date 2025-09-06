import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:contrail/features/habit/presentation/routes/habit_routes.dart';
import 'package:contrail/features/statistics/presentation/routes/statistics_routes.dart';
import 'package:contrail/features/profile/presentation/routes/profile_routes.dart';
import 'package:contrail/features/focus/presentation/routes/focus_routes.dart';
import 'package:contrail/navigation/main_tab_page.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainTabPage(),
        routes: [
          ...HabitRoutes.routes,
          ...StatisticsRoutes.routes,
          ...ProfileRoutes.routes,
          ...FocusRoutes.routes,
        ],
      ),
    ],
  );
}