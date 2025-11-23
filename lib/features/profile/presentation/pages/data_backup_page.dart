import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/profile/presentation/providers/backup_provider.dart';
import 'package:contrail/features/profile/presentation/widgets/backup_delete_confirmation_dialog.dart';
import 'package:contrail/features/profile/presentation/widgets/backup_restore_confirmation_dialog.dart';

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    
    // 使用addPostFrameCallback确保在widget构建完成后再初始化BackupProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final backupProvider = Provider.of<BackupProvider>(context, listen: false);
      backupProvider.initialize();
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
      final backupProvider = Provider.of<BackupProvider>(context, listen: false);
      backupProvider.refreshBackupFiles();
    }
  }

  // 显示删除确认对话框
  void _showDeleteConfirmation(BackupFileInfo backupFile) {
    showDialog(
      context: context,
      builder: (context) => BackupDeleteConfirmationDialog(
        backupFile: backupFile,
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          Navigator.pop(context);
          
          final backupProvider = Provider.of<BackupProvider>(context, listen: false);
          final success = await backupProvider.deleteBackupFile(backupFile);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('备份文件已删除')),
            );
          } else if (backupProvider.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(backupProvider.errorMessage!)),
            );
            backupProvider.clearError();
          }
        },
      ),
    );
  }

  // 显示恢复确认对话框
  void _showRestoreConfirmation(BackupFileInfo backupFile) {
    showDialog(
      context: context,
      builder: (context) => BackupRestoreConfirmationDialog(
        backupFile: backupFile,
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          Navigator.pop(context);
          
          final backupProvider = Provider.of<BackupProvider>(context, listen: false);
          final success = await backupProvider.restoreFromBackup(backupFile, context);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('从本地备份恢复成功')),
            );
            
            // 恢复成功后返回上一页
            Navigator.pop(context);
          } else if (backupProvider.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
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
        decoration: ThemeHelper.generateBackgroundDecoration(context) ?? BoxDecoration(
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
                  // 备份部分
                  Text(
                    '备份数据',
                    style: TextStyle(fontSize: DataBackupPageConstants.fontSize_29, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: BaseLayoutConstants.spacingMedium),
                  
                  // 自动备份设置
                  Container(
                    padding: DataBackupPageConstants.containerPadding,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(ScreenUtil().setWidth(20)),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '自动备份',
                              style: TextStyle(fontSize: DataBackupPageConstants.fontSize_18, fontWeight: FontWeight.bold),
                            ),
                            Switch(
                              value: backupProvider.autoBackupEnabled,
                              onChanged: (value) async {
                                await backupProvider.saveAutoBackupSettings(
                                  value,
                                  backupProvider.backupFrequency
                                );
                              },
                            ),
                          ],
                        ),
                        if (backupProvider.autoBackupEnabled) ...[
                          SizedBox(height: BaseLayoutConstants.spacingMedium),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('备份频率:'),
                              DropdownButton<int>(
                                value: backupProvider.backupFrequency,
                                items: const [
                                  DropdownMenuItem(
                                    value: 1,
                                    child: Text('每天'),
                                  ),
                                  DropdownMenuItem(
                                    value: 2,
                                    child: Text('每2天'),
                                  ),
                                  DropdownMenuItem(
                                    value: 7,
                                    child: Text('每周'),
                                  ),
                                  DropdownMenuItem(
                                    value: 30,
                                    child: Text('每月'),
                                  ),
                                ],
                                onChanged: (value) async {
                                  await backupProvider.saveAutoBackupSettings(
                                    backupProvider.autoBackupEnabled,
                                    value!
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: BaseLayoutConstants.spacingSmall),
                          if (backupProvider.lastBackupTime != null)
                            Text(
                              '上次备份时间: ' +
                                  backupProvider.lastBackupTime!.toIso8601String().replaceAll('T', ' ').substring(0, 19),
                              style: TextStyle(color: Colors.grey, fontSize: DataBackupPageConstants.fontSize_16),
                            ),
                          Text(
                            '下次备份: ' +
                                (backupProvider.lastBackupTime != null
                                    ? backupProvider.lastBackupTime!.add(Duration(days: backupProvider.backupFrequency))
                                        .toIso8601String().replaceAll('T', ' ').substring(0, 19)
                                    : '开启后立即执行第一次备份'),
                            style: TextStyle(color: Colors.grey, fontSize: ScreenUtil().setSp(16)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: BaseLayoutConstants.spacingMedium),
                  
                  // 本地备份设置
                  Container(
                    padding: DataBackupPageConstants.containerPadding,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(ScreenUtil().setWidth(20)),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              Text('备份路径:', style: TextStyle(fontSize: DataBackupPageConstants.fontSize_18)),
                            Expanded(
                              child: Text(
                                backupProvider.localBackupPath,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await backupProvider.changeBackupPath();
                                if (backupProvider.errorMessage == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('备份路径已更改为: ${backupProvider.localBackupPath}')),
                                  );
                                }
                              },
                              child: Text('更换', style: TextStyle(fontSize: DataBackupPageConstants.fontSize_18)),
                            ),
                            SizedBox(width: BaseLayoutConstants.spacingSmall),
                            TextButton(
                              onPressed: () async {
                                await backupProvider.resetBackupPathToDefault();
                                if (backupProvider.errorMessage == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('已回退到默认备份目录')),
                                  );
                                }
                              },
                              child: Text('使用默认目录', style: TextStyle(fontSize: DataBackupPageConstants.fontSize_18)),
                            ),
                          ],
                        ),
                        SizedBox(height: BaseLayoutConstants.spacingMedium),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('本地保留数量:', style: TextStyle(fontSize: DataBackupPageConstants.fontSize_18)),
                            DropdownButton<int>(
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
                                    SnackBar(content: Text('保留数量已设置为: ${backupProvider.retentionCount}')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: BaseLayoutConstants.spacingMedium),
                        ElevatedButton(
                          onPressed: () async {
                            final success = await backupProvider.performBackup();
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('本地备份成功')),
                              );
                            }
                          },
                          child: Text('执行本地备份', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, DataBackupPageConstants.buttonHeight),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: BaseLayoutConstants.spacingLarge),
                  
                  // 恢复部分
                  Text(
                    '恢复数据',
                    style: TextStyle(fontSize: ScreenUtil().setSp(29), fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: BaseLayoutConstants.spacingMedium),
                  
                  SizedBox(height: BaseLayoutConstants.spacingMedium),
                  
                  // 刷新备份文件列表按钮
                  ElevatedButton(
                    onPressed: () {
                      backupProvider.refreshBackupFiles();
                    },
                    child: Text('刷新备份文件列表', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, DataBackupPageConstants.buttonHeight),
                    ),
                  ),
                  
                  SizedBox(height: BaseLayoutConstants.spacingMedium),
                  
                  // 备份文件列表
                  if (backupProvider.isLoading) 
                    Center(child: CircularProgressIndicator())
                  else if (backupProvider.backupFiles.isEmpty) 
                    Center(child: Text('没有找到备份文件', style: TextStyle(fontSize: ScreenUtil().setSp(16))))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: backupProvider.backupFiles.length,
                      itemBuilder: (context, index) {
                        final backupFile = backupProvider.backupFiles[index];
                        return Card(
                          child: ListTile(
                            title: Text(backupFile.name, style: TextStyle(fontSize: DataBackupPageConstants.fontSize_16)),
                            subtitle: Text(
                              '修改时间: ' + backupFile.formattedLastModified +
                              '\n大小: ' + backupFile.formattedSize,
                              style: TextStyle(fontSize: DataBackupPageConstants.fontSize_14)
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _showRestoreConfirmation(backupFile);
                                  },
                                  child: Text('恢复', style: TextStyle(fontSize: DataBackupPageConstants.fontSize_16)),
                                ),
                                SizedBox(width: DataBackupPageConstants.width_8),
                                ElevatedButton(
                                  onPressed: () {
                                    _showDeleteConfirmation(backupFile);
                                  },
                                  child: Text('删除', style: TextStyle(fontSize: ScreenUtil().setSp(16))),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
