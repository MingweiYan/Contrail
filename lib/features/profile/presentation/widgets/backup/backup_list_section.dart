import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/profile/presentation/widgets/backup/backup_list_item.dart';

class BackupListSection extends StatelessWidget {
  final String title;
  final String? caption;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;
  final bool isLoading;
  final List<BackupFileInfo> files;
  final VoidCallback onRefresh;
  final Future<void> Function(BackupFileInfo file) onRestore;
  final Future<bool> Function(BackupFileInfo file) onDelete;

  const BackupListSection({
    super.key,
    required this.title,
    this.caption,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
    required this.isLoading,
    required this.files,
    required this.onRefresh,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ThemeHelper.primary(context);
    return Container(
      padding: DataBackupPageConstants.containerPadding,
      decoration: ThemeHelper.panelDecoration(
        context,
        radius: ScreenUtil().setWidth(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(20),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (caption != null) ...[
                      SizedBox(height: ScreenUtil().setHeight(6)),
                      Text(
                        caption!,
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(12),
                          height: 1.4,
                          color: ThemeHelper.onBackground(
                            context,
                          ).withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: ScreenUtil().setWidth(12)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenUtil().setWidth(10),
                  vertical: ScreenUtil().setHeight(8),
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(ScreenUtil().setWidth(14)),
                  border: Border.all(color: primary.withValues(alpha: 0.12)),
                ),
                child: Text(
                  '${files.length} 份',
                  style: TextStyle(
                    fontSize: ScreenUtil().setSp(12),
                    fontWeight: FontWeight.w700,
                    color: ThemeHelper.onBackground(context),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: BaseLayoutConstants.spacingMedium),
          Wrap(
            spacing: ScreenUtil().setWidth(10),
            runSpacing: ScreenUtil().setHeight(10),
            children: [
              if (primaryActionLabel != null && onPrimaryAction != null)
                ElevatedButton.icon(
                  onPressed: onPrimaryAction,
                  icon: Icon(primaryActionIcon ?? Icons.play_arrow_rounded),
                  label: Text(
                    primaryActionLabel!,
                    style: TextStyle(fontSize: ScreenUtil().setSp(13)),
                  ),
                  style: ThemeHelper.elevatedButtonStyle(
                    context,
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenUtil().setWidth(14),
                      vertical: ScreenUtil().setHeight(12),
                    ),
                    backgroundColor: ThemeHelper.primary(context),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: onSecondaryAction ?? onRefresh,
                icon: Icon(secondaryActionIcon ?? Icons.refresh),
                label: Text(
                  secondaryActionLabel ?? '刷新文件列表',
                  style: TextStyle(fontSize: ScreenUtil().setSp(13)),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeHelper.onBackground(context),
                  side: BorderSide(
                    color: ThemeHelper.onBackground(
                      context,
                    ).withValues(alpha: 0.12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenUtil().setWidth(14),
                    vertical: ScreenUtil().setHeight(12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ScreenUtil().setWidth(14)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: BaseLayoutConstants.spacingMedium),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (files.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: ScreenUtil().setWidth(16),
                vertical: ScreenUtil().setHeight(26),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(18)),
                border: Border.all(
                  color: ThemeHelper.onBackground(
                    context,
                  ).withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: ScreenUtil().setSp(24),
                    color: ThemeHelper.onBackground(
                      context,
                    ).withValues(alpha: 0.5),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(10)),
                  Text(
                    '没有找到备份文件',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(4)),
                  Text(
                    '执行一次备份后，这里会显示可恢复的文件。',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(12),
                      color: ThemeHelper.onBackground(
                        context,
                      ).withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == files.length - 1
                        ? 0
                        : BaseLayoutConstants.spacingMedium,
                  ),
                  child: BackupListItem(
                    file: file,
                    onRestore: () => onRestore(file),
                    onDelete: () => onDelete(file),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
