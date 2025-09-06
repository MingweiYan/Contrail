import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:contrail/features/profile/presentation/pages/profile_page.dart';

class ProfileRoutes {
  static const String root = 'profile';
  static const String settings = 'profile/settings';
  static const String about = 'profile/about';

  static List<GoRoute> get routes => [
        GoRoute(
          path: root,
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: settings,
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: about,
          builder: (context, state) => const ProfilePage(),
        ),
      ];
}