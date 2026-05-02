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
    return Dismissible(
      key: Key(file.path),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.8},
      background: Container(),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(ScreenUtil().setWidth(18)),
        ),
        padding: EdgeInsets.only(right: ScreenUtil().setWidth(18)),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '删除',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTypographyConstants.buttonSecondaryLabelFontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: ScreenUtil().setWidth(8)),
            const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) => onDelete(),
      child: Container(
        padding: EdgeInsets.all(ScreenUtil().setWidth(14)),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(ScreenUtil().setWidth(18)),
          border: Border.all(
            color: ThemeHelper.onBackground(context).withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: ScreenUtil().setWidth(44),
              height: ScreenUtil().setWidth(44),
              decoration: BoxDecoration(
                color: ThemeHelper.primary(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(14)),
              ),
              child: Icon(
                Icons.description_outlined,
                size: ScreenUtil().setSp(20),
                color: ThemeHelper.primary(context),
              ),
            ),
            SizedBox(width: ScreenUtil().setWidth(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: DataBackupPageConstants.fontSize_16,
                      fontWeight: FontWeight.w700,
                      color: ThemeHelper.onBackground(context),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(6)),
                  Text(
                    file.formattedLastModified,
                    style: TextStyle(
                      fontSize: DataBackupPageConstants.fontSize_14,
                      color: ThemeHelper.onBackground(
                        context,
                      ).withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(2)),
                  Text(
                    '文件大小 ${file.formattedSize}',
                    style: TextStyle(
                      fontSize: AppTypographyConstants.formHelperFontSize,
                      color: ThemeHelper.onBackground(
                        context,
                      ).withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ScreenUtil().setWidth(12)),
            OutlinedButton.icon(
              onPressed: onRestore,
              icon: Icon(Icons.restore_rounded, size: ScreenUtil().setSp(18)),
              label: Text(
                '恢复',
                style: TextStyle(
                  fontSize:
                      AppTypographyConstants.buttonSecondaryLabelFontSize,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeHelper.primary(context),
                side: BorderSide(color: ThemeHelper.primary(context)),
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenUtil().setWidth(12),
                  vertical: ScreenUtil().setHeight(10),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ScreenUtil().setWidth(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
