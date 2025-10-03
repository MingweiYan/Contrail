import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/utils/habit_data_generator.dart';
import 'package:contrail/features/habit/domain/use_cases/add_habit_use_case.dart';
import 'package:contrail/core/di/injection_container.dart';

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题卡片
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🔧 Debug工具菜单',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 功能按钮网格
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // 生成测试数据
                  _buildDebugButton(
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
                    }
                  ),
                  
                  // 构建测试数据
                  _buildDebugButton(
                    context, 
                    '🧪 构建测试数据', 
                    Colors.green,
                    () async {
                      try {
                        final addHabitUseCase = sl<AddHabitUseCase>();
                        // 生成习惯数据
                        final habits = HabitDataGenerator.generateMockHabitsWithData();
                        
                        // 保存所有习惯
                        for (final habit in habits) {
                          await addHabitUseCase.execute(habit);
                        }
                        
                        _showToast('测试数据构建成功！已创建6个习惯并生成100条数据');
                        logger.debug('测试数据构建成功');
                      } catch (e) {
                        // 修复空指针错误
                        logger.error('构建测试数据失败', e);
                        _showToast('构建测试数据失败');
                      }
                    }
                  ),
                  
                  // 清除所有数据
                  _buildDebugButton(
                    context, 
                    '🧹 清除所有数据', 
                    Colors.orange,
                    () async {
                      _showConfirmDialog(
                        context,
                        '确定要清除所有数据吗？此操作不可恢复！',
                        () async {
                          // 这里可以实现清除所有数据的逻辑
                          logger.debug('清除所有数据');
                          _showToast('数据清除操作已触发');
                        },
                      );
                    }
                  ),
                  
                  // 显示日志
                  _buildDebugButton(
                    context, 
                    '📝 查看日志', 
                    Colors.purple,
                    () {
                      logger.debug('查看日志');
                      _showToast('日志功能待实现');
                    }
                  ),
                  
                  // 切换主题
                  _buildDebugButton(
                    context, 
                    '🎨 切换主题', 
                    Colors.pink,
                    () {
                      logger.debug('切换主题');
                      _showToast('主题切换功能待实现');
                    }
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // 关闭debug模式按钮
              ElevatedButton(
                onPressed: deactivateDebugMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '🛑 关闭Debug模式',
                  style: TextStyle(
                    fontSize: 16,
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
  
  // 构建debug功能按钮
  Widget _buildDebugButton(BuildContext context, String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  // 显示确认对话框
  void _showConfirmDialog(BuildContext context, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认操作'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('确认'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
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