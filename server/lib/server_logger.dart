import 'dart:convert';
import 'dart:io';

enum ServerLogLevel { debug, info, warning, error, off }

class ServerLogger {
  ServerLogger({
    required this.level,
    File? logFile,
    this.maxBytes = 10 * 1024 * 1024,
    this.backupCount = 3,
    DateTime Function()? now,
  }) : _logFile = logFile,
       _now = now ?? DateTime.now {
    if (maxBytes < 1024) {
      throw ArgumentError.value(maxBytes, 'maxBytes', 'must be at least 1024');
    }
    if (backupCount < 0 || backupCount > 100) {
      throw ArgumentError.value(
        backupCount,
        'backupCount',
        'must be between 0 and 100',
      );
    }
    _logFile?.parent.createSync(recursive: true);
  }

  factory ServerLogger.fromEnvironment(Map<String, String> environment) {
    final level = parseLevel(environment['CONTRAIL_LOG_LEVEL'] ?? 'info');
    final filePath = environment['CONTRAIL_LOG_FILE']?.trim();
    final maxBytes = _parseInt(
      environment,
      'CONTRAIL_LOG_MAX_BYTES',
      10 * 1024 * 1024,
      minimum: 1024,
    );
    final backupCount = _parseInt(
      environment,
      'CONTRAIL_LOG_BACKUP_COUNT',
      3,
      minimum: 0,
      maximum: 100,
    );
    return ServerLogger(
      level: level,
      logFile: filePath == null || filePath.isEmpty ? null : File(filePath),
      maxBytes: maxBytes,
      backupCount: backupCount,
    );
  }

  final ServerLogLevel level;
  final int maxBytes;
  final int backupCount;
  final File? _logFile;
  final DateTime Function() _now;
  bool _fileWriteFailed = false;

  static ServerLogLevel parseLevel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'debug':
        return ServerLogLevel.debug;
      case 'info':
        return ServerLogLevel.info;
      case 'warn':
      case 'warning':
        return ServerLogLevel.warning;
      case 'error':
        return ServerLogLevel.error;
      case 'off':
        return ServerLogLevel.off;
      default:
        throw FormatException(
          'CONTRAIL_LOG_LEVEL must be debug, info, warn, error, or off: $raw',
        );
    }
  }

  void debug(String message) => _write(ServerLogLevel.debug, message);

  void info(String message) => _write(ServerLogLevel.info, message);

  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _write(ServerLogLevel.warning, message, error, stackTrace);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _write(ServerLogLevel.error, message, error, stackTrace);

  void _write(
    ServerLogLevel messageLevel,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_isEnabled(messageLevel)) return;

    final buffer = StringBuffer()
      ..write(_now().toUtc().toIso8601String())
      ..write(' [')
      ..write(_label(messageLevel))
      ..write('] ')
      ..write(message);
    if (error != null) buffer.write(': $error');
    if (stackTrace != null) buffer.write('\n$stackTrace');
    buffer.write('\n');
    final line = buffer.toString();

    final file = _logFile;
    if (file == null) {
      if (messageLevel == ServerLogLevel.warning ||
          messageLevel == ServerLogLevel.error) {
        stderr.write(line);
      } else {
        stdout.write(line);
      }
      return;
    }
    if (_fileWriteFailed) return;

    try {
      _rotateIfNeeded(file, utf8.encode(line).length);
      file.writeAsStringSync(line, mode: FileMode.append, flush: true);
    } on Object catch (writeError) {
      _fileWriteFailed = true;
      stderr.writeln('Failed to write Contrail log ${file.path}: $writeError');
      stderr.write(line);
    }
  }

  bool _isEnabled(ServerLogLevel messageLevel) {
    if (level == ServerLogLevel.off) return false;
    return messageLevel.index >= level.index;
  }

  void _rotateIfNeeded(File file, int incomingBytes) {
    if (!file.existsSync() || file.lengthSync() + incomingBytes <= maxBytes) {
      return;
    }
    if (backupCount == 0) {
      file.writeAsStringSync('');
      return;
    }

    for (var index = backupCount; index >= 1; index--) {
      final destination = File('${file.path}.$index');
      if (destination.existsSync()) destination.deleteSync();
      final source = index == 1 ? file : File('${file.path}.${index - 1}');
      if (source.existsSync()) source.renameSync(destination.path);
    }
  }

  static int _parseInt(
    Map<String, String> environment,
    String name,
    int fallback, {
    required int minimum,
    int? maximum,
  }) {
    final raw = environment[name]?.trim();
    if (raw == null || raw.isEmpty) return fallback;
    final value = int.tryParse(raw);
    if (value == null ||
        value < minimum ||
        (maximum != null && value > maximum)) {
      final range = maximum == null ? 'at least $minimum' : '$minimum-$maximum';
      throw FormatException('$name must be an integer in range $range: $raw');
    }
    return value;
  }

  static String _label(ServerLogLevel level) {
    switch (level) {
      case ServerLogLevel.debug:
        return 'DEBUG';
      case ServerLogLevel.info:
        return 'INFO';
      case ServerLogLevel.warning:
        return 'WARN';
      case ServerLogLevel.error:
        return 'ERROR';
      case ServerLogLevel.off:
        return 'OFF';
    }
  }
}
