import 'package:contrail/features/profile/presentation/providers/backup_provider.dart';
import 'package:contrail/features/profile/presentation/providers/webdav_backup_provider.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AutoBackupPolicyPage extends StatelessWidget {
  const AutoBackupPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration:
            ThemeHelper.generateBackgroundDecoration(context) ??
            BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: SafeArea(
          child: Padding(
            padding: PageLayoutConstants.getPageContainerPadding(),
            child: Consumer<BackupProvider>(
              builder: (context, provider, _) {
                _showErrorIfNeeded(
                  context,
                  provider.errorMessage,
                  provider.clearError,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(
                      context,
                      title: '自动备份策略',
                      subtitle: '这是一套页面级公共配置，同时影响本地与 WebDAV 备份策略。',
                    ),
                    SizedBox(height: BaseLayoutConstants.spacingLarge),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: BaseLayoutConstants.spacingLarge,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          _buildSectionPanel(
                            context,
                            title: '当前状态',
                            subtitle: '统一查看自动备份是否开启、频率与最近执行情况。',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    _buildStatusPill(
                                      context,
                                      label: '自动备份',
                                      value: provider.autoBackupEnabled
                                          ? '已开启'
                                          : '未开启',
                                    ),
                                    _buildStatusPill(
                                      context,
                                      label: '频率',
                                      value: _frequencyLabel(
                                        provider.backupFrequency,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                _buildInfoRow(
                                  context,
                                  label: '最近备份',
                                  value: _formatDateTime(provider.lastBackupTime),
                                ),
                                _buildInfoRow(
                                  context,
                                  label: '最近检查',
                                  value: _formatDateTime(
                                    provider.autoBackupLastRun,
                                  ),
                                ),
                                if (provider.autoBackupEnabled)
                                  _buildInfoRow(
                                    context,
                                    label: '下次备份',
                                    value: provider.lastBackupTime != null
                                        ? _formatDateTime(
                                            provider.lastBackupTime!.add(
                                              Duration(
                                                days: provider.backupFrequency,
                                              ),
                                            ),
                                          )
                                        : '开启后立即执行第一次备份',
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: BaseLayoutConstants.spacingLarge),
                          _buildSectionPanel(
                            context,
                            title: '修改策略',
                            subtitle: '这里只维护全局自动备份开关与频率。',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '自动备份',
                                        style: TextStyle(
                                          fontSize:
                                              AppTypographyConstants.cardTitleFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: ThemeHelper.onBackground(context),
                                        ),
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: provider.autoBackupEnabled,
                                      onChanged: (value) async {
                                        await provider.saveAutoBackupSettings(
                                          value,
                                          provider.backupFrequency,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                _buildDropdownRow<int>(
                                  context,
                                  icon: Icons.repeat_rounded,
                                  label: '自动备份频率',
                                  value: provider.backupFrequency,
                                  items: const [
                                    DropdownMenuItem(value: 1, child: Text('每天')),
                                    DropdownMenuItem(
                                      value: 2,
                                      child: Text('每 2 天'),
                                    ),
                                    DropdownMenuItem(value: 7, child: Text('每周')),
                                    DropdownMenuItem(value: 30, child: Text('每月')),
                                  ],
                                  onChanged: (value) async {
                                    if (value == null) return;
                                    await provider.saveAutoBackupSettings(
                                      provider.autoBackupEnabled,
                                      value,
                                    );
                                  },
                                ),
                                if (provider.autoBackupLastError != null &&
                                    provider.autoBackupLastError!.isNotEmpty) ...[
                                  SizedBox(height: 16.h),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(14.w),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: Colors.red.withValues(alpha: 0.14),
                                      ),
                                    ),
                                    child: Text(
                                      '最近错误：${provider.autoBackupLastError!}',
                                      style: TextStyle(
                                        fontSize:
                                            AppTypographyConstants.formHelperFontSize,
                                        height: 1.45,
                                        color: Colors.red.withValues(alpha: 0.86),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class LocalBackupConfigPage extends StatelessWidget {
  const LocalBackupConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration:
            ThemeHelper.generateBackgroundDecoration(context) ??
            BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: SafeArea(
          child: Padding(
            padding: PageLayoutConstants.getPageContainerPadding(),
            child: Consumer<BackupProvider>(
              builder: (context, provider, _) {
                _showErrorIfNeeded(
                  context,
                  provider.errorMessage,
                  provider.clearError,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(
                      context,
                      title: '本地备份配置',
                      subtitle: '管理本地备份目录与本地保留策略。',
                    ),
                    SizedBox(height: BaseLayoutConstants.spacingLarge),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: BaseLayoutConstants.spacingLarge,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          _buildSectionPanel(
                            context,
                            title: '配置状态',
                            subtitle: '当前本地备份目录、文件库存与最近执行情况。',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    _buildStatusPill(
                                      context,
                                      label: '保留数量',
                                      value: '${provider.retentionCount} 份',
                                    ),
                                    _buildStatusPill(
                                      context,
                                      label: '本地文件',
                                      value: '${provider.backupFiles.length} 份',
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                _buildInfoRow(
                                  context,
                                  label: '最近备份',
                                  value: _formatDateTime(provider.lastBackupTime),
                                ),
                                _buildInfoRow(
                                  context,
                                  label: '备份目录',
                                  value: provider.localBackupPath,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: BaseLayoutConstants.spacingLarge),
                          _buildSectionPanel(
                            context,
                            title: '修改配置',
                            subtitle: '这里只维护本地目录与本地保留数量。',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDropdownRow<int>(
                                  context,
                                  icon: Icons.inventory_2_outlined,
                                  label: '本地保留数量',
                                  value: provider.retentionCount,
                                  items: const [
                                    DropdownMenuItem(value: 3, child: Text('3')),
                                    DropdownMenuItem(value: 5, child: Text('5')),
                                    DropdownMenuItem(value: 10, child: Text('10')),
                                    DropdownMenuItem(value: 20, child: Text('20')),
                                    DropdownMenuItem(value: 50, child: Text('50')),
                                  ],
                                  onChanged: (value) async {
                                    if (value == null) return;
                                    await provider.saveRetentionCount(value);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '保留数量已设置为 ${provider.retentionCount}',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 16.h),
                                _buildPathPanel(
                                  context,
                                  title: '备份目录',
                                  path: provider.localBackupPath,
                                  primaryActionLabel: '更换目录',
                                  secondaryActionLabel: '默认目录',
                                  onPrimaryTap: () async {
                                    await provider.changeBackupPath();
                                    if (!context.mounted ||
                                        provider.errorMessage != null) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '备份路径已更改为 ${provider.localBackupPath}',
                                        ),
                                      ),
                                    );
                                  },
                                  onSecondaryTap: () async {
                                    await provider.resetBackupPathToDefault();
                                    if (!context.mounted ||
                                        provider.errorMessage != null) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('已回退到默认备份目录'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class WebDavBackupConfigPage extends StatefulWidget {
  const WebDavBackupConfigPage({super.key});

  @override
  State<WebDavBackupConfigPage> createState() => _WebDavBackupConfigPageState();
}

class _WebDavBackupConfigPageState extends State<WebDavBackupConfigPage> {
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _pathController;
  late int _retentionCount;

  @override
  void initState() {
    super.initState();
    final provider = context.read<WebDavBackupProvider>();
    _urlController = TextEditingController(text: provider.webdavUrl);
    _usernameController = TextEditingController(text: provider.webdavUsername);
    _passwordController = TextEditingController(text: provider.webdavPassword);
    _pathController = TextEditingController(text: provider.webdavPath);
    _retentionCount = provider.retentionCount;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final provider = context.read<WebDavBackupProvider>();
    provider.setWebDavUrl(_urlController.text.trim());
    provider.setWebDavUsername(_usernameController.text.trim());
    provider.setWebDavPassword(_passwordController.text);
    provider.setWebDavPath(_pathController.text.trim());
    await provider.saveRetentionCount(_retentionCount);
    await provider.saveWebDavConfig();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('WebDAV 配置已保存')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration:
            ThemeHelper.generateBackgroundDecoration(context) ??
            BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: SafeArea(
          child: Padding(
            padding: PageLayoutConstants.getPageContainerPadding(),
            child: Consumer<WebDavBackupProvider>(
              builder: (context, provider, _) {
                _showErrorIfNeeded(
                  context,
                  provider.errorMessage,
                  provider.clearError,
                );
                final configured =
                    provider.webdavUrl.trim().isNotEmpty &&
                    provider.webdavUsername.trim().isNotEmpty &&
                    provider.webdavPath.trim().isNotEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(
                      context,
                      title: 'WebDAV 配置',
                      subtitle: '管理远端地址、账号、路径与保留策略。',
                    ),
                    SizedBox(height: BaseLayoutConstants.spacingLarge),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: BaseLayoutConstants.spacingLarge,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          _buildSectionPanel(
                            context,
                            title: '配置状态',
                            subtitle: '确认配置是否完整，再执行网络备份。',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    _buildStatusPill(
                                      context,
                                      label: '配置状态',
                                      value: configured ? '已就绪' : '待配置',
                                    ),
                                    _buildStatusPill(
                                      context,
                                      label: '远端文件',
                                      value: '${provider.backupFiles.length} 份',
                                    ),
                                    _buildStatusPill(
                                      context,
                                      label: '保留数量',
                                      value: '${provider.retentionCount} 份',
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                _buildInfoRow(
                                  context,
                                  label: '最近备份',
                                  value: _formatDateTime(provider.lastBackupTime),
                                ),
                                _buildInfoRow(
                                  context,
                                  label: '当前地址',
                                  value: provider.webdavUrl.isEmpty
                                      ? '未填写 WebDAV URL'
                                      : provider.webdavUrl,
                                ),
                                _buildInfoRow(
                                  context,
                                  label: '远端目录',
                                  value: provider.displayPath.isEmpty
                                      ? '尚未创建远端目录'
                                      : provider.displayPath,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: BaseLayoutConstants.spacingLarge),
                          _buildSectionPanel(
                            context,
                            title: '修改配置',
                            subtitle: '保存后会立即刷新远端文件列表。',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldCard(
                                  context,
                                  icon: Icons.link_rounded,
                                  title: 'WebDAV URL',
                                  child: TextField(
                                    controller: _urlController,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'https://example.com/dav',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                _buildFieldCard(
                                  context,
                                  icon: Icons.person_outline_rounded,
                                  title: '账号',
                                  child: TextField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '输入 WebDAV 账号',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                _buildFieldCard(
                                  context,
                                  icon: Icons.lock_outline_rounded,
                                  title: '密码',
                                  child: TextField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '输入 WebDAV 密码',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                _buildFieldCard(
                                  context,
                                  icon: Icons.folder_copy_outlined,
                                  title: '保存路径',
                                  child: TextField(
                                    controller: _pathController,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Contrail',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                _buildDropdownRow<int>(
                                  context,
                                  icon: Icons.inventory_2_outlined,
                                  label: '远端保留数量',
                                  value: _retentionCount,
                                  items: const [
                                    DropdownMenuItem(value: 3, child: Text('3')),
                                    DropdownMenuItem(value: 5, child: Text('5')),
                                    DropdownMenuItem(value: 10, child: Text('10')),
                                    DropdownMenuItem(value: 20, child: Text('20')),
                                    DropdownMenuItem(value: 50, child: Text('50')),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _retentionCount = value;
                                    });
                                  },
                                ),
                                SizedBox(height: 16.h),
                                ElevatedButton.icon(
                                  onPressed: _saveConfig,
                                  icon: const Icon(Icons.save_outlined),
                                  label: Text(
                                    '保存配置',
                                    style: TextStyle(
                                      fontSize:
                                          AppTypographyConstants.buttonLabelFontSize,
                                    ),
                                  ),
                                  style: ThemeHelper.elevatedButtonStyle(
                                    context,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 14.h,
                                    ),
                                    backgroundColor: ThemeHelper.primary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildHeader(
  BuildContext context, {
  required String title,
  required String subtitle,
}) {
  final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
  final heroSecondary = ThemeHelper.visualTheme(context).heroSecondaryForeground;
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    decoration: ThemeHelper.heroDecoration(context, radius: 28),
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        _buildHeaderButton(context),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTypographyConstants.secondaryHeroTitleFontSize,
                  fontWeight: FontWeight.w800,
                  color: heroForeground,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize:
                      AppTypographyConstants.secondaryHeroSubtitleFontSize,
                  height: 1.5,
                  color: heroSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildHeaderButton(BuildContext context) {
  final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(16.r),
      child: Ink(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_rounded,
              size: 18.sp,
              color: heroForeground,
            ),
            SizedBox(width: 6.w),
            Text(
              '返回',
              style: TextStyle(
                fontSize: AppTypographyConstants.secondaryHeroButtonFontSize,
                fontWeight: FontWeight.w700,
                color: heroForeground,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSectionPanel(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Widget child,
}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(18.w),
    decoration: ThemeHelper.panelDecoration(context, radius: 24.r),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTypographyConstants.panelTitleFontSize,
            fontWeight: FontWeight.w800,
            color: ThemeHelper.onBackground(context),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: AppTypographyConstants.panelSubtitleFontSize,
            height: 1.4,
            color: ThemeHelper.onBackground(context).withValues(alpha: 0.62),
          ),
        ),
        SizedBox(height: 18.h),
        child,
      ],
    ),
  );
}

Widget _buildStatusPill(
  BuildContext context, {
  required String label,
  required String value,
}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
    decoration: BoxDecoration(
      color: ThemeHelper.primary(context).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(
        color: ThemeHelper.primary(context).withValues(alpha: 0.12),
      ),
    ),
    child: RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: AppTypographyConstants.cardSubtitleFontSize,
          color: ThemeHelper.onBackground(context),
        ),
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: ThemeHelper.onBackground(context).withValues(alpha: 0.6),
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

Widget _buildInfoRow(
  BuildContext context, {
  required String label,
  required String value,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypographyConstants.cardSubtitleFontSize,
              fontWeight: FontWeight.w600,
              color: ThemeHelper.onBackground(context).withValues(alpha: 0.58),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value,
          style: TextStyle(
            fontSize: AppTypographyConstants.cardSubtitleFontSize,
            height: 1.4,
            color: ThemeHelper.onBackground(context).withValues(alpha: 0.84),
          ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDropdownRow<T>(
  BuildContext context, {
  required IconData icon,
  required String label,
  required T value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(18.r),
      border: Border.all(
        color: ThemeHelper.onBackground(context).withValues(alpha: 0.08),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18.sp, color: ThemeHelper.primary(context)),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypographyConstants.formLabelFontSize,
              fontWeight: FontWeight.w600,
              color: ThemeHelper.onBackground(context),
            ),
          ),
        ),
        DropdownButton<T>(
          value: value,
          items: items,
          underline: const SizedBox.shrink(),
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

Widget _buildPathPanel(
  BuildContext context, {
  required String title,
  required String path,
  required String primaryActionLabel,
  required String secondaryActionLabel,
  required VoidCallback onPrimaryTap,
  required VoidCallback onSecondaryTap,
}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(14.w),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(18.r),
      border: Border.all(
        color: ThemeHelper.onBackground(context).withValues(alpha: 0.08),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTypographyConstants.formLabelFontSize,
            fontWeight: FontWeight.w700,
            color: ThemeHelper.onBackground(context),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          path,
          style: TextStyle(
            fontSize: AppTypographyConstants.formHelperFontSize,
            height: 1.45,
            color: ThemeHelper.onBackground(context).withValues(alpha: 0.68),
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildSecondaryAction(
              context,
              icon: Icons.drive_file_move_outline,
              label: primaryActionLabel,
              onTap: onPrimaryTap,
            ),
            _buildSecondaryAction(
              context,
              icon: Icons.settings_backup_restore_rounded,
              label: secondaryActionLabel,
              onTap: onSecondaryTap,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildFieldCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required Widget child,
}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(18.r),
      border: Border.all(
        color: ThemeHelper.onBackground(context).withValues(alpha: 0.08),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Icon(icon, size: 18.sp, color: ThemeHelper.primary(context)),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTypographyConstants.formFieldTitleFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4.h),
              child,
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildSecondaryAction(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 17.sp),
    label: Text(
      label,
      style: TextStyle(
        fontSize: AppTypographyConstants.buttonSecondaryLabelFontSize,
      ),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: ThemeHelper.onBackground(context),
      side: BorderSide(
        color: ThemeHelper.onBackground(context).withValues(alpha: 0.12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
    ),
  );
}

void _showErrorIfNeeded(
  BuildContext context,
  String? message,
  VoidCallback onClear,
) {
  if (message == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    onClear();
  });
}

String _frequencyLabel(int frequency) {
  switch (frequency) {
    case 1:
      return '每天';
    case 2:
      return '每 2 天';
    case 7:
      return '每周';
    case 30:
      return '每月';
    default:
      return '每 $frequency 天';
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '暂无记录';
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}
