import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:contrail/features/habit/presentation/pages/habit_management_page.dart';
import 'package:contrail/features/habit/presentation/pages/habit_tracking_page.dart';
import 'package:contrail/features/statistics/presentation/pages/statistics_page.dart';
import 'package:contrail/features/profile/presentation/pages/profile_page.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/core/routing/app_router.dart';
import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/shared/models/theme_model.dart' as app_theme;
import 'package:contrail/core/state/focus_state.dart';
import '../main.dart'; // 导入main.dart以访问isNotificationClicked变量

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
    _checkNotificationState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在依赖变化时也检查通知状态，确保从后台唤醒时能正确处理
    _checkNotificationState();
  }



  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 应用从后台唤醒时检查通知状态
      _checkNotificationState();
      
      // 检查专注状态并更新时间
      final focusState = FocusState();
      // 调用appResumed方法更新后台流逝的时间
      focusState.appResumed();
    }
  }

  // 检查通知状态并执行相应的导航操作
  void _checkNotificationState() {
    logger.debug('🔍  检查通知状态: isNotificationClicked=$isNotificationClicked');
    
    // 检查是否是通过通知点击启动的
    if (isNotificationClicked) {
      logger.debug('💬  检测到通知标志为true');
      // 立即执行导航，无需等待
      try {
        logger.debug('🔄  切换到底部导航栏的统计页面（索引1）');
        setState(() {
          _selectedIndex = 1; // 切换到统计页面（索引为1）
          isNotificationClicked = false; // 重置标记
        });
      } catch (e) {
        logger.error('❌  切换tab失败: $e');
        // 即使失败，也重置全局变量
        isNotificationClicked = false;
      }
    }
    else {
      logger.debug('✅  没有检测到通知点击，无需特殊处理');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;
    final decoration = ThemeHelper.generateBackgroundDecoration(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: decoration,
            child: _pages.elementAt(_selectedIndex),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '习惯管理',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}