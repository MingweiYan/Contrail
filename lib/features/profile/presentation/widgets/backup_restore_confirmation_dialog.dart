import 'package:flutter/material.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

/// 备份文件恢复确认对话框组件
class BackupRestoreConfirmationDialog extends StatelessWidget {
  final BackupFileInfo backupFile;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const BackupRestoreConfirmationDialog({
    super.key,
    required this.backupFile,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BackupRestoreConfirmationDialogConstants.dialogBorderRadius),
      ),
      contentPadding: BackupRestoreConfirmationDialogConstants.dialogPadding,
      title: Text('确认恢复', style: TextStyle(
        fontSize: BackupRestoreConfirmationDialogConstants.titleFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.orange
      )),
      content: Text('确定要从备份文件 "${backupFile.name}" 恢复数据吗？当前数据将被覆盖！', style: TextStyle(
        fontSize: BackupRestoreConfirmationDialogConstants.contentFontSize,
        color: ThemeHelper.onBackground(context)
      )),
      actions: [
        ElevatedButton(
          child: Text('取消', style: TextStyle(
            fontSize: BackupRestoreConfirmationDialogConstants.buttonFontSize,
            color: ThemeHelper.onPrimary(context)
          )),
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeHelper.primary(context).withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BackupRestoreConfirmationDialogConstants.buttonBorderRadius),
            ),
          ),
          onPressed: onCancel,
        ),
        ElevatedButton(
          child: Text('确认恢复', style: TextStyle(
            fontSize: BackupRestoreConfirmationDialogConstants.buttonFontSize,
            color: Colors.white
          )),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BackupRestoreConfirmationDialogConstants.buttonBorderRadius),
            ),
          ),
          onPressed: onConfirm,
        ),
      ],
    );
  }
}