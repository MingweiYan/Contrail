import 'package:flutter/material.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

class BackupListItem extends StatelessWidget {
  final BackupFileInfo file;
  final Future<bool> Function() onDelete;
  final Future<void> Function() onRestore;

  const BackupListItem({
    super.key,
    required this.file,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
      ),
      child: Dismissible(
        key: Key(file.path),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {DismissDirection.endToStart: 0.8},
        background: Container(),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '删除',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: ScreenUtil().setWidth(8)),
              const Icon(Icons.delete, color: Colors.white),
              SizedBox(width: ScreenUtil().setWidth(10)),
            ],
          ),
        ),
        confirmDismiss: (direction) => onDelete(),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: ScreenUtil().setWidth(12),
            vertical: ScreenUtil().setHeight(8),
          ),
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
              Icons.insert_drive_file,
              color: ThemeHelper.primary(context),
            ),
          ),
          title: Text(
            file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: DataBackupPageConstants.fontSize_16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '备份时间: ' +
                file.formattedLastModified +
                ' · 大小: ' +
                file.formattedSize,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: DataBackupPageConstants.fontSize_14,
              color: ThemeHelper.onBackground(context).withValues(alpha: 0.7),
            ),
          ),
          trailing: ElevatedButton.icon(
            onPressed: () => onRestore(),
            icon: Icon(Icons.restore, size: ScreenUtil().setSp(20)),
            label: Text(
              '恢复',
              style: TextStyle(fontSize: DataBackupPageConstants.fontSize_16),
            ),
          ),
        ),
      ),
    );
  }
}
