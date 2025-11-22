import 'package:go_router/go_router.dart';
import 'package:contrail/features/profile/presentation/pages/profile_page.dart';

class ProfileRoutes {
  static const String root = 'profile';

  static List<GoRoute> get routes => [
        GoRoute(
          path: root,
          builder: (context, state) => const ProfilePage(),
        ),
      ];
}