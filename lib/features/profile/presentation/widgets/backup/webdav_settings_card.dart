import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

class WebDavSettingsCard extends StatelessWidget {
  final String url;
  final String username;
  final String password;
  final String path;
  final int retentionCount;
  final ValueChanged<String> onUrlChanged;
  final ValueChanged<String> onUsernameChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onPathChanged;
  final VoidCallback onSaveConfig;
  final ValueChanged<int> onRetentionChanged;
  final VoidCallback onPerformBackup;

  const WebDavSettingsCard({super.key, required this.url, required this.username, required this.password, required this.path, required this.retentionCount, required this.onUrlChanged, required this.onUsernameChanged, required this.onPasswordChanged, required this.onPathChanged, required this.onSaveConfig, required this.onRetentionChanged, required this.onPerformBackup});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: DataBackupPageConstants.containerPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Container(
              width: ScreenUtil().setWidth(40),
              height: ScreenUtil().setWidth(40),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.link, color: ThemeHelper.primary(context)),
            ),
            title: Text('WebDAV URL', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
            subtitle: TextFormField(
              key: ValueKey('webdav_url_$url'),
              initialValue: url,
              onChanged: onUrlChanged,
            ),
          ),
          ListTile(
            leading: Container(
              width: ScreenUtil().setWidth(40),
              height: ScreenUtil().setWidth(40),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.person_outline, color: ThemeHelper.primary(context)),
            ),
            title: Text('账号', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
            subtitle: TextFormField(
              key: ValueKey('webdav_user_$username'),
              initialValue: username,
              onChanged: onUsernameChanged,
            ),
          ),
          ListTile(
            leading: Container(
              width: ScreenUtil().setWidth(40),
              height: ScreenUtil().setWidth(40),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.lock_outline, color: ThemeHelper.primary(context)),
            ),
            title: Text('密码', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
            subtitle: TextFormField(
              key: ValueKey('webdav_pass_${password.hashCode}'),
              initialValue: password,
              obscureText: true,
              onChanged: onPasswordChanged,
            ),
          ),
          ListTile(
            leading: Container(
              width: ScreenUtil().setWidth(40),
              height: ScreenUtil().setWidth(40),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.folder_copy_outlined, color: ThemeHelper.primary(context)),
            ),
            title: Text('保存路径', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
            subtitle: TextFormField(
              key: ValueKey('webdav_path_$path'),
              initialValue: path,
              onChanged: onPathChanged,
            ),
          ),
          SizedBox(height: BaseLayoutConstants.spacingSmall),
          ElevatedButton(
            onPressed: onSaveConfig,
            child: Text('保存配置', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, DataBackupPageConstants.buttonHeight)),
          ),
          Divider(height: ScreenUtil().setHeight(1), color: ThemeHelper.onBackground(context).withValues(alpha: 0.1)),
          ListTile(
            leading: Container(
              width: ScreenUtil().setWidth(40),
              height: ScreenUtil().setWidth(40),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.cloud_done_outlined, color: ThemeHelper.primary(context)),
            ),
            title: Text('保留数量', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
            trailing: DropdownButton<int>(
              value: retentionCount,
              items: const [
                DropdownMenuItem(value: 3, child: Text('3')),
                DropdownMenuItem(value: 5, child: Text('5')),
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 20, child: Text('20')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
              onChanged: (val) {
                if (val != null) onRetentionChanged(val);
              },
            ),
          ),
          SizedBox(height: BaseLayoutConstants.spacingMedium),
          ElevatedButton.icon(
            onPressed: onPerformBackup,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text('执行网络备份', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, DataBackupPageConstants.buttonHeight)),
          ),
        ],
      ),
    );
  }
}

