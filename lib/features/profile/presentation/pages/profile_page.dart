import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/models/theme_model.dart';
import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/features/profile/presentation/pages/theme_selection_page.dart';
import 'package:contrail/features/profile/presentation/pages/data_backup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/debug_menu_manager.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/core/state/focus_state.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    // 添加对debug模式状态变化的监听
    _debugMenuManager.showDebugTabNotifier.addListener(() {
      setState(() {
        // 当debug模式状态变化时，触发UI更新
        logger.debug('Debug模式状态变化: ${_debugMenuManager.showDebugTab}');
      });
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      try {
        _username = prefs.getString('username') ?? '用户';
        _avatarPath = prefs.getString('avatarPath');
        _dataBackupEnabled = prefs.getBool('dataBackupEnabled') ?? false;
        
        // 安全地获取backupFrequency，处理可能的类型错误
        final frequencyValue = prefs.get('backupFrequency');
        if (frequencyValue is String) {
          _backupFrequency = frequencyValue;
        } else if (frequencyValue != null) {
          // 如果存储的值不是String类型，尝试转换或使用默认值
          _backupFrequency = frequencyValue.toString();
          logger.warning('backupFrequency存储的值类型不正确，已转换为字符串');
        } else {
          _backupFrequency = '每周';
        }
      } catch (e) {
        logger.error('加载设置失败', e);
        // 设置默认值以确保应用继续运行
        _username = '用户';
        _avatarPath = null;
        _dataBackupEnabled = false;
        _backupFrequency = '每周';
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _username);
    await prefs.setString('avatarPath', _avatarPath ?? '');
    await prefs.setBool('dataBackupEnabled', _dataBackupEnabled);
    await prefs.setString('backupFrequency', _backupFrequency);
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
    // 获取主题Provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    // 生成背景装饰
    final backgroundDecoration = ThemeHelper.generateBackgroundDecoration(context);

    return Scaffold(
      body: Container(
        decoration: backgroundDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 渐变背景的头部 - 与习惯页面统一样式
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
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
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.onPrimary(context),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '设置中心',
                    style: ThemeHelper.textStyleWithTheme(
                      context,
                      fontSize: 16,
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
      // 创建一个临时函数用于移除监听器
      void tempListener() {}
      _debugMenuManager.showDebugTabNotifier.removeListener(tempListener);
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
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 头像容器带有阴影效果
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
                    ],
                  ),
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _avatarPath != null && _avatarPath!.isNotEmpty
                          ? FileImage(File(_avatarPath!))
                          : null,
                      backgroundColor: ThemeHelper.primary(context).withOpacity(0.1),
                      child: (_avatarPath == null || _avatarPath!.isEmpty)
                          ? ThemeHelper.styledIcon(context, Icons.person, size: 60, color: ThemeHelper.primary(context))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 用户名输入框带有自定义样式
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: TextFormField(
                    initialValue: _username,
                    decoration: InputDecoration(
                      labelText: '用户名',
                      labelStyle: TextStyle(
                        color: ThemeHelper.onBackground(context).withOpacity(0.9),
                        fontSize: 16
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      color: ThemeHelper.onBackground(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                    ),
                    onChanged: (value) => setState(() => _username = value),
                  ),
                ),
                const SizedBox(height: 20),
                // 保存按钮使用悬浮效果
                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeHelper.primary(context),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                    shadowColor: ThemeHelper.primary(context).withOpacity(0.3),
                  ),
                  child: Text('保存', style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.onPrimary(context)
                  )),
                ),
              ],
            ),
          ),

          // 设置分组卡片
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
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
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ListTile(
                    title: Text('主题设置', style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.onBackground(context)
                    )),
                    subtitle: Text('选择应用的外观风格', style: TextStyle(
                      fontSize: 14,
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
                Divider(height: 1, color: ThemeHelper.onBackground(context).withOpacity(0.1)),

                // 数据备份
                ListTile(
                  title: Text('数据备份', style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ThemeHelper.onBackground(context)
                  )),
                  subtitle: Text('备份和恢复应用数据', style: TextStyle(
                    fontSize: 14,
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
                Divider(height: 1, color: ThemeHelper.onBackground(context).withOpacity(0.1)),

                // 关于
                ListTile(
                  title: Text('关于', style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ThemeHelper.onBackground(context)
                  )),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: '习惯追踪',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2023 习惯追踪. 保留所有权利.',
                    );
                  },
                ),
                
                // Debug菜单选项 - 仅在debug模式激活时显示
                if (_debugMenuManager.showDebugTab) ...[
                  // 分隔线
                  Divider(height: 1, color: ThemeHelper.onBackground(context).withOpacity(0.1)),
                  
                  // Debug菜单
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: ListTile(
                      title: Text('Debug工具', style: TextStyle(
                        fontSize: 16,
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
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 清空数据 - 独立的红色警示卡片
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
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
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red
              )),
              subtitle: Text('删除所有习惯和统计数据', style: TextStyle(
                fontSize: 14,
                color: Colors.red.withOpacity(0.7)
              )),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).cardColor,
                    title: Text('警告', style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red
                    )),
                    content: Text('确定要删除所有习惯和统计数据吗？此操作不可撤销！', style: TextStyle(
                      fontSize: 16,
                      color: ThemeHelper.onBackground(context)
                    )),
                    actions: [
                      ElevatedButton(
                        child: Text('取消', style: TextStyle(
                          fontSize: 16,
                          color: ThemeHelper.onPrimary(context)
                        )),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.primary(context).withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        child: Text('确认', style: TextStyle(
                          fontSize: 16,
                          color: Colors.white
                        )),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            // 关闭并删除habits数据库
                            await Hive.box<Habit>('habits').clear();
                            
                            // 清除专注状态单例中的内存状态
                            final focusState = FocusState();
                            focusState.endFocus();
                            
                            // 重新加载习惯数据，确保内存中的数据与数据库一致
                            final habitProvider = Provider.of<HabitProvider>(context, listen: false);
                            await habitProvider.loadHabits();
                            
                            // 显示成功消息
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('所有数据已清空', style: TextStyle(
                                fontSize: 16,
                                color: Colors.white
                              ))),
                            );
                          } catch (e) {
                            // 显示错误消息
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('清空数据失败: $e', style: TextStyle(
                                fontSize: 16,
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