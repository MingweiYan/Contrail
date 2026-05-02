import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/profile/domain/services/webdav_backup_service.dart';
import 'package:contrail/features/profile/domain/services/webdav_storage_service.dart';
import 'package:contrail/features/profile/presentation/pages/backup_config_page.dart';
import 'package:contrail/features/profile/presentation/providers/backup_provider.dart';
import 'package:contrail/features/profile/presentation/providers/webdav_backup_provider.dart';
import 'package:contrail/features/profile/presentation/widgets/backup/backup_list_section.dart';
import 'package:contrail/features/profile/presentation/widgets/backup_restore_confirmation_dialog.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackupProvider>().initialize();
    });
    WidgetsBinding.instance.addObserver(this);
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
      context.read<BackupProvider>().refreshBackupFiles();
    }
  }

  void _showErrorIfNeeded(
    BuildContext context,
    String? message,
    VoidCallback onClear,
  ) {
    if (message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      onClear();
    });
  }

  Future<void> _showRestoreConfirmation(BackupFileInfo backupFile) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => BackupRestoreConfirmationDialog(
        backupFile: backupFile,
        onCancel: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          Navigator.pop(dialogContext);
          final backupProvider = context.read<BackupProvider>();
          final success = await backupProvider.restoreFromBackup(
            backupFile,
            context,
          );
          if (!mounted) return;

          if (success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('从本地备份恢复成功')));
            Navigator.pop(context);
          } else if (backupProvider.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(backupProvider.errorMessage!)));
            backupProvider.clearError();
          }
        },
      ),
    );
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
            child: Consumer<BackupProvider>(
              builder: (context, backupProvider, _) {
                _showErrorIfNeeded(
                  context,
                  backupProvider.errorMessage,
                  backupProvider.clearError,
                );

                return ChangeNotifierProvider<WebDavBackupProvider>(
                  create: (_) => WebDavBackupProvider(
                    WebDavBackupService(storageService: WebDavStorageService()),
                  )..initialize(),
                  child: Consumer<WebDavBackupProvider>(
                    builder: (context, webdavProvider, _) {
                      _showErrorIfNeeded(
                        context,
                        webdavProvider.errorMessage,
                        webdavProvider.clearError,
                      );

                      return DefaultTabController(
                        length: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroHeader(context),
                            SizedBox(height: BaseLayoutConstants.spacingLarge),
                            _buildConfigStatusCard(
                              context,
                              icon: Icons.schedule_rounded,
                              title: '自动备份策略',
                              subtitle: '页面级公共配置，统一影响本地与 WebDAV',
                              statusItems: [
                                _StatusItem(
                                  label: '自动备份',
                                  value: backupProvider.autoBackupEnabled
                                      ? '已开启'
                                      : '未开启',
                                ),
                                _StatusItem(
                                  label: '频率',
                                  value: _frequencyLabel(
                                    backupProvider.backupFrequency,
                                  ),
                                ),
                              ],
                              detailItems: [
                                _DetailItem(
                                  label: '最近备份',
                                  value: _formatDateTime(
                                    backupProvider.lastBackupTime,
                                  ),
                                ),
                                _DetailItem(
                                  label: '最近检查',
                                  value: _formatDateTime(
                                    backupProvider.autoBackupLastRun,
                                  ),
                                ),
                              ],
                              onTap: () => _openAutoBackupPolicyPage(
                                context,
                                backupProvider,
                              ),
                            ),
                            SizedBox(height: BaseLayoutConstants.spacingLarge),
                            _buildTabShell(context),
                            SizedBox(height: BaseLayoutConstants.spacingMedium),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  SingleChildScrollView(
                                    padding: EdgeInsets.only(
                                      bottom: BaseLayoutConstants.spacingLarge,
                                    ),
                                    child: _buildLocalTab(
                                      context,
                                      backupProvider,
                                    ),
                                  ),
                                  SingleChildScrollView(
                                    padding: EdgeInsets.only(
                                      bottom: BaseLayoutConstants.spacingLarge,
                                    ),
                                    child: _buildWebDavTab(
                                      context,
                                      webdavProvider,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
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
                  '数据备份与恢复',
                  style: TextStyle(
                    fontSize: AppTypographyConstants.secondaryHeroTitleFontSize,
                    fontWeight: FontWeight.w800,
                    color: heroForeground,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '分别在本地与 WebDAV 子页管理配置、查看状态，并处理备份文件。',
                  style: TextStyle(
                    fontSize:
                        AppTypographyConstants.secondaryHeroSubtitleFontSize,
                    color: heroSecondary,
                    height: 1.5,
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

  Widget _buildTabShell(BuildContext context) {
    final primary = ThemeHelper.primary(context);
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: ThemeHelper.panelDecoration(context, radius: 22.r),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: ThemeHelper.onBackground(
          context,
        ).withValues(alpha: 0.7),
        labelStyle: TextStyle(
          fontSize: AppTypographyConstants.buttonLabelFontSize,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: AppTypographyConstants.buttonLabelFontSize,
          fontWeight: FontWeight.w600,
        ),
        indicator: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(16.r),
        ),
        tabs: const [
          Tab(text: '本地'),
          Tab(text: 'WebDAV'),
        ],
      ),
    );
  }

  Widget _buildLocalTab(BuildContext context, BackupProvider backupProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConfigStatusCard(
          context,
          icon: Icons.folder_open_rounded,
          title: '本地配置与状态',
          subtitle: '点击进入本地备份配置页面',
          statusItems: [
            _StatusItem(
              label: '保留数量',
              value: '${backupProvider.retentionCount} 份',
            ),
            _StatusItem(
              label: '本地文件',
              value: '${backupProvider.backupFiles.length} 份',
            ),
          ],
          detailItems: [
            _DetailItem(
              label: '最近备份',
              value: _formatDateTime(backupProvider.lastBackupTime),
            ),
            _DetailItem(
              label: '备份目录',
              value: backupProvider.localBackupPath,
            ),
          ],
          onTap: () => _openLocalConfigPage(context, backupProvider),
        ),
        SizedBox(height: BaseLayoutConstants.spacingLarge),
        BackupListSection(
          title: '本地备份文件',
          caption: '恢复会覆盖当前数据，左滑可删除。',
          primaryActionLabel: '立即备份',
          primaryActionIcon: Icons.save_alt_rounded,
          onPrimaryAction: () async {
            final success = await backupProvider.performBackup();
            if (!mounted || !success) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('本地备份成功')));
          },
          secondaryActionLabel: '刷新列表',
          secondaryActionIcon: Icons.refresh_rounded,
          onSecondaryAction: backupProvider.refreshBackupFiles,
          isLoading: backupProvider.isLoading,
          files: backupProvider.backupFiles,
          onRefresh: backupProvider.refreshBackupFiles,
          onRestore: _showRestoreConfirmation,
          onDelete: (file) => _deleteLocalBackupFile(context, file),
        ),
      ],
    );
  }

  Widget _buildWebDavTab(
    BuildContext context,
    WebDavBackupProvider webdavProvider,
  ) {
    final configured = _isWebDavConfigured(webdavProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConfigStatusCard(
          context,
          icon: Icons.cloud_sync_rounded,
          title: 'WebDAV 配置与状态',
          subtitle: '点击进入 WebDAV 配置页面',
          statusItems: [
            _StatusItem(label: '配置状态', value: configured ? '已就绪' : '待配置'),
            _StatusItem(
              label: '远端文件',
              value: '${webdavProvider.backupFiles.length} 份',
            ),
            _StatusItem(
              label: '保留数量',
              value: '${webdavProvider.retentionCount} 份',
            ),
          ],
          detailItems: [
            _DetailItem(
              label: '最近备份',
              value: _formatDateTime(webdavProvider.lastBackupTime),
            ),
            _DetailItem(
              label: '当前地址',
              value: webdavProvider.webdavUrl.isEmpty
                  ? '未填写 WebDAV URL'
                  : webdavProvider.webdavUrl,
            ),
            _DetailItem(
              label: '远端目录',
              value: webdavProvider.displayPath.isEmpty
                  ? '尚未创建远端目录'
                  : webdavProvider.displayPath,
            ),
          ],
          onTap: () => _openWebDavConfigPage(context, webdavProvider),
        ),
        SizedBox(height: BaseLayoutConstants.spacingLarge),
        BackupListSection(
          title: 'WebDAV 文件列表',
          caption: '远端文件同样支持恢复与左滑删除。',
          primaryActionLabel: '立即备份',
          primaryActionIcon: Icons.cloud_upload_outlined,
          onPrimaryAction: () async {
            final success = await webdavProvider.performBackup();
            if (!mounted || !success) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('网络备份成功')));
          },
          secondaryActionLabel: '刷新列表',
          secondaryActionIcon: Icons.refresh_rounded,
          onSecondaryAction: webdavProvider.refreshBackupFiles,
          isLoading: webdavProvider.isLoading,
          files: webdavProvider.backupFiles,
          onRefresh: webdavProvider.refreshBackupFiles,
          onRestore: (file) => _restoreWebDavBackup(context, webdavProvider, file),
          onDelete: (file) => _deleteWebDavBackup(context, webdavProvider, file),
        ),
      ],
    );
  }

  Widget _buildConfigStatusCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<_StatusItem> statusItems,
    required List<_DetailItem> detailItems,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.all(18.w),
          decoration: ThemeHelper.panelDecoration(context, radius: 24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: ThemeHelper.primary(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      icon,
                      size: 20.sp,
                      color: ThemeHelper.primary(context),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
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
                            color: ThemeHelper.onBackground(
                              context,
                            ).withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22.sp,
                    color: ThemeHelper.onBackground(
                      context,
                    ).withValues(alpha: 0.42),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: statusItems
                    .map(
                      (item) => _buildStatusPill(
                        context,
                        label: item.label,
                        value: item.value,
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: 16.h),
              ...detailItems.map(
                (item) => _buildInfoRow(
                  context,
                  label: item.label,
                  value: item.value,
                ),
              ),
            ],
          ),
        ),
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
                color: ThemeHelper.onBackground(
                  context,
                ).withValues(alpha: 0.6),
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

  Future<void> _openLocalConfigPage(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: backupProvider,
          child: const LocalBackupConfigPage(),
        ),
      ),
    );
  }

  Future<void> _openAutoBackupPolicyPage(
    BuildContext context,
    BackupProvider backupProvider,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: backupProvider,
          child: const AutoBackupPolicyPage(),
        ),
      ),
    );
  }

  Future<void> _openWebDavConfigPage(
    BuildContext context,
    WebDavBackupProvider webdavProvider,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: webdavProvider,
          child: const WebDavBackupConfigPage(),
        ),
      ),
    );
  }

  Future<bool> _deleteLocalBackupFile(
    BuildContext context,
    BackupFileInfo backupFile,
  ) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除备份文件 "${backupFile.name}" 吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return false;
    final backupProvider = context.read<BackupProvider>();
    final success = await backupProvider.deleteBackupFile(backupFile);
    if (!mounted) return false;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('备份文件已删除')));
    } else if (backupProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(backupProvider.errorMessage!)));
      backupProvider.clearError();
    }
    return success;
  }

  Future<void> _restoreWebDavBackup(
    BuildContext context,
    WebDavBackupProvider webdavProvider,
    BackupFileInfo file,
  ) async {
    final shouldRestore = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: const Text('确认恢复'),
            content: const Text('将用该网络备份覆盖当前数据，确定继续？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldRestore) return;
    final success = await webdavProvider.restoreBackupFile(context, file);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(success ? '网络数据恢复成功' : '恢复失败')));
  }

  Future<bool> _deleteWebDavBackup(
    BuildContext context,
    WebDavBackupProvider webdavProvider,
    BackupFileInfo file,
  ) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: const Text('确认删除'),
            content: const Text('确定要删除备份文件吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return false;
    final success = await webdavProvider.deleteBackupFile(file);
    if (!mounted) return false;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(success ? '已删除网络备份' : '删除失败')));
    return success;
  }

  bool _isWebDavConfigured(WebDavBackupProvider provider) {
    return provider.webdavUrl.trim().isNotEmpty &&
        provider.webdavUsername.trim().isNotEmpty &&
        provider.webdavPath.trim().isNotEmpty;
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
}

class _StatusItem {
  final String label;
  final String value;

  const _StatusItem({required this.label, required this.value});
}

class _DetailItem {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});
}
