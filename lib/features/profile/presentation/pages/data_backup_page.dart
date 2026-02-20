import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/profile/presentation/providers/backup_provider.dart';
import 'package:contrail/features/profile/presentation/providers/webdav_backup_provider.dart';
import 'package:contrail/features/profile/domain/services/webdav_backup_service.dart';
import 'package:contrail/features/profile/domain/services/webdav_storage_service.dart';
import 'package:contrail/features/profile/presentation/widgets/backup/backup_list_section.dart';
import 'package:contrail/features/profile/presentation/widgets/backup/webdav_settings_card.dart';
import 'package:contrail/features/profile/presentation/widgets/backup_delete_confirmation_dialog.dart';
import 'package:contrail/features/profile/presentation/widgets/backup_restore_confirmation_dialog.dart';

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

    // 使用addPostFrameCallback确保在widget构建完成后再初始化BackupProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final backupProvider = Provider.of<BackupProvider>(
        context,
        listen: false,
      );
      backupProvider.initialize();
      // 初始化 WebDAV Provider（仅用于页面内部）
      // 如果外部已提供，可省略此处
    });

    // 添加观察者，监听页面可见性变化
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 移除观察者
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 当应用从后台回到前台时，刷新备份文件列表
    if (state == AppLifecycleState.resumed) {
      final backupProvider = Provider.of<BackupProvider>(
        context,
        listen: false,
      );
      backupProvider.refreshBackupFiles();
    }
  }

  // 显示恢复确认对话框
  void _showRestoreConfirmation(BackupFileInfo backupFile) {
    showDialog(
      context: context,
      builder: (dialogContext) => BackupRestoreConfirmationDialog(
        backupFile: backupFile,
        onCancel: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          Navigator.pop(dialogContext);

          final backupProvider = Provider.of<BackupProvider>(
            this.context,
            listen: false,
          );
          final success = await backupProvider.restoreFromBackup(
            backupFile,
            this.context,
          );

          if (!mounted) return;

          if (success) {
            ScaffoldMessenger.of(
              this.context,
            ).showSnackBar(const SnackBar(content: Text('从本地备份恢复成功')));
            Navigator.pop(this.context);
          } else if (backupProvider.errorMessage != null) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(content: Text(backupProvider.errorMessage!)),
            );
            backupProvider.clearError();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('数据备份与恢复')),
      body: Container(
        decoration:
            ThemeHelper.generateBackgroundDecoration(context) ??
            BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor, // 与主题颜色联动
            ),
        width: double.infinity,
        height: double.infinity,
        padding: PageLayoutConstants.getPageContainerPadding(), // 使用共享的页面容器边距
        child: Consumer<BackupProvider>(
          builder: (context, backupProvider, child) {
            // 显示错误信息
            if (backupProvider.errorMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(backupProvider.errorMessage!)),
                );
                backupProvider.clearError();
              });
            }

            return SingleChildScrollView(
              padding: DataBackupPageConstants.containerPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 备份设置标题
                  Text(
                    '备份设置',
                    style: TextStyle(
                      fontSize: DataBackupPageConstants.fontSize_29,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: BaseLayoutConstants.spacingSmall),

                  // 自动备份设置
                  Container(
                    padding: DataBackupPageConstants.containerPadding,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(
                        ScreenUtil().setWidth(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: Container(
                            width: ScreenUtil().setWidth(40),
                            height: ScreenUtil().setWidth(40),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.schedule,
                              color: ThemeHelper.primary(context),
                            ),
                          ),
                          title: Text(
                            '自动备份',
                            style: TextStyle(
                              fontSize: DataBackupPageConstants.fontSize_18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Switch(
                            value: backupProvider.autoBackupEnabled,
                            onChanged: (value) async {
                              await backupProvider.saveAutoBackupSettings(
                                value,
                                backupProvider.backupFrequency,
                              );
                            },
                          ),
                        ),
                        if (backupProvider.autoBackupEnabled) ...[
                          Divider(
                            height: ScreenUtil().setHeight(1),
                            color: ThemeHelper.onBackground(
                              context,
                            ).withValues(alpha: 0.1),
                          ),
                          ListTile(
                            leading: Container(
                              width: ScreenUtil().setWidth(40),
                              height: ScreenUtil().setWidth(40),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.repeat,
                                color: ThemeHelper.primary(context),
                              ),
                            ),
                            title: Text(
                              '备份频率:',
                              style: TextStyle(
                                fontSize: DataBackupPageConstants.fontSize_18,
                              ),
                            ),
                            trailing: DropdownButton<int>(
                              value: backupProvider.backupFrequency,
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('每天')),
                                DropdownMenuItem(value: 2, child: Text('每2天')),
                                DropdownMenuItem(value: 7, child: Text('每周')),
                                DropdownMenuItem(value: 30, child: Text('每月')),
                              ],
                              onChanged: (value) async {
                                await backupProvider.saveAutoBackupSettings(
                                  backupProvider.autoBackupEnabled,
                                  value!,
                                );
                              },
                            ),
                          ),
                          SizedBox(height: BaseLayoutConstants.spacingSmall),
                          if (backupProvider.lastBackupTime != null)
                            Text(
                              '上次备份时间: ' +
                                  backupProvider.lastBackupTime!
                                      .toIso8601String()
                                      .replaceAll('T', ' ')
                                      .substring(0, 19),
                              style: TextStyle(
                                color: ThemeHelper.onBackground(
                                  context,
                                ).withValues(alpha: 0.6),
                                fontSize: DataBackupPageConstants.fontSize_16,
                              ),
                            ),
                          Text(
                            '下次备份: ' +
                                (backupProvider.lastBackupTime != null
                                    ? backupProvider.lastBackupTime!
                                          .add(
                                            Duration(
                                              days: backupProvider
                                                  .backupFrequency,
                                            ),
                                          )
                                          .toIso8601String()
                                          .replaceAll('T', ' ')
                                          .substring(0, 19)
                                    : '开启后立即执行第一次备份'),
                            style: TextStyle(
                              color: ThemeHelper.onBackground(
                                context,
                              ).withValues(alpha: 0.6),
                              fontSize: ScreenUtil().setSp(16),
                            ),
                          ),
                          // 结束：备份设置卡片
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: BaseLayoutConstants.spacingLarge),
                  // 本地备份标题
                  Text(
                    '本地备份',
                    style: TextStyle(
                      fontSize: DataBackupPageConstants.fontSize_29,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: BaseLayoutConstants.spacingSmall),

                  // 本地备份设置
                  Container(
                    padding: DataBackupPageConstants.containerPadding,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(
                        ScreenUtil().setWidth(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: ScreenUtil().setWidth(40),
                            height: ScreenUtil().setWidth(40),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.folder_open,
                              color: ThemeHelper.primary(context),
                            ),
                          ),
                          title: Text(
                            '备份路径',
                            style: TextStyle(
                              fontSize: DataBackupPageConstants.fontSize_18,
                            ),
                          ),
                          subtitle: Text(
                            backupProvider.localBackupPath,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await backupProvider.changeBackupPath();
                                  if (!mounted) return;
                                  if (backupProvider.errorMessage == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '备份路径已更改为: ${backupProvider.localBackupPath}',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  '更换',
                                  style: TextStyle(
                                    fontSize:
                                        DataBackupPageConstants.fontSize_18,
                                  ),
                                ),
                              ),
                              SizedBox(width: BaseLayoutConstants.spacingSmall),
                              TextButton(
                                onPressed: () async {
                                  await backupProvider
                                      .resetBackupPathToDefault();
                                  if (!mounted) return;
                                  if (backupProvider.errorMessage == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('已回退到默认备份目录'),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  '默认目录',
                                  style: TextStyle(
                                    fontSize:
                                        DataBackupPageConstants.fontSize_18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: ScreenUtil().setHeight(1),
                          color: ThemeHelper.onBackground(
                            context,
                          ).withValues(alpha: 0.1),
                        ),
                        ListTile(
                          leading: Container(
                            width: ScreenUtil().setWidth(40),
                            height: ScreenUtil().setWidth(40),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inventory_2,
                              color: ThemeHelper.primary(context),
                            ),
                          ),
                          title: Text(
                            '本地保留数量',
                            style: TextStyle(
                              fontSize: DataBackupPageConstants.fontSize_18,
                            ),
                          ),
                          trailing: DropdownButton<int>(
                            value: backupProvider.retentionCount,
                            items: const [
                              DropdownMenuItem(value: 3, child: Text('3')),
                              DropdownMenuItem(value: 5, child: Text('5')),
                              DropdownMenuItem(value: 10, child: Text('10')),
                              DropdownMenuItem(value: 20, child: Text('20')),
                              DropdownMenuItem(value: 50, child: Text('50')),
                            ],
                            onChanged: (value) async {
                              if (value != null) {
                                await backupProvider.saveRetentionCount(value);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '保留数量已设置为: ${backupProvider.retentionCount}',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        SizedBox(height: BaseLayoutConstants.spacingMedium),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final success = await backupProvider
                                .performBackup();
                            if (!mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('本地备份成功')),
                              );
                            }
                          },
                          icon: Icon(Icons.save_alt),
                          label: Text(
                            '执行本地备份',
                            style: TextStyle(fontSize: ScreenUtil().setSp(18)),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(
                              double.infinity,
                              DataBackupPageConstants.buttonHeight,
                            ),
                          ),
                        ),
                        SizedBox(height: BaseLayoutConstants.spacingMedium),
                        Text(
                          '本地备份文件',
                          style: TextStyle(
                            fontSize: ScreenUtil().setSp(18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: BaseLayoutConstants.spacingMedium),
                  ElevatedButton.icon(
                    onPressed: () {
                      backupProvider.refreshBackupFiles();
                    },
                    icon: Icon(Icons.refresh),
                    label: Text(
                      '刷新备份文件列表',
                      style: TextStyle(fontSize: ScreenUtil().setSp(18)),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(
                        double.infinity,
                        DataBackupPageConstants.buttonHeight,
                      ),
                    ),
                  ),
                  SizedBox(height: BaseLayoutConstants.spacingLarge),

                  // 本地恢复卡片
                  Container(
                    padding: DataBackupPageConstants.containerPadding,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(
                        ScreenUtil().setWidth(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: BaseLayoutConstants.spacingSmall),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: ScreenUtil().setSp(16),
                              color: ThemeHelper.onBackground(
                                context,
                              ).withValues(alpha: 0.7),
                            ),
                            SizedBox(width: ScreenUtil().setWidth(6)),
                            Expanded(
                              child: Text(
                                '提示：恢复将用所选备份覆盖当前数据，删除为不可逆操作。',
                                style: TextStyle(
                                  fontSize: ScreenUtil().setSp(14),
                                  color: ThemeHelper.onBackground(
                                    context,
                                  ).withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: BaseLayoutConstants.spacingMedium),
                        if (backupProvider.isLoading)
                          Center(child: CircularProgressIndicator())
                        else if (backupProvider.backupFiles.isEmpty)
                          Center(
                            child: Text(
                              '没有找到备份文件',
                              style: TextStyle(
                                fontSize: ScreenUtil().setSp(16),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: backupProvider.backupFiles.length,
                            itemBuilder: (context, index) {
                              final backupFile =
                                  backupProvider.backupFiles[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: BaseLayoutConstants.spacingMedium,
                                ),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      ScreenUtil().setWidth(12),
                                    ),
                                  ),
                                  child: Dismissible(
                                    key: Key(backupFile.path),
                                    direction: DismissDirection.endToStart,
                                    dismissThresholds: const {
                                      DismissDirection.endToStart: 0.6,
                                    },
                                    background: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(
                                          ScreenUtil().setWidth(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '删除',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(
                                            width: ScreenUtil().setWidth(8),
                                          ),
                                          const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                          SizedBox(
                                            width: ScreenUtil().setWidth(10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      final shouldDelete =
                                          await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('确认删除'),
                                              content: Text(
                                                '确定要删除备份文件 "${backupFile.name}" 吗？',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('取消'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    '删除',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ) ??
                                          false;
                                      if (shouldDelete) {
                                        final bp = Provider.of<BackupProvider>(
                                          context,
                                          listen: false,
                                        );
                                        final success = await bp
                                            .deleteBackupFile(backupFile);
                                        if (!mounted) return false;
                                        if (success) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('备份文件已删除'),
                                            ),
                                          );
                                        } else if (bp.errorMessage != null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(bp.errorMessage!),
                                            ),
                                          );
                                          bp.clearError();
                                        }
                                      }
                                      return false;
                                    },
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: ScreenUtil().setWidth(12),
                                        vertical: ScreenUtil().setHeight(8),
                                      ),
                                      leading: Container(
                                        width: ScreenUtil().setWidth(40),
                                        height: ScreenUtil().setWidth(40),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.insert_drive_file,
                                          color: ThemeHelper.primary(context),
                                        ),
                                      ),
                                      title: Text(
                                        backupFile.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: DataBackupPageConstants
                                              .fontSize_16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '备份时间: ' +
                                            backupFile.formattedLastModified +
                                            '\n大小: ' +
                                            backupFile.formattedSize,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: DataBackupPageConstants
                                              .fontSize_14,
                                          color: ThemeHelper.onBackground(
                                            context,
                                          ).withValues(alpha: 0.7),
                                        ),
                                      ),
                                      trailing: OutlinedButton.icon(
                                        onPressed: () {
                                          _showRestoreConfirmation(backupFile);
                                        },
                                        icon: Icon(
                                          Icons.restore,
                                          size: ScreenUtil().setSp(22),
                                        ),
                                        label: Text(
                                          '恢复',
                                          style: TextStyle(
                                            fontSize: DataBackupPageConstants
                                                .fontSize_16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: Size(
                                            ScreenUtil().setWidth(100),
                                            ScreenUtil().setHeight(34),
                                          ),
                                          foregroundColor: ThemeHelper.primary(
                                            context,
                                          ),
                                          side: BorderSide(
                                            color: ThemeHelper.primary(context),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: ScreenUtil().setWidth(
                                              10,
                                            ),
                                            vertical: ScreenUtil().setHeight(6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: BaseLayoutConstants.spacingLarge),

                  // 网络备份（WebDAV）分组
                  ChangeNotifierProvider<WebDavBackupProvider>(
                    create: (_) => WebDavBackupProvider(
                      WebDavBackupService(
                        storageService: WebDavStorageService(),
                      ),
                    )..initialize(),
                    child: Consumer<WebDavBackupProvider>(
                      builder: (context, webdavProvider, _) {
                        // 错误提示
                        if (webdavProvider.errorMessage != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(webdavProvider.errorMessage!),
                              ),
                            );
                            webdavProvider.clearError();
                          });
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '网络备份（WebDAV）',
                              style: TextStyle(
                                fontSize: DataBackupPageConstants.fontSize_29,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: BaseLayoutConstants.spacingSmall),
                            WebDavSettingsCard(
                              url: webdavProvider.webdavUrl,
                              username: webdavProvider.webdavUsername,
                              password: webdavProvider.webdavPassword,
                              path: webdavProvider.webdavPath,
                              retentionCount: webdavProvider.retentionCount,
                              onUrlChanged: webdavProvider.setWebDavUrl,
                              onUsernameChanged:
                                  webdavProvider.setWebDavUsername,
                              onPasswordChanged:
                                  webdavProvider.setWebDavPassword,
                              onPathChanged: webdavProvider.setWebDavPath,
                              onSaveConfig: () async {
                                await webdavProvider.saveWebDavConfig();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('WebDAV 配置已保存')),
                                );
                              },
                              onRetentionChanged: (val) async {
                                await webdavProvider.saveRetentionCount(val);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'WebDAV 保留数量已设置为: ${webdavProvider.retentionCount}',
                                    ),
                                  ),
                                );
                              },
                              onPerformBackup: () async {
                                final ok = await webdavProvider.performBackup();
                                if (!mounted) return;
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('网络备份成功')),
                                  );
                                }
                              },
                            ),
                            SizedBox(height: BaseLayoutConstants.spacingLarge),
                            BackupListSection(
                              title: '网络备份（WebDAV）文件',
                              isLoading: webdavProvider.isLoading,
                              files: webdavProvider.backupFiles,
                              onRefresh: () {
                                webdavProvider.refreshBackupFiles();
                              },
                              onRestore: (file) async {
                                final shouldRestore =
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).cardColor,
                                        title: Text(
                                          '确认恢复',
                                          style: TextStyle(
                                            fontSize: ScreenUtil().setSp(16),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: Text(
                                          '将用该网络备份覆盖当前数据，确定继续？',
                                          style: TextStyle(
                                            fontSize: ScreenUtil().setSp(20),
                                            color: ThemeHelper.onBackground(
                                              context,
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('确认'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (!shouldRestore) return;
                                final ok = await webdavProvider
                                    .restoreBackupFile(context, file);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? '网络数据恢复成功' : '恢复失败'),
                                  ),
                                );
                              },
                              onDelete: (file) async {
                                final shouldDelete =
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).cardColor,
                                        title: Text(
                                          '确认删除',
                                          style: TextStyle(
                                            fontSize: ScreenUtil().setSp(16),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                        content: Text(
                                          '确定要删除备份文件吗？此操作不可撤销！',
                                          style: TextStyle(
                                            fontSize: ScreenUtil().setSp(20),
                                            color: ThemeHelper.onBackground(
                                              context,
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('确认'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (!shouldDelete) return false;
                                final ok = await webdavProvider
                                    .deleteBackupFile(file);
                                if (!mounted) return false;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? '已删除网络备份' : '删除失败'),
                                  ),
                                );
                                return ok;
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
