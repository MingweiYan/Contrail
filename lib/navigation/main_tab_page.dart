import 'package:flutter/material.dart';
import 'package:contrail/features/habit/presentation/pages/habit_management_page.dart';
import 'package:contrail/features/statistics/presentation/pages/statistics_page.dart';
import 'package:contrail/features/profile/presentation/pages/profile_page.dart';
import 'package:contrail/shared/layout/adaptive_navigation_scaffold.dart';
import 'package:contrail/shared/utils/theme_helper.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainTabPageState>();
    if (state != null) {
      state.updateTabIndex(index);
    }
  }

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _selectedIndex = 0;

  void updateTabIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static final List<Widget> _pages = <Widget>[
    HabitManagementPage(),
    StatisticsPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final decoration = ThemeHelper.generateBackgroundDecoration(context);
    const items = <AdaptiveNavigationItem>[
      AdaptiveNavigationItem(icon: Icons.list_rounded, label: '习惯'),
      AdaptiveNavigationItem(icon: Icons.bar_chart_rounded, label: '统计'),
      AdaptiveNavigationItem(icon: Icons.person_rounded, label: '我的'),
    ];

    return AdaptiveNavigationScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      items: items,
      body: Container(
        decoration: decoration,
        child: _pages.elementAt(_selectedIndex),
      ),
    );
  }
}
