import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/features/profile/presentation/pages/theme_selection_page.dart';
import 'package:contrail/features/profile/presentation/pages/data_backup_page.dart';
import 'package:contrail/features/profile/presentation/pages/personalization_settings_page.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/features/profile/presentation/providers/profile_view_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: ThemeHelper.heroDecoration(context, radius: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    viewModel.recordDebugTap(context);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '我的',
                        style: ThemeHelper.textStyleWithTheme(
                          context,
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w800,
                          color: heroForeground,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '把主题、资料和备份统一收进控制中心',
                        style: ThemeHelper.textStyleWithTheme(
                          context,
                          fontSize: 15.sp,
                          color: ThemeHelper.visualTheme(
                            context,
                          ).heroSecondaryForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 14.sp,
                      color: heroForeground.withValues(alpha: 0.92),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '控制中心',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: heroForeground.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _buildHeaderShortcut(
                  icon: Icons.palette_outlined,
                  title: '主题',
                  subtitle: '切换风格',
                  onTap: _openThemeSelection,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildHeaderShortcut(
                  icon: Icons.tune_outlined,
                  title: '个性化',
                  subtitle: '偏好设置',
                  onTap: _openPersonalizationSettings,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildHeaderShortcut(
                  icon: Icons.cloud_outlined,
                  title: '备份',
                  subtitle: '数据管理',
                  onTap: _openBackupSettings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(ProfileViewModel viewModel) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildUserInfoCard(viewModel),
          _buildSettingsCard(viewModel),
          _buildClearDataCard(),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(ProfileViewModel viewModel) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      decoration: ThemeHelper.panelDecoration(context, radius: 24.w),
      padding: EdgeInsets.all(24.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(viewModel),
          SizedBox(width: 18.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '个人名片',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: ThemeHelper.primary(context),
                  ),
                ),
                SizedBox(height: 6.h),
                _buildAvatarHint(),
                SizedBox(height: 16.h),
                _buildUsernameField(viewModel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ProfileViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: 3,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: ThemeHelper.primary(context).withValues(alpha: 0.25),
            spreadRadius: 6,
            blurRadius: 12,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Semantics(
        label: '更换头像',
        button: true,
        child: Tooltip(
          message: '点击头像更换头像',
          child: GestureDetector(
            onTap: () => viewModel.pickImage(),
            child: CircleAvatar(
              radius: 60.w,
              backgroundImage:
                  viewModel.avatarPath != null &&
                      viewModel.avatarPath!.isNotEmpty
                  ? FileImage(File(viewModel.avatarPath!))
                  : null,
              backgroundColor: ThemeHelper.primary(
                context,
              ).withValues(alpha: 0.1),
              child:
                  (viewModel.avatarPath == null ||
                      viewModel.avatarPath!.isEmpty)
                  ? ThemeHelper.styledIcon(
                      context,
                      Icons.person,
                      size: 48.w,
                      color: ThemeHelper.primary(context),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarHint() {
    return Text(
      '点击头像即可更换展示形象',
      style: TextStyle(
        fontSize: 13.sp,
        color: ThemeHelper.onBackground(context).withValues(alpha: 0.64),
      ),
    );
  }

  Widget _buildUsernameField(ProfileViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeHelper.visualTheme(context).inputFillColor,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: ThemeHelper.visualTheme(context).panelBorderColor),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      child: TextFormField(
        initialValue: viewModel.username,
        textAlign: TextAlign.left,
        decoration: const InputDecoration(border: InputBorder.none),
        style: TextStyle(
          color: ThemeHelper.onBackground(context),
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
        onChanged: (value) {
          viewModel.updateUsername(value);
        },
        onEditingComplete: () {
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  Widget _buildSettingsCard(ProfileViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: ThemeHelper.panelDecoration(
        context,
        secondary: true,
        radius: 24.w,
      ),
      child: Column(
        children: [
          _buildThemeSetting(),
          _buildDivider(),
          _buildPersonalizationSetting(),
          _buildDivider(),
          _buildBackupSetting(),
          _buildDivider(),
          _buildAboutSetting(),
          if (viewModel.showDebugTab) ...[
            _buildDivider(),
            _buildDebugSetting(viewModel),
          ] else ...[
            _buildBottomRoundedContainer(),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeSetting() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.w),
          topRight: Radius.circular(20.w),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.color_lens, color: ThemeHelper.primary(context)),
        ),
        title: Text(
          '主题设置',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: ThemeHelper.onBackground(context),
          ),
        ),
        subtitle: Text(
          '选择应用的外观风格',
          style: TextStyle(
            fontSize: 14.sp,
            color: ThemeHelper.onBackground(context).withValues(alpha: 0.7),
          ),
        ),
        trailing: ThemeHelper.styledIcon(context, Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ThemeSelectionPage()),
          );
        },
      ),
    );
  }

  Widget _buildPersonalizationSetting() {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.tune, color: ThemeHelper.primary(context)),
      ),
      title: Text(
        '个性化设置',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w500,
          color: ThemeHelper.onBackground(context),
        ),
      ),
      subtitle: Text(
        '自定义应用的行为和显示方式',
        style: TextStyle(
          fontSize: 14.sp,
          color: ThemeHelper.onBackground(context).withValues(alpha: 0.7),
        ),
      ),
      trailing: ThemeHelper.styledIcon(context, Icons.arrow_forward_ios),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PersonalizationSettingsPage(),
          ),
        );
      },
    );
  }

  Widget _buildBackupSetting() {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.cloud_upload, color: ThemeHelper.primary(context)),
      ),
      title: Text(
        '数据备份',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w500,
          color: ThemeHelper.onBackground(context),
        ),
      ),
      subtitle: Text(
        '备份和恢复应用数据',
        style: TextStyle(
          fontSize: 14.sp,
          color: ThemeHelper.onBackground(context).withValues(alpha: 0.7),
        ),
      ),
      trailing: ThemeHelper.styledIcon(context, Icons.arrow_forward_ios),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DataBackupPage()),
        );
      },
    );
  }

  Widget _buildAboutSetting() {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.info_outline, color: ThemeHelper.primary(context)),
      ),
      title: Text(
        '关于',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w500,
          color: ThemeHelper.onBackground(context),
        ),
      ),
      onTap: () {
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
      },
    );
  }

  Widget _buildDebugSetting(ProfileViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.w),
          bottomRight: Radius.circular(20.w),
        ),
      ),
      child: ListTile(
        title: Text(
          'Debug工具',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            color: Colors.blue,
          ),
        ),
        trailing: ThemeHelper.styledIcon(context, Icons.arrow_forward_ios),
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
    );
  }

  Widget _buildBottomRoundedContainer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.w),
          bottomRight: Radius.circular(20.w),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1.h,
      color: ThemeHelper.onBackground(context).withValues(alpha: 0.1),
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
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
        subtitle: Text(
          '删除所有习惯和统计数据',
          style: TextStyle(
            fontSize: 16.sp,
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
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          '确定要删除所有习惯和统计数据吗？此操作不可撤销！',
          style: TextStyle(
            fontSize: 20.sp,
            color: ThemeHelper.onBackground(context),
          ),
        ),
        actions: [
          ElevatedButton(
            child: Text(
              '取消',
              style: TextStyle(
                fontSize: 20.sp,
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
              style: TextStyle(fontSize: 20.sp, color: Colors.white),
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
                      style: TextStyle(fontSize: 20.sp, color: Colors.white),
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '清空数据失败: $e',
                      style: TextStyle(fontSize: 20.sp, color: Colors.white),
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

  Widget _buildHeaderShortcut({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20.sp, color: heroForeground),
              SizedBox(height: 8.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: heroForeground,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: heroForeground.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
