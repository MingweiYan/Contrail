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
import '../main.dart'; // 导入main.dart以访问isNotificationClicked、isStatsReportNotification和statsReportType变量

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
  bool _showFocusNotification = false;

  // 更新标签索引的方法
  void updateTabIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  // 处理专注状态变化
  void _onFocusStateChanged(bool isFocusing) {
    setState(() {
      _showFocusNotification = isFocusing;
    });
  }
  
  // 返回专注页面
  void _returnToFocusPage() {
    final focusState = FocusState();
    if (focusState.currentFocusHabit != null) {
      // 使用GoRouter进行导航，避免与应用的路由管理系统冲突
      GoRouter.of(context).go('/habits/tracking', extra: focusState.currentFocusHabit!);
    }
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
    
    // 添加专注状态监听器
    final focusState = FocusState();
    focusState.addListener(_onFocusStateChanged);
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
    
    // 移除专注状态监听器
    final focusState = FocusState();
    focusState.removeListener(_onFocusStateChanged);
    
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
      
      setState(() {
        _showFocusNotification = focusState.isFocusing;
      });
    }
  }

  // 检查通知状态并执行相应的导航操作
  void _checkNotificationState() {
    logger.debug('🔍  检查通知状态: isStatsReportNotification=$isStatsReportNotification, isNotificationClicked=$isNotificationClicked, statsReportType=$statsReportType');
    
    // 检查是否是通过统计报告通知点击启动的
    if (isStatsReportNotification) {
      logger.debug('📊  检测到统计报告通知标志为true');
      // 确定周期类型
      String periodType = 'week'; // 默认周报告
      if (statsReportType == 'monthly_report') {
        periodType = 'month';
      }
      
      logger.debug('📅  确定周期类型: $periodType (statsReportType=$statsReportType)');
      logger.debug('🚀  准备导航到统计结果页面: statistics/result, extra={periodType: $periodType}');
      
      // 立即执行导航，不使用addPostFrameCallback以避免延迟问题
      try {
        // 直接使用GoRouter的静态方法进行导航，无需依赖BuildContext
        AppRouter.router.push('/statistics/result', extra: {
          'periodType': periodType,
        });
        logger.debug('✅  成功触发导航到统计结果页面');
      } catch (e) {
        logger.error('❌  导航失败: $e');
        // 即使导航失败，也重置全局变量，避免状态错乱
      }
      
      logger.debug('🔄  重置全局变量: isStatsReportNotification=false, isNotificationClicked=false, statsReportType=null');
      isStatsReportNotification = false; // 重置标记
      isNotificationClicked = false; // 同时重置普通通知标记
      statsReportType = null; // 重置报告类型
    } 
    // 检查是否是通过普通通知点击启动的
    else if (isNotificationClicked) {
      logger.debug('💬  检测到普通通知标志为true');
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
          // 专注提示按钮 - 固定在右下角，与添加习惯按钮对齐
          if (_showFocusNotification)
            Positioned(
              bottom: 20, // 位于添加习惯按钮上方
              left: 16,
              child: SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: _returnToFocusPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '有正在进行的专注',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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