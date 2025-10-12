import 'package:contrail/features/habit/presentation/pages/habit_tracking_page.dart';
import 'package:flutter/material.dart';
import 'package:contrail/features/habit/presentation/pages/habit_management_page.dart';
import 'package:contrail/features/statistics/presentation/pages/statistics_page.dart';
import 'package:contrail/features/profile/presentation/pages/profile_page.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/utils/theme_helper.dart';

import 'package:contrail/core/state/focus_state.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  // 静态方法来更新选中的索引
  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainTabPageState>();
    if (state != null) {
      state.updateTabIndex(index);
    }
  }

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  // 更新标签索引的方法
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    logger.debug('🔍  依赖变化时检查通知状态');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    logger.debug('🔄  应用从后台唤醒');
    // if (state == AppLifecycleState.resumed) {

    //   // 检查专注状态并更新时间
    //   final focusState = FocusState();
    //   // 调用appResumed方法更新后台流逝的时间
    //   focusState.appResumed();
    //   if (focusState.focusStatus != FocusStatus.stop && focusState.currentFocusHabit != null) {
    //     // 如果有正在进行中的专注，直接进入专注页面
    //     // 再次检查currentFocusHabit是否为null，防止竞态条件
    //     final currentHabit = focusState.currentFocusHabit;
    //     if (currentHabit != null) {
    //       Navigator.push(
    //         context,
    //         MaterialPageRoute(
    //           builder: (context) => HabitTrackingPage(habit: currentHabit),
    //         ),
    //       );
    //       logger.debug('🔄  导航到专注页面');
    //     }
    //   }
    // }
  }


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
        bottom: false, // 底部导航栏不需要避开
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
        selectedLabelStyle: TextStyle(fontSize: ScreenUtil().setSp(16), fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: ScreenUtil().setSp(16), fontWeight: FontWeight.w600),
      ),
    );
  }
}