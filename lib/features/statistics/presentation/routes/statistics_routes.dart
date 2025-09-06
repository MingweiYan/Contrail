import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:contrail/features/statistics/presentation/pages/statistics_page.dart';

class StatisticsRoutes {
  static const String root = 'statistics';
  static const String details = 'statistics/details';
  static const String timeline = 'statistics/timeline';

  static List<GoRoute> get routes => [
        GoRoute(
          path: root,
          builder: (context, state) => const StatisticsPage(),
        ),
        GoRoute(
          path: details,
          builder: (context, state) => const StatisticsPage(),
        ),
        GoRoute(
          path: timeline,
          builder: (context, state) => const StatisticsPage(),
        ),
      ];
}