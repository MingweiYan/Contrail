import 'package:flutter/material.dart';
import 'package:contrail/features/habit/presentation/pages/habit_management_page.dart';
import 'package:contrail/features/statistics/presentation/pages/statistics_page.dart';
import 'package:contrail/features/profile/presentation/pages/profile_page.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
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
    final visualTheme = ThemeHelper.visualTheme(context);
    const items = <({IconData icon, String label})>[
      (icon: Icons.list_rounded, label: '习惯'),
      (icon: Icons.bar_chart_rounded, label: '统计'),
      (icon: Icons.person_rounded, label: '我的'),
    ];

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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: AppTypographyConstants.bottomNavBarVerticalPadding,
            ),
            decoration: ThemeHelper.navigationDecoration(context),
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = _selectedIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: AppTypographyConstants.bottomNavItemVerticalPadding,
                      ),
                      decoration: isSelected
                          ? ThemeHelper.selectedNavigationItemDecoration(context)
                          : BoxDecoration(
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: ScreenUtil().setSp(19),
                            color: isSelected
                                ? visualTheme.navSelectedForeground
                                : visualTheme.navUnselectedForeground,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize:
                                  AppTypographyConstants.bottomNavLabelFontSize,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? visualTheme.navSelectedForeground
                                  : visualTheme.navUnselectedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
