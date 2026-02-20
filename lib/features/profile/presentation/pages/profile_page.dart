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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.all(Radius.circular(24.w)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              viewModel.recordDebugTap(context);
            },
            child: Text(
              '我的',
              style: ThemeHelper.textStyleWithTheme(
                context,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.onPrimary(context),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '设置中心',
            style: ThemeHelper.textStyleWithTheme(
              context,
              fontSize: 16.sp,
              color: ThemeHelper.onPrimary(context).withOpacity(0.9),
            ),
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
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          _buildAvatar(viewModel),
          SizedBox(height: 8.h),
          _buildAvatarHint(),
          SizedBox(height: 16.h),
          _buildUsernameField(viewModel),
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
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: ThemeHelper.primary(context).withOpacity(0.25),
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
              backgroundColor: ThemeHelper.primary(context).withOpacity(0.1),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline,
          size: 16.sp,
          color: ThemeHelper.onBackground(context).withOpacity(0.6),
        ),
        SizedBox(width: 6.w),
        Text(
          '点击头像更换头像',
          style: TextStyle(
            fontSize: 14.sp,
            color: ThemeHelper.onBackground(context).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField(ProfileViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.w),
      ),
      padding: EdgeInsets.all(12.w),
      child: TextFormField(
        initialValue: viewModel.username,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(border: InputBorder.none),
        style: TextStyle(
          color: ThemeHelper.onBackground(context),
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
            color: ThemeHelper.onBackground(context).withOpacity(0.7),
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
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
          color: ThemeHelper.onBackground(context).withOpacity(0.7),
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
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
          color: ThemeHelper.onBackground(context).withOpacity(0.7),
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
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
      color: ThemeHelper.onBackground(context).withOpacity(0.1),
    );
  }

  Widget _buildClearDataCard() {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
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
          style: TextStyle(fontSize: 16.sp, color: Colors.red.withOpacity(0.7)),
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
              backgroundColor: ThemeHelper.primary(context).withOpacity(0.8),
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
}
