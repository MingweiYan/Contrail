import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart'; // 添加这个导入

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  late final Logger _logger;

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal() {
    // 配置日志器
    _logger = Logger(
      level: kDebugMode ? Level.verbose : Level.info,
      printer: PrefixPrinter(
        PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 8,
          lineLength: 10000, // 设置为一个非常大的值，基本实现不限制长度
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.dateAndTime,
        ),
      ),
    );
  }

  // 详细日志
  void verbose(String message) {
    _logger.v(message);
  }

  // 调试日志
  void debug(String message) {
    _logger.d(message);
  }

  // 信息日志
  void info(String message) {
    _logger.i(message);
  }

  // 警告日志
  void warning(String message) {
    _logger.w(message);
  }

  // 错误日志
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // 致命错误日志
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

// 全局日志实例
final logger = AppLogger();