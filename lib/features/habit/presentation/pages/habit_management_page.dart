import 'package:flutter/material.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/habit/domain/use_cases/get_habits_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/delete_habit_use_case.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/habit/presentation/pages/add_habit_page.dart';
import 'package:contrail/features/habit/presentation/pages/habit_tracking_page.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/core/state/focus_tracking_manager.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/features/habit/domain/services/habit_management_service.dart';
import 'package:contrail/features/habit/presentation/widgets/habit_item_widget.dart';
import 'package:contrail/features/habit/presentation/widgets/supplement_check_in_dialog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/widgets/header_card_widget.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';


class HabitManagementPage extends StatefulWidget {
  const HabitManagementPage({super.key});

  @override
  State<HabitManagementPage> createState() => _HabitManagementPageState();
}

class _HabitManagementPageState extends State<HabitManagementPage> {
  late final GetHabitsUseCase _getHabitsUseCase;
  late final UpdateHabitUseCase _updateHabitUseCase;
  late final DeleteHabitUseCase _deleteHabitUseCase;
  late final HabitManagementService _habitManagementService;
  List<Habit> _habits = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _getHabitsUseCase = sl<GetHabitsUseCase>();
    _updateHabitUseCase = sl<UpdateHabitUseCase>();
    _deleteHabitUseCase = sl<DeleteHabitUseCase>();
    _habitManagementService = sl<HabitManagementService>();
    _loadHabits();
  }
  
  // 加载用户使用天数 - 使用统计服务
  
  Future<void> _loadHabits() async {
    try {
      final habits = await _getHabitsUseCase.execute();
      final sorted = List<Habit>.from(habits)
        ..sort((a, b) => _getFinalProgress(a).compareTo(_getFinalProgress(b)));
      setState(() {
        _habits = sorted;
      });
    } catch (e) {
      logger.error('加载习惯失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载习惯失败: ${e.toString()}')),
      );
    } 
  }

  // 显示补充打卡对话框 - 使用独立组件
  void _showSupplementCheckInDialog(BuildContext context) {
    SupplementCheckInDialog.show(
      context: context,
      habits: _habits,
      updateHabitUseCase: _updateHabitUseCase,
      onRefresh: () async {
        await _loadHabits();
        _resortWithAnimation();
      },
    );
  }

  // 删除习惯
  Future<void> _deleteHabit(String habitId) async {
    try {
      await _deleteHabitUseCase.execute(habitId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('习惯删除成功')),
      );
      _loadHabits();
    } catch (e) {
      logger.error('删除习惯失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除习惯失败: ${e.toString()}')),
      );
    }
  }


  // 格式化习惯描述 - 使用统计服务
  String _formatHabitDescription(Habit habit) {
    return _habitManagementService.formatHabitDescription(habit);
  }
  
  // 获取最终的进度值 - 使用统计服务
  double _getFinalProgress(Habit habit) {
    return _habitManagementService.getFinalProgress(habit);
  }
  
  // 导航到追踪页面
  void _navigateToTrackingPage(Habit habit) {
    // 检查是否有正在进行的专注会话
    final focusState = sl<FocusTrackingManager>();
    if (focusState.focusStatus != FocusStatus.stop && focusState.currentFocusHabit != null) {
      // 如果正在专注的习惯与当前选择的习惯不同，显示提示
      if (focusState.currentFocusHabit!.id != habit.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已有专注正在进行中，请先结束当前专注')),
        );
        return; // 不导航到新的专注页面
      }
    }
    
    // 如果习惯设置了追踪时间，则导航到专注页面
    if (habit.trackTime) {
      // 使用async/await来等待从HabitTrackingPage返回，并刷新UI
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HabitTrackingPage(habit: habit),
        ),
      ).then((_) {
        // 从专注页面返回后刷新UI，但要先检查widget是否仍然存在
        if (mounted) {
          setState(() {
            // 重新加载习惯列表以显示更新后的进度
            _loadHabits();
          });
          _resortWithAnimation();
        }
      });
    } else {
      // 如果习惯没有设置追踪时间，则直接完成该习惯的追踪
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      habitProvider.stopTracking(habit.id, Duration(minutes: 1)); // 添加1分钟的默认追踪记录
      
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已完成 ${habit.name}')),
      );
      
      // 刷新UI以显示更新后的进度
      setState(() {
        _loadHabits();
      });
      _resortWithAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
  
    return Scaffold(
      body: Container(
        decoration: ThemeHelper.generateBackgroundDecoration(context) ?? BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor, // 与主题颜色联动
        ),
        padding: PageLayoutConstants.getPageContainerPadding(), // 使用共享的页面容器边距
        child: _buildHabitList(),
      ),
    );
  }



  Widget _buildHabitList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 炫酷的头部设计
        AnimatedContainer(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
          padding: HabitManagementPageConstants.headerPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.all(Radius.circular(HabitManagementPageConstants.headerBorderRadius)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我的习惯',
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: HabitManagementPageConstants.titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.onPrimary(context),
                ),
              ),
              SizedBox(height: HabitManagementPageConstants.smallSpacing),
              Text(
                '从新增一个习惯出发吧！',
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: HabitManagementPageConstants.subtitleFontSize,
                  color: ThemeHelper.onPrimary(context).withOpacity(0.9),
                ),
              ),
              SizedBox(height: HabitManagementPageConstants.largeSpacing),
              // 功能按钮 - 与统计页面风格一致
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 第一个按钮：补充打卡
                  StatisticsCardWidget(
                    icon: Icons.edit,
                    title: '补充记录',
                    onTap: () => _showSupplementCheckInDialog(context),
                  ),
                  
                  // 第二个按钮：查看专注
                  StatisticsCardWidget(
                    icon: Icons.timer,
                    title: '查看专注',
                    onTap: () {
                      // 检查是否有正在进行中的专注
                      final focusState = sl<FocusTrackingManager>();
                      if (focusState.focusStatus != FocusStatus.stop && focusState.currentFocusHabit != null) {
                        // 如果有正在进行中的专注，直接进入专注页面
                        // 再次检查currentFocusHabit是否为null，防止竞态条件
                        final currentHabit = focusState.currentFocusHabit;
                        if (currentHabit != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HabitTrackingPage(habit: currentHabit),
                            ),
                          ).then((_) {
                            // 从专注页面返回后刷新UI
                            setState(() {
                              _loadHabits();
                            });
                          });
                        } else {
                          // 如果currentFocusHabit变为null，显示错误提示
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('无法获取专注信息')),
                          );
                        }
                      } else {
                        // 如果没有正在进行中的专注，提示用户
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('没有正在进行中的专注')),
                        );
                      }
                    },
                  ),
                  
                  // 第三个按钮：新增习惯
                  StatisticsCardWidget(
                    icon: Icons.add,
                    title: '新增习惯',
                    onTap: () async {
                      final result = await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const AddHabitPage()),
                      );
                      if (result is Habit) {
                        setState(() {
                          _habits.add(result);
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // 习惯列表或空状态
        Expanded(
          child: Container(
            padding: HabitManagementPageConstants.contentPadding,
            child: _habits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: Duration(seconds: 1),
                          curve: Curves.bounceInOut,
                          child: Icon(
                            Icons.list,
                            size: HabitManagementPageConstants.emptyStateIconSize,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: ScreenUtil().setHeight(24)),
                        Text(
                          '还没有添加习惯',
                          style: ThemeHelper.textStyleWithTheme(
                            context,
                            fontSize: HabitManagementPageConstants.emptyStateTitleFontSize,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: HabitManagementPageConstants.mediumSpacing),
                        Text(
                          '点击右下角的+按钮开始添加',
                          style: ThemeHelper.textStyleWithTheme(
                            context,
                            fontSize: HabitManagementPageConstants.emptyStateSubtitleFontSize,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : AnimatedList(
                    key: _listKey,
                    initialItemCount: _habits.length,
                    padding: HabitManagementPageConstants.listPadding,
                    itemBuilder: (context, index, animation) {
                      final item = _habits[index];
                      return SizeTransition(
                        sizeFactor: animation,
                        child: HabitItemWidget(
                          key: ValueKey(item.id),
                          habit: item,
                          onDelete: _deleteHabit,
                          onRefresh: _refreshHabits,
                          onNavigateToTracking: _navigateToTrackingPage,
                          formatDescription: _formatHabitDescription,
                          getFinalProgress: _getFinalProgress,
                          isFirst: index == 0,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }









  // 刷新习惯列表
  void _refreshHabits() {
    setState(() {
      _loadHabits();
    });
    _resortWithAnimation();
  }

  void _resortWithAnimation() {
    if (_listKey.currentState == null) {
      return;
    }
    final target = List<Habit>.from(_habits)
      ..sort((a, b) => _getFinalProgress(a).compareTo(_getFinalProgress(b)));
    for (int i = 0; i < target.length; i++) {
      final h = target[i];
      final currentIndex = _habits.indexWhere((e) => e.id == h.id);
      if (currentIndex != i && currentIndex != -1) {
        final removed = _habits.removeAt(currentIndex);
        _listKey.currentState!.removeItem(
          currentIndex,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: HabitItemWidget(
              key: ValueKey(removed.id),
              habit: removed,
              onDelete: _deleteHabit,
              onRefresh: _refreshHabits,
              onNavigateToTracking: _navigateToTrackingPage,
              formatDescription: _formatHabitDescription,
              getFinalProgress: _getFinalProgress,
              isFirst: currentIndex == 0,
            ),
          ),
          duration: const Duration(milliseconds: 200),
        );
        _habits.insert(i, removed);
        _listKey.currentState!.insertItem(i, duration: const Duration(milliseconds: 200));
      }
    }
  }
}
