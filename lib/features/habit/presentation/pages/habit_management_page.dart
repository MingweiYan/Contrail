import 'package:flutter/material.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
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
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/widgets/app_hero_header.dart';
import 'package:contrail/shared/widgets/scroll_to_top_fab.dart';

class HabitManagementPage extends StatefulWidget {
  const HabitManagementPage({super.key});

  @override
  State<HabitManagementPage> createState() => _HabitManagementPageState();
}

class _HabitManagementPageState extends State<HabitManagementPage> {
  late final UpdateHabitUseCase _updateHabitUseCase;
  late final HabitManagementService _habitManagementService;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _updateHabitUseCase = sl<UpdateHabitUseCase>();
    _habitManagementService = sl<HabitManagementService>();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 显示补充打卡对话框 - 使用独立组件
  void _showSupplementCheckInDialog(BuildContext context, List<Habit> habits) {
    SupplementCheckInDialog.show(
      context: context,
      habits: habits,
      updateHabitUseCase: _updateHabitUseCase,
      onRefresh: _refreshHabits,
    );
  }

  // 删除习惯
  Future<void> _deleteHabit(String habitId) async {
    final habitProvider = context.read<HabitProvider>();
    await habitProvider.deleteHabit(habitId);
    if (!mounted) {
      return;
    }

    final errorMessage = habitProvider.errorMessage;
    if (errorMessage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('习惯删除成功')));
    } else {
      logger.error(errorMessage);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
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

  Future<bool> _showRepeatCompletionConfirmation(Habit habit) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('今日已完成'),
          content: Text('「${habit.name}」今天已经完成过，再次继续会新增一条记录，是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('继续'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _completeCountOnlyHabit(Habit habit) async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final shouldContinue =
        !_habitManagementService.isTodayCompleted(habit) ||
        await _showRepeatCompletionConfirmation(habit);

    if (!shouldContinue) {
      return;
    }

    try {
      await habitProvider.stopTracking(habit.id, Duration(minutes: 1));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已完成 ${habit.name}')));
      await habitProvider.loadHabits();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('完成习惯失败: ${e.toString()}')));
    }
  }

  // 导航到追踪页面
  Future<void> _navigateToTrackingPage(Habit habit) async {
    // 检查是否有正在进行的专注会话
    final focusState = sl<FocusTrackingManager>();
    if (focusState.focusStatus != FocusStatus.stop &&
        focusState.currentFocusHabit != null) {
      // 如果正在专注的习惯与当前选择的习惯不同，显示提示
      if (focusState.currentFocusHabit!.id != habit.id) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已有专注正在进行中，请先结束当前专注')));
        return; // 不导航到新的专注页面
      }
    }

    // 如果习惯设置了追踪时间，则导航到专注页面
    if (habit.trackTime) {
      // 等待从专注页面返回，再从统一状态源重新加载数据。
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HabitTrackingPage(habit: habit),
        ),
      );
      if (mounted) {
        await context.read<HabitProvider>().loadHabits();
      }
    } else {
      await _completeCountOnlyHabit(habit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final habits = List<Habit>.from(habitProvider.habits)
      ..sort((a, b) => _getFinalProgress(a).compareTo(_getFinalProgress(b)));

    return Scaffold(
      floatingActionButton: ScrollToTopFab(controller: _scrollController),
      body: Container(
        decoration:
            ThemeHelper.generateBackgroundDecoration(context) ??
            BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor, // 与主题颜色联动
            ),
        child: _buildHabitList(habits, isLoading: habitProvider.isLoading),
      ),
    );
  }

  Widget _buildHabitList(List<Habit> habits, {required bool isLoading}) {
    final pagePadding = HeroHeaderPageConstants.mainPagePadding;
    final listPadding = HabitManagementPageConstants.listPadding;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: pagePadding,
          sliver: SliverToBoxAdapter(
            child: AppHeroHeader(
              title: '我的习惯',
              subtitle: '从新增一个习惯出发吧',
              badge: const AppHeroHeaderBadgeData(
                icon: Icons.dashboard_customize_outlined,
                label: '控制台',
              ),
              actions: [
                AppHeroHeaderActionData(
                  icon: Icons.edit_outlined,
                  title: '补充记录',
                  subtitle: 'Record',
                  onTap: () => _showSupplementCheckInDialog(context, habits),
                ),
                AppHeroHeaderActionData(
                  icon: Icons.timer_outlined,
                  title: '查看专注',
                  subtitle: 'Focus',
                  onTap: _openCurrentFocus,
                ),
                AppHeroHeaderActionData(
                  icon: Icons.add_rounded,
                  title: '新增习惯',
                  subtitle: 'Create',
                  onTap: _openAddHabit,
                ),
              ],
            ),
          ),
        ),
        if (isLoading && habits.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (habits.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pagePadding.left),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: Duration(seconds: 1),
                      curve: Curves.bounceInOut,
                      child: Icon(
                        Icons.list,
                        size: HabitManagementPageConstants.emptyStateIconSize,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: ScreenUtil().setHeight(24)),
                    Text(
                      '还没有添加习惯',
                      style: ThemeHelper.textStyleWithTheme(
                        context,
                        fontSize: HabitManagementPageConstants
                            .emptyStateTitleFontSize,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height: HabitManagementPageConstants.mediumSpacing,
                    ),
                    Text(
                      '点击右下角的+按钮开始添加',
                      style: ThemeHelper.textStyleWithTheme(
                        context,
                        fontSize: HabitManagementPageConstants
                            .emptyStateSubtitleFontSize,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              pagePadding.left,
              listPadding.top,
              pagePadding.right,
              listPadding.bottom,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = habits[index];
                return HabitItemWidget(
                  key: ValueKey(item.id),
                  habit: item,
                  onDelete: _deleteHabit,
                  onRefresh: _refreshHabits,
                  onNavigateToTracking: _navigateToTrackingPage,
                  formatDescription: _formatHabitDescription,
                  getFinalProgress: _getFinalProgress,
                  isFirst: index == 0,
                );
              }, childCount: habits.length),
            ),
          ),
      ],
    );
  }

  // 刷新习惯列表
  void _refreshHabits() {
    context.read<HabitProvider>().loadHabits();
  }

  Future<void> _openAddHabit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddHabitPage()),
    );
  }

  Future<void> _openCurrentFocus() async {
    final focusState = sl<FocusTrackingManager>();
    if (focusState.focusStatus != FocusStatus.stop &&
        focusState.currentFocusHabit != null) {
      final currentHabit = focusState.currentFocusHabit;
      if (currentHabit != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HabitTrackingPage(habit: currentHabit),
          ),
        );
        if (mounted) {
          await context.read<HabitProvider>().loadHabits();
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法获取专注信息')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('没有正在进行中的专注')));
    }
  }
}
