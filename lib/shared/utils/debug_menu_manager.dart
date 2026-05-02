import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/utils/habit_data_generator.dart';
import 'package:contrail/features/habit/domain/use_cases/add_habit_use_case.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/json_editor_page.dart';
import 'package:contrail/shared/utils/debug_logs_viewer_page.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Debug菜单管理器 - 提供作为标签页的调试功能
class DebugMenuManager with WidgetsBindingObserver {
  static final DebugMenuManager _instance = DebugMenuManager._internal();
  factory DebugMenuManager() => _instance;

  static const String _debugModeKey = 'debug_mode_active';
  static const int _tapCountThreshold = 5; // 连续点击5次激活debug模式
  static const Duration _tapTimeout = Duration(seconds: 1); // 点击超时时间

  bool _isDebugModeActive = false;
  int _tapCount = 0;
  DateTime? _lastTapTime;
  BuildContext? _context;
  bool _showDebugTab = false; // 控制是否显示debug标签页

  // 添加ValueNotifier用于通知UI状态变化
  final ValueNotifier<bool> showDebugTabNotifier = ValueNotifier(false);

  // 私有构造函数
  DebugMenuManager._internal() {
    // 添加应用生命周期监听器
    WidgetsBinding.instance.addObserver(this);
    // 检查之前的debug模式状态
    _checkDebugModeStatus();
  }

  // 检查并设置debug模式状态 - 现在默认关闭debug模式
  Future<void> _checkDebugModeStatus() async {
    // 默认设置为关闭状态，不管之前保存的是什么
    _isDebugModeActive = false;
    _showDebugTab = false;
    showDebugTabNotifier.value = false;

    // 清除之前保存的状态
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugModeKey, false);

    logger.debug('🔧 Debug模式重置为关闭状态');
  }

  // 记录点击次数并检查是否需要激活debug模式
  void recordTap(BuildContext context) {
    final now = DateTime.now();

    // 重置点击计数如果超时
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!).compareTo(_tapTimeout) > 0) {
      _tapCount = 0;
    }

    _tapCount++;
    _lastTapTime = now;
    _context = context;

    logger.debug('👆 检测到点击，当前计数: $_tapCount');

    // 达到点击阈值，激活debug模式
    if (_tapCount >= _tapCountThreshold && !_isDebugModeActive) {
      _activateDebugMode();
    }
  }

  // 激活debug模式
  Future<void> _activateDebugMode() async {
    _isDebugModeActive = true;
    _showDebugTab = true;

    // 更新Notifier
    showDebugTabNotifier.value = true;

    // 保存debug模式状态
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugModeKey, true);

    logger.debug('🚀 Debug模式已激活!');

    // 显示Toast提示
    _showToast('Debug模式已激活');

    // 通知UI更新
    if (_context != null) {
      logger.debug('Debug模式激活，通知UI更新');
    }
  }

  // 直接显示debug标签页
  void toggleDebugTab() {
    _isDebugModeActive = true;
    _showDebugTab = true;

    // 更新Notifier
    showDebugTabNotifier.value = true;

    // 保存debug模式状态
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_debugModeKey, true);
    });

    logger.debug('🚀 直接显示Debug标签页');
  }

  // 关闭debug模式
  Future<void> deactivateDebugMode() async {
    _isDebugModeActive = false;
    _showDebugTab = false;

    // 更新Notifier
    showDebugTabNotifier.value = false;

    // 保存debug模式状态
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugModeKey, false);

    logger.debug('🛑 Debug模式已关闭');
  }

  // 获取是否显示debug标签页
  bool get showDebugTab => _showDebugTab;

  // 重置debug标签页显示状态
  void resetDebugTab() {
    _showDebugTab = false;

    // 更新Notifier
    showDebugTabNotifier.value = false;
  }

  // 构建debug页面内容
  Widget buildDebugTab(BuildContext context) {
    _context = context;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Debug工具'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              deactivateDebugMode();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题卡片
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ScreenUtil().setWidth(12),
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      ScreenUtil().setWidth(12),
                    ),
                  ),
                  child: Text(
                    '🔧 Debug工具菜单',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTypographyConstants.sectionTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: ScreenUtil().setHeight(20)),

              // 生成测试数据按钮 - 水平占满屏幕
              _buildFullWidthDebugButton(
                context,
                '📊 生成测试数据',
                Colors.blue,
                () async {
                  try {
                    final addHabitUseCase = sl<AddHabitUseCase>();
                    await HabitDataGenerator.generateAndSaveTestData(
                      addHabitUseCase: addHabitUseCase,
                      context: context,
                    );
                  } catch (e) {
                    // 修复空指针错误
                    logger.error('生成测试数据失败', e);
                    _showToast('生成测试数据失败');
                  }
                },
              ),
              SizedBox(height: ScreenUtil().setHeight(20)),

              // JSON编辑器按钮 - 水平占满屏幕
              _buildFullWidthDebugButton(
                context,
                '📝 JSON编辑器',
                Colors.purple,
                () async {
                  try {
                    // 打开JSON编辑器页面
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => JsonEditorPage()),
                    );

                    // 如果有返回结果，使用增强的分段打印方法，确保完整显示
                    if (result != null && result is String) {
                      _printLongJsonWithHeaders('JSON编辑器返回数据', result);
                      _showToast('JSON数据已完整输出到日志');
                    }
                  } catch (e) {
                    logger.error('打开JSON编辑器失败', e);
                    _showToast('打开JSON编辑器失败');
                  }
                },
              ),
              SizedBox(height: ScreenUtil().setHeight(40)),

              // 打开Debug日志查看器
              _buildFullWidthDebugButton(
                context,
                '📂 打开Debug日志',
                Colors.green,
                () async {
                  try {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DebugLogsViewerPage(),
                      ),
                    );
                  } catch (e) {
                    logger.error('打开Debug日志查看器失败', e);
                    _showToast('打开Debug日志查看器失败');
                  }
                },
              ),
              SizedBox(height: ScreenUtil().setHeight(20)),

              // 关闭debug模式按钮
              ElevatedButton(
                onPressed: deactivateDebugMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(
                    vertical: ScreenUtil().setHeight(16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ScreenUtil().setWidth(12),
                    ),
                  ),
                ),
                child: Text(
                  '🛑 关闭Debug模式',
                  style: TextStyle(
                    fontSize: AppTypographyConstants.formSectionTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建水平占满屏幕的debug功能按钮
  Widget _buildFullWidthDebugButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: ScreenUtil().setHeight(24)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
        ),
        elevation: 2,
        // 水平占满屏幕
        minimumSize: Size(double.infinity, 0),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTypographyConstants.panelTitleFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // 显示Toast提示
  void _showToast(String message) {
    if (_context != null) {
      final scaffoldMessenger = ScaffoldMessenger.of(_context!);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 增强的分段打印方法，使用小标题分隔，确保完整显示
  void _printLongJsonWithHeaders(String prefix, String jsonString) {
    const int maxLength = 500; // 更小的分段大小，确保每个段都能完整显示

    // 打印开始标记和总长度信息
    logger.debug('=' * 50);
    logger.debug('开始输出$prefix - 总长度: ${jsonString.length} 字符');
    logger.debug('=' * 50);

    // 分段打印
    int start = 0;
    int segmentIndex = 1;

    while (start < jsonString.length) {
      int end = start + maxLength;
      if (end > jsonString.length) {
        end = jsonString.length;
      }

      final segment = jsonString.substring(start, end);
      logger.debug('【$prefix - 分段 $segmentIndex】 字符范围: $start-$end');
      logger.debug(segment);

      start = end;
      segmentIndex++;
    }

    // 打印结束标记
    logger.debug('=' * 50);
    logger.debug('$prefix 输出完成，共分成 ${segmentIndex - 1} 段');
    logger.debug('=' * 50);
  }

  // 获取当前debug模式状态
  bool get isDebugModeActive => _isDebugModeActive;

  // 监听应用生命周期变化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 在应用进入后台或退出时自动关闭debug模式
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_isDebugModeActive) {
        logger.debug('应用进入后台，自动关闭Debug模式');
        deactivateDebugMode();
      }
    }
  }

  // 清理资源
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 清理Notifier
    showDebugTabNotifier.dispose();
  }
}
