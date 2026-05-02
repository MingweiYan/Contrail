import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/features/profile/presentation/pages/theme_selection_page.dart';
import 'package:contrail/features/profile/presentation/pages/data_backup_page.dart';
import 'package:contrail/features/profile/presentation/pages/personalization_settings_page.dart';
import 'package:contrail/features/profile/presentation/providers/backup_provider.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/features/profile/presentation/providers/profile_view_model.dart';
import 'package:contrail/shared/widgets/app_hero_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackupProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel(
        userSettingsService: Provider.of(context, listen: false),
        debugMenuManager: Provider.of(context, listen: false),
      ),
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            body: Container(
              decoration:
                  ThemeHelper.generateBackgroundDecoration(context) ??
                  BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
              padding: PageLayoutConstants.getPageContainerPadding(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(viewModel),
                  _buildProfileContent(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ProfileViewModel viewModel) {
    return AppHeroHeader(
      title: '我的',
      subtitle: '把握当前的状态才能更好的前进',
      badge: const AppHeroHeaderBadgeData(
        icon: Icons.tune_rounded,
        label: '控制中心',
      ),
      onTitleTap: () {
        viewModel.recordDebugTap(context);
      },
      actions: [
        AppHeroHeaderActionData(
          icon: Icons.palette_outlined,
          title: '主题',
          subtitle: 'Theme',
          onTap: _openThemeSelection,
        ),
        AppHeroHeaderActionData(
          icon: Icons.tune_outlined,
          title: '个性化',
          subtitle: 'Personal',
          onTap: _openPersonalizationSettings,
        ),
        AppHeroHeaderActionData(
          icon: Icons.cloud_outlined,
          title: '备份',
          subtitle: 'Backup',
          onTap: _openBackupSettings,
        ),
      ],
    );
  }

  Widget _buildProfileContent(ProfileViewModel viewModel) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildWeeklyOverviewCard(topMargin: 16.h),
          _buildSystemStatusCard(viewModel),
          _buildClearDataCard(),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard(ProfileViewModel viewModel) {
    final themeName = ThemeHelper.currentTheme(context).name;
    final backupProvider = context.watch<BackupProvider>();
    final lastBackupText = backupProvider.lastBackupTime != null
        ? _formatDateTime(backupProvider.lastBackupTime!)
        : '暂未检测到备份记录';
    final backupBadge = backupProvider.lastBackupTime != null ? '最近备份' : '未备份';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: ThemeHelper.panelDecoration(
        context,
        secondary: true,
        radius: 24.w,
      ),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '系统状态',
            style: TextStyle(
              fontSize: AppTypographyConstants.sectionTitleFontSize,
              fontWeight: FontWeight.w800,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '知彼知己百战不殆',
            style: TextStyle(
              fontSize: AppTypographyConstants.sectionSubtitleFontSize,
              color: ThemeHelper.onBackground(context).withValues(alpha: 0.62),
            ),
          ),
          SizedBox(height: 16.h),
          _buildStatusRow(
            icon: Icons.palette_outlined,
            title: '主题风格',
            subtitle: '当前主题：$themeName',
            badge: '已启用',
            onTap: _openThemeSelection,
          ),
          SizedBox(height: 10.h),
          _buildStatusRow(
            icon: Icons.cloud_done_outlined,
            title: '数据备份',
            subtitle: '最近一次备份：$lastBackupText',
            badge: backupBadge,
            onTap: _openBackupSettings,
          ),
          SizedBox(height: 10.h),
          _buildStatusRow(
            icon: Icons.info_outline_rounded,
            title: '应用信息',
            subtitle: 'Contrail--- A Habit Recorder',
            badge: '关于',
            onTap: _showAboutDialog,
          ),
          if (viewModel.showDebugTab) ...[
            SizedBox(height: 10.h),
            _buildStatusRow(
              icon: Icons.developer_mode_rounded,
              title: 'Debug 工具',
              subtitle: '调试页已就绪，点击查看内部工具',
              badge: '开发',
              onTap: () {
                final debugTab = viewModel.buildDebugTab(context);
                if (debugTab != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => debugTab),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: ThemeHelper.visualTheme(context).panelColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: ThemeHelper.visualTheme(context).panelBorderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: ThemeHelper.primary(context), size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTypographyConstants.cardTitleFontSize,
                    fontWeight: FontWeight.w700,
                    color: ThemeHelper.onBackground(context),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppTypographyConstants.cardSubtitleFontSize,
                    height: 1.35,
                    color: ThemeHelper.onBackground(context).withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: AppTypographyConstants.cardBadgeFontSize,
                fontWeight: FontWeight.w700,
                color: ThemeHelper.primary(context),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: content,
      ),
    );
  }

  Widget _buildWeeklyOverviewCard({double? topMargin}) {
    final habits = context.watch<HabitProvider>().habits;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    int weeklyCompletions = 0;
    int weeklyMinutes = 0;

    for (final habit in habits) {
      weeklyCompletions += habit.dailyCompletionStatus.entries
          .where(
            (entry) =>
                entry.value &&
                !entry.key.isBefore(weekStart) &&
                entry.key.isBefore(weekEnd),
          )
          .length;

      for (final entry in habit.trackingDurations.entries) {
        if (!entry.key.isBefore(weekStart) && entry.key.isBefore(weekEnd)) {
          weeklyMinutes += entry.value.fold(
            0,
            (sum, duration) => sum + duration.inMinutes,
          );
        }
      }
    }

    final completedToday = habits.where((habit) {
      return habit.dailyCompletionStatus.entries.any(
        (entry) =>
            entry.value &&
            entry.key.year == today.year &&
            entry.key.month == today.month &&
            entry.key.day == today.day,
      );
    }).length;

    final minutesText = weeklyMinutes >= 60
        ? '${weeklyMinutes ~/ 60}h ${weeklyMinutes % 60}m'
        : '$weeklyMinutes min';

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, topMargin ?? 0, 16.w, 12.h),
      decoration: ThemeHelper.panelDecoration(
        context,
        secondary: true,
        radius: 24.w,
      ),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本周总览',
            style: TextStyle(
              fontSize: AppTypographyConstants.sectionTitleFontSize,
              fontWeight: FontWeight.w800,
              color: ThemeHelper.onBackground(context),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '快速查看这周的活跃情况与专注表现',
            style: TextStyle(
              fontSize: AppTypographyConstants.sectionSubtitleFontSize,
              color: ThemeHelper.onBackground(context).withValues(alpha: 0.62),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildWeeklyMetric(
                  label: '活跃习惯',
                  value: '${habits.length}',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildWeeklyMetric(
                  label: '完成记录',
                  value: '$weeklyCompletions',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildWeeklyMetric(
                  label: '专注时长',
                  value: minutesText,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: ThemeHelper.visualTheme(context).panelColor,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: ThemeHelper.visualTheme(context).panelBorderColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: ThemeHelper.primary(context),
                  size: 18.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    '今天已完成 $completedToday / ${habits.length} 个习惯',
                    style: TextStyle(
                      fontSize: AppTypographyConstants.sectionSubtitleFontSize,
                      fontWeight: FontWeight.w700,
                      color: ThemeHelper.onBackground(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyMetric({
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: ThemeHelper.visualTheme(context).panelColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: ThemeHelper.visualTheme(context).panelBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypographyConstants.cardBadgeFontSize,
              fontWeight: FontWeight.w600,
              color: ThemeHelper.onBackground(context).withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypographyConstants.cardMetricValueFontSize,
              fontWeight: FontWeight.w800,
              color: ThemeHelper.onBackground(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearDataCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: ThemeHelper.panelDecoration(
        context,
        secondary: true,
        radius: 24.w,
      ),
      child: ListTile(
        title: Text(
          '清空数据',
          style: TextStyle(
            fontSize: AppTypographyConstants.sectionTitleFontSize,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
        subtitle: Text(
          '删除所有习惯和统计数据',
          style: TextStyle(
            fontSize: AppTypographyConstants.dialogBodyFontSize,
            color: Colors.red.withValues(alpha: 0.7),
          ),
        ),
        onTap: () {
          _showClearDataDialog();
        },
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          '警告',
          style: TextStyle(
            fontSize: AppTypographyConstants.dialogTitleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          '确定要删除所有习惯和统计数据吗？此操作不可撤销！',
          style: TextStyle(
            fontSize: AppTypographyConstants.dialogBodyFontSize,
            color: ThemeHelper.onBackground(context),
          ),
        ),
        actions: [
          ElevatedButton(
            child: Text(
              '取消',
              style: TextStyle(
                fontSize: AppTypographyConstants.dialogActionFontSize,
                color: ThemeHelper.onPrimary(context),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeHelper.primary(
                context,
              ).withValues(alpha: 0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.w),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text(
              '确认',
              style: TextStyle(
                fontSize: AppTypographyConstants.dialogActionFontSize,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.w),
              ),
            ),
            onPressed: () async {
              try {
                await Hive.box<Habit>('habits').clear();

                final habitProvider = Provider.of<HabitProvider>(
                  context,
                  listen: false,
                );
                await habitProvider.loadHabits();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '所有数据已清空',
                      style: TextStyle(
                        fontSize: AppTypographyConstants.snackbarFontSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '清空数据失败: $e',
                      style: TextStyle(
                        fontSize: AppTypographyConstants.snackbarFontSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _openThemeSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ThemeSelectionPage()),
    );
  }

  void _openPersonalizationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonalizationSettingsPage(),
      ),
    );
  }

  void _openBackupSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DataBackupPage()),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationIcon: Icon(
        Icons.info_outline,
        color: ThemeHelper.primary(context),
        size: 28.sp,
      ),
      applicationName: 'Contrail',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 吃葡萄不吃葡萄皮. 保留所有权利.',
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }

}
