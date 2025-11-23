import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/features/profile/presentation/pages/theme_selection_page.dart';
import 'package:contrail/features/profile/presentation/pages/data_backup_page.dart';
import 'package:contrail/features/profile/presentation/pages/personalization_settings_page.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/profile/domain/services/user_settings_service.dart';
import 'package:contrail/shared/utils/debug_menu_manager.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = '用户';
  String? _avatarPath;
  bool _dataBackupEnabled = false;
  String _backupFrequency = '每周';

  final DebugMenuManager _debugMenuManager = DebugMenuManager();

  // 创建一个引用以便在dispose中移除
  late final VoidCallback _debugModeListener;
  


  // 使用依赖注入获取用户设置服务
  late final IUserSettingsService _userSettingsService;

  @override
  void initState() {
    super.initState();
    // 从依赖注入容器获取服务
    _userSettingsService = sl<IUserSettingsService>();
    _loadSettings();
    
    // 创建监听器函数
    _debugModeListener = () {
      if (mounted) {
        setState(() {
          // 当debug模式状态变化时，触发UI更新
          logger.debug('Debug模式状态变化: ${_debugMenuManager.showDebugTab}');
        });
      }
    };
    
    // 添加对debug模式状态变化的监听
    _debugMenuManager.showDebugTabNotifier.addListener(_debugModeListener);
  }

  Future<void> _loadSettings() async {
    final settings = await _userSettingsService.loadSettings();
    if (mounted) {
      setState(() {
        _username = settings.username;
        _avatarPath = settings.avatarPath;
        _dataBackupEnabled = settings.dataBackupEnabled;
        _backupFrequency = settings.backupFrequency;
      });
    }
  }

  Future<void> _saveSettings() async {
    final settings = UserSettings(
      username: _username,
      avatarPath: _avatarPath,
      dataBackupEnabled: _dataBackupEnabled,
      backupFrequency: _backupFrequency,
    );
    await _userSettingsService.saveSettings(settings);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarPath = pickedFile.path;
      });
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: ThemeHelper.generateBackgroundDecoration(context) ?? BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor, // 与主题颜色联动
        ),
        padding: PageLayoutConstants.getPageContainerPadding(), // 使用共享的页面容器边距
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 渐变背景的头部 - 与习惯页面统一样式
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              width: double.infinity,
              padding: ProfilePageConstants.headerPadding,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(ProfilePageConstants.headerBorderRadius)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      _debugMenuManager.recordTap(context);
                    },
                    child: Text(
                      '我的',
                      style: ThemeHelper.textStyleWithTheme(
                        context,
                        fontSize: ProfilePageConstants.titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.onPrimary(context),
                      ),
                    ),
                  ),
                  SizedBox(height: ProfilePageConstants.titleSubtitleSpacing),
                  Text(
                    '设置中心',
                    style: ThemeHelper.textStyleWithTheme(
                      context,
                      fontSize: ProfilePageConstants.subtitleFontSize,
                      color: ThemeHelper.onPrimary(context).withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            // 直接显示个人设置内容
            _buildProfileContent(),
          ],
        ),
      ),
    );
  }
  
  // 构建个人设置内容
  
  @override
  void dispose() {
    // 移除对debug模式状态变化的监听
    try {
      _debugMenuManager.showDebugTabNotifier.removeListener(_debugModeListener);
    } catch (e) {
      logger.error('移除debug模式监听器失败', e);
    }
    
    super.dispose();
  }
  
  Widget _buildProfileContent() {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 用户信息卡片 - 调整为与头部分离的独立卡片
          Container(
            margin: EdgeInsets.all(ScreenUtil().setWidth(16)),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(ScreenUtil().setWidth(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: ProfilePageConstants.userInfoPadding,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 3,
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: ThemeHelper.primary(context).withOpacity(0.25),
                        spreadRadius: 6,
                        blurRadius: 12,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Semantics(
                    label: '更换头像',
                    button: true,
                    child: Tooltip(
                      message: '点击头像更换头像',
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: ProfilePageConstants.avatarRadius,
                          backgroundImage: _avatarPath != null && _avatarPath!.isNotEmpty
                              ? FileImage(File(_avatarPath!))
                              : null,
                          backgroundColor: ThemeHelper.primary(context).withOpacity(0.1),
                          child: (_avatarPath == null || _avatarPath!.isEmpty)
                              ? ThemeHelper.styledIcon(context, Icons.person, size: ProfilePageConstants.avatarIconSize, color: ThemeHelper.primary(context))
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ScreenUtil().setHeight(8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: ScreenUtil().setSp(16), color: ThemeHelper.onBackground(context).withOpacity(0.6)),
                    SizedBox(width: ScreenUtil().setWidth(6)),
                    Text(
                      '点击头像更换头像',
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(14),
                        color: ThemeHelper.onBackground(context).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ProfilePageConstants.avatarUsernameSpacing),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(ProfilePageConstants.textFieldBorderRadius),
                  ),
                  padding: ProfilePageConstants.textFieldPadding,
                  child: TextFormField(
                    initialValue: _username,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      color: ThemeHelper.onBackground(context),
                      fontSize: ProfilePageConstants.inputFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (value) {
                      setState(() => _username = value);
                      _saveSettings();
                    },
                    onEditingComplete: () {
                      FocusScope.of(context).unfocus();
                      _saveSettings();
                    },
                  ),
                ),
              ],
            ),
          ),

          // 设置分组卡片
          Container(
            margin: ProfilePageConstants.settingsContainerMargin,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(ProfilePageConstants.settingsContainerBorderRadius),
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
                // 主题设置
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ProfilePageConstants.settingsCardTopBorderRadius),
                      topRight: Radius.circular(ProfilePageConstants.settingsCardTopBorderRadius),
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: ScreenUtil().setWidth(40),
                      height: ScreenUtil().setWidth(40),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.color_lens, color: ThemeHelper.primary(context)),
                    ),
                    title: Text('主题设置', style: TextStyle(
                      fontSize: ProfilePageConstants.listTileTitleFontSize,
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.onBackground(context)
                    )),
                    subtitle: Text('选择应用的外观风格', style: TextStyle(
                      fontSize: ProfilePageConstants.listTileSubtitleFontSize,
                      color: ThemeHelper.onBackground(context).withOpacity(0.7)
                    )),
                    trailing: ThemeHelper.styledIcon(context, Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ThemeSelectionPage())
                      );
                    },
                  ),
                ),
                
                // 分隔线
                Divider(height: ScreenUtil().setHeight(1), color: ThemeHelper.onBackground(context).withOpacity(0.1)),
                
                // 个性化设置
                ListTile(
                  leading: Container(
                    width: ScreenUtil().setWidth(40),
                    height: ScreenUtil().setWidth(40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.tune, color: ThemeHelper.primary(context)),
                  ),
                  title: Text('个性化设置', style: TextStyle(
                    fontSize: ProfilePageConstants.listTileTitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: ThemeHelper.onBackground(context)
                  )),
                  subtitle: Text('自定义应用的行为和显示方式', style: TextStyle(
                      fontSize: ProfilePageConstants.listTileSubtitleFontSize,
                    color: ThemeHelper.onBackground(context).withOpacity(0.7)
                  )),
                  trailing: ThemeHelper.styledIcon(context, Icons.arrow_forward_ios),
                  onTap: () {
                    // 导航到个性化设置页面
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PersonalizationSettingsPage())
                    );
                  },
                ),

                // 分隔线
                Divider(height: ScreenUtil().setHeight(1), color: ThemeHelper.onBackground(context).withOpacity(0.1)),

                // 数据备份
                ListTile(
                  leading: Container(
                    width: ScreenUtil().setWidth(40),
                    height: ScreenUtil().setWidth(40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.cloud_upload, color: ThemeHelper.primary(context)),
                  ),
                  title: Text('数据备份', style: TextStyle(
                    fontSize: ProfilePageConstants.listTileTitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: ThemeHelper.onBackground(context)
                  )),
                  subtitle: Text('备份和恢复应用数据', style: TextStyle(
                    fontSize: ProfilePageConstants.listTileSubtitleFontSize,
                    color: ThemeHelper.onBackground(context).withOpacity(0.7)
                  )),
                  trailing: ThemeHelper.styledIcon(context, Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const DataBackupPage())
                    );
                  },
                ),
                
                // 分隔线
                Divider(height: ScreenUtil().setHeight(1), color: ThemeHelper.onBackground(context).withOpacity(0.1)),

                // 关于
                ListTile(
                  leading: Container(
                    width: ScreenUtil().setWidth(40),
                    height: ScreenUtil().setWidth(40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info_outline, color: ThemeHelper.primary(context)),
                  ),
                  title: Text('关于', style: TextStyle(
                    fontSize: ProfilePageConstants.listTileTitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: ThemeHelper.onBackground(context)
                  )),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationIcon: Icon(
                        Icons.info_outline,
                        color: ThemeHelper.primary(context),
                        size: ScreenUtil().setSp(28),
                      ),
                      applicationName: 'Contrail',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 吃葡萄不吃葡萄皮. 保留所有权利.',
                    );
                  },
                ),
                
                // Debug菜单选项 - 仅在debug模式激活时显示
                if (_debugMenuManager.showDebugTab) ...[
                  // 分隔线
                  Divider(height: ScreenUtil().setHeight(1), color: ThemeHelper.onBackground(context).withOpacity(0.1)),
                  
                  // Debug菜单
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(ScreenUtil().setWidth(20)),
                          bottomRight: Radius.circular(ScreenUtil().setWidth(20)),
                        ),
                      ),
                      child: ListTile(
                        title: Text('Debug工具', style: TextStyle(
                          fontSize: ScreenUtil().setSp(20),
                          fontWeight: FontWeight.w500,
                          color: Colors.blue
                        )),
                      trailing: ThemeHelper.styledIcon(context, Icons.arrow_forward_ios),
                      onTap: () {
                        // 点击后导航到Debug工具页面
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _debugMenuManager.buildDebugTab(context)
                          )
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // 关于的圆角装饰容器
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(ScreenUtil().setWidth(20)),
                          bottomRight: Radius.circular(ScreenUtil().setWidth(20)),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),

          // 清空数据 - 独立的红色警示卡片
          Container(
            margin: EdgeInsets.all(ScreenUtil().setWidth(16)),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(ScreenUtil().setWidth(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              title: Text('清空数据', style: TextStyle(
                fontSize: ScreenUtil().setSp(20),
                fontWeight: FontWeight.w500,
                color: Colors.red
              )),
              subtitle: Text('删除所有习惯和统计数据', style: TextStyle(
                fontSize: ScreenUtil().setSp(16),
                color: Colors.red.withOpacity(0.7)
              )),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).cardColor,
                    title: Text('警告', style: TextStyle(
                      fontSize: ScreenUtil().setSp(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.red
                    )),
                    content: Text('确定要删除所有习惯和统计数据吗？此操作不可撤销！', style: TextStyle(
                      fontSize: ScreenUtil().setSp(20),
                      color: ThemeHelper.onBackground(context)
                    )),
                    actions: [
                      ElevatedButton(
                        child: Text('取消', style: TextStyle(
                          fontSize: ScreenUtil().setSp(20),
                          color: ThemeHelper.onPrimary(context)
                        )),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.primary(context).withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        child: Text('确认', style: TextStyle(
                          fontSize: ScreenUtil().setSp(20),
                          color: Colors.white
                        )),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            // 关闭并删除habits数据库
                            await Hive.box<Habit>('habits').clear();
                            
                            // 重新加载习惯数据，确保内存中的数据与数据库一致
                            final habitProvider = Provider.of<HabitProvider>(context, listen: false);
                            await habitProvider.loadHabits();
                            
                            // 显示成功消息
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('所有数据已清空', style: TextStyle(
                                fontSize: ScreenUtil().setSp(20),
                                color: Colors.white
                              ))),
                            );
                          } catch (e) {
                            // 显示错误消息
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('清空数据失败: $e', style: TextStyle(
                                fontSize: ScreenUtil().setSp(20),
                                color: Colors.white
                              ))),
                            );
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
