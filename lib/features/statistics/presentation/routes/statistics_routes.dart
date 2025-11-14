import 'package:go_router/go_router.dart';
import 'package:contrail/features/statistics/presentation/pages/statistics_page.dart';
import 'package:contrail/features/statistics/presentation/pages/stats_share_result_page.dart'
    show StatsResultPage, KeepAliveStatsResultPage; // 导入StatsResultPage和KeepAliveStatsResultPage

class StatisticsRoutes {
  static const String root = 'statistics';
  static const String details = 'statistics/details';
  static const String timeline = 'statistics/timeline';
  static const String result = 'statistics/result';

  static List<GoRoute> get routes => [
        GoRoute(
          path: root,
          builder: (context, state) => StatisticsPage(),
        ),
        GoRoute(
          path: details,
          builder: (context, state) => StatisticsPage(),
        ),
        GoRoute(
          path: timeline,
          builder: (context, state) => StatisticsPage(),
        ),
        GoRoute(
          path: result,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final statisticsData = extra?['statisticsData'] as Map<String, dynamic>?;
            final periodType = extra?['periodType'] as String?;
            return KeepAliveStatsResultPage(
              statisticsData: statisticsData,
              periodType: periodType,
            );
          },
        ),
      ];
}