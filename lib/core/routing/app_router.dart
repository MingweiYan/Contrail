import 'package:go_router/go_router.dart';
import 'package:contrail/features/habit/presentation/routes/habit_routes.dart';
import 'package:contrail/features/statistics/presentation/routes/statistics_routes.dart';
import 'package:contrail/features/profile/presentation/routes/profile_routes.dart';
import 'package:contrail/navigation/main_tab_page.dart';
import 'package:contrail/features/splash/presentation/pages/splash_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // 闪屏页面路由
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // 主页路由
      GoRoute(
        path: '/',
        builder: (context, state) => const MainTabPage(),
        routes: [
          ...HabitRoutes.routes,
          ...StatisticsRoutes.routes,
          ...ProfileRoutes.routes,
        ],
      ),
    ],
  );
}
