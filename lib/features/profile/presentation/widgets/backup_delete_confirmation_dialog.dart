import 'package:flutter/material.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

/// 备份文件删除确认对话框组件
class BackupDeleteConfirmationDialog extends StatelessWidget {
  final BackupFileInfo backupFile;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const BackupDeleteConfirmationDialog({
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
        borderRadius: BorderRadius.circular(
          BackupDeleteConfirmationDialogConstants.dialogBorderRadius,
        ),
      ),
      contentPadding: BackupDeleteConfirmationDialogConstants.dialogPadding,
      title: Text(
        '确认删除',
        style: TextStyle(
          fontSize: BackupDeleteConfirmationDialogConstants.titleFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
      content: Text(
        '确定要删除备份文件 "${backupFile.name}" 吗？此操作不可撤销！',
        style: TextStyle(
          fontSize: BackupDeleteConfirmationDialogConstants.contentFontSize,
          color: ThemeHelper.onBackground(context),
        ),
      ),
      actions: [
        ElevatedButton(
          child: Text(
            '取消',
            style: TextStyle(
              fontSize: BackupDeleteConfirmationDialogConstants.buttonFontSize,
              color: ThemeHelper.onPrimary(context),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeHelper.primary(context).withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                BackupDeleteConfirmationDialogConstants.buttonBorderRadius,
              ),
            ),
          ),
          onPressed: onCancel,
        ),
        ElevatedButton(
          child: Text(
            '确认删除',
            style: TextStyle(
              fontSize: BackupDeleteConfirmationDialogConstants.buttonFontSize,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                BackupDeleteConfirmationDialogConstants.buttonBorderRadius,
              ),
            ),
          ),
          onPressed: onConfirm,
        ),
      ],
    );
  }
}
