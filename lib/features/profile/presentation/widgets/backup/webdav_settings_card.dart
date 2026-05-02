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

  const WebDavSettingsCard({
    super.key,
    required this.url,
    required this.username,
    required this.password,
    required this.path,
    required this.retentionCount,
    required this.onUrlChanged,
    required this.onUsernameChanged,
    required this.onPasswordChanged,
    required this.onPathChanged,
    required this.onSaveConfig,
    required this.onRetentionChanged,
    required this.onPerformBackup,
  });

  @override
  Widget build(BuildContext context) {
    final configured =
        url.trim().isNotEmpty &&
        username.trim().isNotEmpty &&
        path.trim().isNotEmpty;
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
            children: [
              Container(
                width: ScreenUtil().setWidth(42),
                height: ScreenUtil().setWidth(42),
                decoration: BoxDecoration(
                  color: ThemeHelper.primary(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ScreenUtil().setWidth(14)),
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  color: ThemeHelper.primary(context),
                ),
              ),
              SizedBox(width: ScreenUtil().setWidth(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WebDAV 配置',
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(18),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: ScreenUtil().setHeight(4)),
                    Text(
                      configured
                          ? '配置已就绪，可以执行网络备份与恢复。'
                          : '先补齐地址、账号与路径，再保存配置。',
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(12),
                        color: ThemeHelper.onBackground(
                          context,
                        ).withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: BaseLayoutConstants.spacingMedium),
          Wrap(
            spacing: ScreenUtil().setWidth(8),
            runSpacing: ScreenUtil().setHeight(8),
            children: [
              _buildBadge(
                context,
                label: 'URL',
                value: url.trim().isEmpty ? '未填写' : '已填写',
              ),
              _buildBadge(
                context,
                label: '账号',
                value: username.trim().isEmpty ? '未填写' : '已填写',
              ),
              _buildBadge(
                context,
                label: '路径',
                value: path.trim().isEmpty ? '未填写' : path,
              ),
              _buildBadge(
                context,
                label: '保留数量',
                value: '$retentionCount 份',
              ),
            ],
          ),
          SizedBox(height: BaseLayoutConstants.spacingMedium),
          _buildFieldCard(
            context,
            icon: Icons.link_rounded,
            title: 'WebDAV URL',
            child: TextFormField(
              key: ValueKey('webdav_url_$url'),
              initialValue: url,
              onChanged: onUrlChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'https://example.com/dav',
              ),
            ),
          ),
          SizedBox(height: BaseLayoutConstants.spacingMedium),
          _buildFieldCard(
            context,
            icon: Icons.person_outline_rounded,
            title: '账号',
            child: TextFormField(
              key: ValueKey('webdav_user_$username'),
              initialValue: username,
              onChanged: onUsernameChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '输入 WebDAV 账号',
              ),
            ),
          ),
          SizedBox(height: BaseLayoutConstants.spacingMedium),
          _buildFieldCard(
            context,
            icon: Icons.lock_outline_rounded,
            title: '密码',
            child: TextFormField(
              key: ValueKey('webdav_pass_${password.hashCode}'),
              initialValue: password,
              obscureText: true,
              onChanged: onPasswordChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '输入 WebDAV 密码',
              ),
            ),
          ),
          SizedBox(height: BaseLayoutConstants.spacingMedium),
          _buildFieldCard(
            context,
            icon: Icons.folder_copy_outlined,
            title: '保存路径',
            child: TextFormField(
              key: ValueKey('webdav_path_$path'),
              initialValue: path,
              onChanged: onPathChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Contrail',
              ),
            ),
          ),
          SizedBox(height: BaseLayoutConstants.spacingMedium),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ScreenUtil().setWidth(14),
              vertical: ScreenUtil().setHeight(4),
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
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: ScreenUtil().setSp(18),
                  color: ThemeHelper.primary(context),
                ),
                SizedBox(width: ScreenUtil().setWidth(10)),
                Expanded(
                  child: Text(
                    '远端保留数量',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DropdownButton<int>(
                  value: retentionCount,
                  underline: const SizedBox.shrink(),
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
              ],
            ),
          ),
          SizedBox(height: BaseLayoutConstants.spacingMedium),
          Wrap(
            spacing: ScreenUtil().setWidth(10),
            runSpacing: ScreenUtil().setHeight(10),
            children: [
              ElevatedButton.icon(
                onPressed: onSaveConfig,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  '保存配置',
                  style: TextStyle(fontSize: ScreenUtil().setSp(14)),
                ),
                style: ThemeHelper.elevatedButtonStyle(
                  context,
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenUtil().setWidth(16),
                    vertical: ScreenUtil().setHeight(14),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onPerformBackup,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  '执行网络备份',
                  style: TextStyle(fontSize: ScreenUtil().setSp(13)),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeHelper.primary(context),
                  side: BorderSide(color: ThemeHelper.primary(context)),
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
        ],
      ),
    );
  }

  Widget _buildFieldCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenUtil().setWidth(14),
        vertical: ScreenUtil().setHeight(12),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(18)),
        border: Border.all(
          color: ThemeHelper.onBackground(context).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: ScreenUtil().setHeight(2)),
            child: Icon(icon, size: ScreenUtil().setSp(18), color: ThemeHelper.primary(context)),
          ),
          SizedBox(width: ScreenUtil().setWidth(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ScreenUtil().setSp(13),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: ScreenUtil().setHeight(4)),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenUtil().setWidth(10),
        vertical: ScreenUtil().setHeight(8),
      ),
      decoration: BoxDecoration(
        color: ThemeHelper.primary(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(14)),
        border: Border.all(
          color: ThemeHelper.primary(context).withValues(alpha: 0.12),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: ScreenUtil().setSp(12),
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
}
