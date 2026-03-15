import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';

abstract class LoggerPort {
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(String message, [dynamic error, StackTrace? stackTrace]);
  void fatal(String message, [dynamic error, StackTrace? stackTrace]);
  void enableFileLogging(
    String directoryPath, {
    int maxBytes = 16 * 1024 * 1024,
  });
}

class NativeLogger {
  static const MethodChannel _channel = MethodChannel('app.contrail/logging');

  static Future<void> log({
    required String level,
    String tag = 'Contrail',
    required String message,
  }) async {
    if (!Platform.isAndroid) {
      _fallbackLog(level, tag, message);
      return;
    }
    try {
      await _channel.invokeMethod('log', {
        'level': level,
        'tag': tag,
        'message': message,
      });
    } on PlatformException catch (e) {
      debugPrint('NativeLogger error: $e');
      _fallbackLog(level, tag, message);
    } catch (e) {
      debugPrint('NativeLogger unexpected error: $e');
      _fallbackLog(level, tag, message);
    }
  }

  static void _fallbackLog(String level, String tag, String message) {
    final logMessage = '[$tag] $message';
    debugPrint(logMessage);
  }
}

class _NativeLogOutput extends LogOutput {
  static const String _tag = 'Contrail';

  String _levelToString(Level level) {
    switch (level) {
      case Level.verbose:
        return 'verbose';
      case Level.debug:
        return 'debug';
      case Level.info:
        return 'info';
      case Level.warning:
        return 'warning';
      case Level.error:
        return 'error';
      case Level.fatal:
        return 'fatal';
      default:
        return 'info';
    }
  }

  @override
  void output(OutputEvent event) {
    final message = event.lines.join('\n');
    final level = _levelToString(event.level);
    NativeLogger.log(
      level: level,
      tag: _tag,
      message: message,
    );
  }
}

class _DebugPrintOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      debugPrint(line);
    }
  }
}

class AppLogger implements LoggerPort {
  static final AppLogger _instance = AppLogger._internal();
  late Logger _logger;
  Level _level = kDebugMode ? Level.verbose : Level.info;
  late final PrettyPrinter _printer;
  LogOutput _output = _NativeLogOutput();

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal() {
    _printer = PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 10000,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    );
    _logger = Logger(
      level: _level,
      printer: PrefixPrinter(_printer),
      output: _output,
    );
  }

  @override
  void enableFileLogging(
    String directoryPath, {
    int maxBytes = 16 * 1024 * 1024,
  }) {
    final errorOutput = _LevelFileOutput(
      directoryPath,
      maxBytes,
      'error.log',
      Level.error,
    );
    final infoOutput = _LevelFileOutput(
      directoryPath,
      maxBytes,
      'info.log',
      Level.info,
    );
    _logger.i('启用文件日志 dir=$directoryPath maxBytes=$maxBytes');
    errorOutput.prepare();
    infoOutput.prepare();
    _output = MultiOutput([_NativeLogOutput(), errorOutput, infoOutput]);
    _logger = Logger(
      level: _level,
      printer: PrefixPrinter(_printer),
      output: _output,
    );
    _logger.i('文件日志输出已启用 dir=$directoryPath');
  }

  @override
  void debug(String message) {
    _logger.d(message);
  }

  @override
  void info(String message) {
    _logger.i(message);
  }

  @override
  void warning(String message) {
    _logger.w(message);
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  @override
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

final logger = AppLogger();

class _LevelFileOutput extends LogOutput {
  final String dirPath;
  final int maxBytes;
  final String fileName;
  final Level minLevel;
  late final String filePath;
  late final String rotatedPath;
  bool _inited = false;

  _LevelFileOutput(this.dirPath, this.maxBytes, this.fileName, this.minLevel);

  void prepare() {
    if (_inited) {
      debugPrint('日志输出已准备好: $dirPath');
      return;
    }
    try {
      _init();
      debugPrint('日志输出初始化完成: file=$filePath');
    } catch (e) {
      debugPrint('日志输出初始化失败: $e');
    }
  }

  void _init() {
    final dir = Directory(dirPath);
    debugPrint('日志目录检查: $dirPath');
    if (!dir.existsSync()) {
      try {
        dir.createSync(recursive: true);
        debugPrint('日志目录已创建: $dirPath');
      } catch (e) {
        debugPrint('创建日志目录失败: $e');
      }
    }
    filePath = '$dirPath/$fileName';
    rotatedPath = '$dirPath/$fileName.1';
    final f = File(filePath);
    if (!f.existsSync()) {
      try {
        f.writeAsStringSync('', mode: FileMode.write);
        debugPrint('已创建空日志文件: $filePath');
      } catch (e) {
        debugPrint('创建日志文件失败: $e');
      }
    }
    _inited = true;
    debugPrint('日志初始化完成，最大字节: $maxBytes');
  }

  @override
  void output(OutputEvent event) {
    if (event.level.index < minLevel.index) return;
    if (!_inited) {
      try {
        _init();
      } catch (e) {
        debugPrint('日志初始化失败: $e');
        return;
      }
    }
    final content = event.lines.join('\n') + '\n';
    final bytesLen = utf8.encode(content).length;
    final file = File(filePath);
    final currentSize = file.existsSync() ? file.lengthSync() : 0;
    debugPrint(
      '写入日志准备: currentSize=$currentSize addBytes=$bytesLen maxBytes=$maxBytes',
    );
    if (currentSize + bytesLen > maxBytes) {
      final rotated = File(rotatedPath);
      if (rotated.existsSync()) {
        rotated.deleteSync();
      }
      if (file.existsSync()) {
        file.renameSync(rotatedPath);
      }
      try {
        File(filePath).writeAsStringSync('', mode: FileMode.write);
        debugPrint('日志文件轮转完成: $rotatedPath -> $filePath');
      } catch (e) {
        debugPrint('日志轮转失败: $e');
      }
    }
    try {
      File(filePath).writeAsStringSync(content, mode: FileMode.append);
      debugPrint('日志写入完成: ${utf8.encode(content).length} 字节 -> $filePath');
    } catch (e) {
      debugPrint('日志写入失败: $e');
    }
  }
}
