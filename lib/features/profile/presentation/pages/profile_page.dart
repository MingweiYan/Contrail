import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:contrail/shared/models/habit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = '用户';
  String? _avatarPath;
  bool _notificationsEnabled = true;
  String _themeMode = 'light';
  bool _dataBackupEnabled = false;
  String _backupFrequency = '每周';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '用户';
      _avatarPath = prefs.getString('avatarPath');
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _themeMode = prefs.getString('themeMode') ?? 'light';
      _dataBackupEnabled = prefs.getBool('dataBackupEnabled') ?? false;
      _backupFrequency = prefs.getString('backupFrequency') ?? '每周';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _username);
    await prefs.setString('avatarPath', _avatarPath ?? '');
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setString('themeMode', _themeMode);
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
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          // 用户信息
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _avatarPath != null
                        ? FileImage(File(_avatarPath!))
                        : null,
                    child: _avatarPath == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: _username,
                  decoration: const InputDecoration(labelText: '用户名'),
                  onChanged: (value) => setState(() => _username = value),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('保存'),
                ),
              ],
            ),
          ),

          // 通知设置
          ListTile(
            title: const Text('通知设置'),
            subtitle: const Text('接收习惯提醒和统计报告'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
            ),
          ),

          // 主题设置
          ListTile(
            title: const Text('主题设置'),
            subtitle: Text('当前: $_themeMode'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('选择主题'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ['light', 'dark', 'system'].map((mode) {
                      return ListTile(
                        title: Text(mode == 'light' ? '浅色' : mode == 'dark' ? '深色' : '跟随系统'),
                        onTap: () {
                          setState(() => _themeMode = mode);
                          Navigator.pop(context);
                        },
                        trailing: Radio(
                          value: mode,
                          groupValue: _themeMode,
                          onChanged: (value) {
                            setState(() => _themeMode = value as String);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),

          // 数据备份
          ListTile(
            title: const Text('数据备份'),
            subtitle: Text('频率: $_backupFrequency'),
            trailing: Switch(
              value: _dataBackupEnabled,
              onChanged: (value) => setState(() => _dataBackupEnabled = value),
            ),
            onTap: () {
              if (_dataBackupEnabled) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('备份频率'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ['每天', '每周', '每月'].map((freq) {
                        return ListTile(
                          title: Text(freq),
                          onTap: () {
                            setState(() => _backupFrequency = freq);
                            Navigator.pop(context);
                          },
                          trailing: Radio(
                            value: freq,
                            groupValue: _backupFrequency,
                            onChanged: (value) {
                              setState(() => _backupFrequency = value as String);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }
            },
          ),

          // 关于
          ListTile(
            title: const Text('关于'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '习惯追踪',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2023 习惯追踪. 保留所有权利.',
              );
            },
          ),

          // 清空数据
          ListTile(
            title: const Text('清空数据'),
            subtitle: const Text('删除所有习惯和统计数据'),
            textColor: Colors.red,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('警告'),
                  content: const Text('确定要删除所有习惯和统计数据吗？此操作不可撤销！'),
                  actions: [
                    TextButton(
                      child: const Text('取消'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('确认', style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        try {
                          // 关闭并删除habits数据库
                          await Hive.box<Habit>('habits').clear();
                          // 显示成功消息
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('所有数据已清空')),
                          );
                        } catch (e) {
                          // 显示错误消息
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('清空数据失败: $e')),
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
        ],
      ),
    );
  }
}