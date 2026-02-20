import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/profile/presentation/widgets/backup/backup_list_item.dart';

class BackupListSection extends StatelessWidget {
  final String title;
  final bool isLoading;
  final List<BackupFileInfo> files;
  final VoidCallback onRefresh;
  final Future<void> Function(BackupFileInfo file) onRestore;
  final Future<bool> Function(BackupFileInfo file) onDelete;

  const BackupListSection({
    super.key,
    required this.title,
    required this.isLoading,
    required this.files,
    required this.onRefresh,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ScreenUtil().setSp(29),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: BaseLayoutConstants.spacingSmall),
        ElevatedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
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
        Container(
          padding: DataBackupPageConstants.containerPadding,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : files.isEmpty
              ? Center(
                  child: Text(
                    '没有找到备份文件',
                    style: TextStyle(fontSize: ScreenUtil().setSp(16)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final f = files[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: BaseLayoutConstants.spacingMedium,
                      ),
                      child: BackupListItem(
                        file: f,
                        onRestore: () => onRestore(f),
                        onDelete: () => onDelete(f),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
