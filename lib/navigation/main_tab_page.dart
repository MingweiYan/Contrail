import 'package:flutter/material.dart';
import 'package:contrail/features/habit/presentation/pages/habit_management_page.dart';
import 'package:contrail/features/statistics/presentation/pages/statistics_page.dart';
import 'package:contrail/features/profile/presentation/pages/profile_page.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Container(
              decoration: decoration,
              child: _pages.elementAt(_selectedIndex),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list, size: ScreenUtil().setSp(24)),
            label: '习惯',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart, size: ScreenUtil().setSp(24)),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: ScreenUtil().setSp(24)),
            label: '我的',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
        selectedLabelStyle: TextStyle(
          fontSize: ScreenUtil().setSp(16),
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: ScreenUtil().setSp(16),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
