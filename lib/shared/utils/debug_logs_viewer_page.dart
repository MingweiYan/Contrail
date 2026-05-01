import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_filex/open_filex.dart';

enum LogFileType { error, info }

class DebugLogsViewerPage extends StatefulWidget {
  const DebugLogsViewerPage({super.key});

  @override
  State<DebugLogsViewerPage> createState() => _DebugLogsViewerPageState();
}

class _DebugLogsViewerPageState extends State<DebugLogsViewerPage> {
  static const int _defaultReadBytes = 200 * 1024;
  String? _logsDir;
  String? _currentFilePath;
  String _content = '';
  bool _loading = true;
  bool _showRotated = false;
  LogFileType _logType = LogFileType.error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    final dir = await getApplicationDocumentsDirectory();
    final logsDir = '${dir.path}/logs';
    final fileName = _logType == LogFileType.error ? 'error.log' : 'info.log';
    final filePath = _showRotated
        ? '$logsDir/$fileName.1'
        : '$logsDir/$fileName';
    String content = '';
    try {
      final file = File(filePath);
      if (await file.exists()) {
        content = await _readLogTail(file);
      } else {
        content = '日志文件不存在: $filePath';
      }
    } catch (e) {
      content = '读取日志失败: $e';
    }
    setState(() {
      _logsDir = logsDir;
      _currentFilePath = filePath;
      _content = content;
      _loading = false;
    });
  }

  Future<String> _readLogTail(File file) async {
    final length = await file.length();
    if (length == 0) {
      return '';
    }

    final start = length > _defaultReadBytes ? length - _defaultReadBytes : 0;
    final raf = await file.open(mode: FileMode.read);
    try {
      await raf.setPosition(start);
      final bytes = await raf.read(length - start);
      var content = utf8.decode(bytes, allowMalformed: true);

      // 从中间截断时，丢弃第一行残缺内容，避免开头出现乱码/半行。
      if (start > 0) {
        final firstLineBreak = content.indexOf('\n');
        if (firstLineBreak != -1 && firstLineBreak + 1 < content.length) {
          content = content.substring(firstLineBreak + 1);
        }
        return '[仅显示末尾 200KB 内容，完整日志请使用“系统打开当前日志”]\n\n$content';
      }
      return content;
    } finally {
      await raf.close();
    }
  }

  Future<void> _clearCurrentLogFile() async {
    final filePath = _currentFilePath;
    if (filePath == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空日志'),
        content: Text('确定要清空当前日志文件吗？\n$filePath'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.writeAsString('', mode: FileMode.write);
      } else {
        await file.create(recursive: true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('日志已清空')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('清空日志失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug日志查看'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清空当前日志',
            onPressed: _loading || _currentFilePath == null
                ? null
                : _clearCurrentLogFile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(ScreenUtil().setWidth(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: (_currentFilePath == null)
                            ? null
                            : () async {
                                try {
                                  final res = await OpenFilex.open(
                                    _currentFilePath!,
                                  );
                                  if (res.type != ResultType.done) {
                                    final message = res.message.isNotEmpty
                                        ? res.message
                                        : res.type.name;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('系统打开失败: $message'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('系统打开失败: $e')),
                                  );
                                }
                              },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('系统打开当前日志'),
                      ),
                      SizedBox(width: ScreenUtil().setWidth(12)),
                      ElevatedButton.icon(
                        onPressed: (_logsDir == null)
                            ? null
                            : () async {
                                try {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DebugLogsDirectoryPage(
                                        logsDir: _logsDir!,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('系统打开目录失败: $e')),
                                  );
                                }
                              },
                        icon: const Icon(Icons.folder_open),
                        label: const Text('系统打开日志目录'),
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(12)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '目录: ${_logsDir ?? ''}',
                          style: TextStyle(
                            fontSize: ScreenUtil().setSp(14),
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_logsDir != null) {
                            Clipboard.setData(ClipboardData(text: _logsDir!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('目录路径已复制')),
                            );
                          }
                        },
                        child: const Text('复制目录路径'),
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(8)),
                  Row(
                    children: [
                      DropdownButton<LogFileType>(
                        value: _logType,
                        items: const [
                          DropdownMenuItem(
                            value: LogFileType.error,
                            child: Text('error'),
                          ),
                          DropdownMenuItem(
                            value: LogFileType.info,
                            child: Text('info+'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _logType = v;
                          });
                          _load();
                        },
                      ),
                      SizedBox(width: ScreenUtil().setWidth(12)),
                      Expanded(
                        child: Text(
                          '文件: ${_currentFilePath ?? ''}',
                          style: TextStyle(
                            fontSize: ScreenUtil().setSp(14),
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Switch(
                        value: _showRotated,
                        onChanged: (v) {
                          setState(() {
                            _showRotated = v;
                          });
                          _load();
                        },
                      ),
                      Text(_showRotated ? '查看备份' : '查看当前'),
                      TextButton(
                        onPressed: () {
                          if (_currentFilePath != null) {
                            Clipboard.setData(
                              ClipboardData(text: _currentFilePath!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('文件路径已复制')),
                            );
                          }
                        },
                        child: const Text('复制文件路径'),
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(12)),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(
                          ScreenUtil().setWidth(8),
                        ),
                      ),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(ScreenUtil().setWidth(12)),
                          child: SelectableText(
                            _content,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: ScreenUtil().setSp(13),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class DebugLogsDirectoryPage extends StatefulWidget {
  final String logsDir;
  const DebugLogsDirectoryPage({super.key, required this.logsDir});

  @override
  State<DebugLogsDirectoryPage> createState() => _DebugLogsDirectoryPageState();
}

class _DebugLogsDirectoryPageState extends State<DebugLogsDirectoryPage> {
  bool _loading = true;
  String? _error;
  List<FileSystemEntity> _files = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dir = Directory(widget.logsDir);
      if (!await dir.exists()) {
        setState(() {
          _error = '目录不存在: ${widget.logsDir}';
          _loading = false;
        });
        return;
      }
      final files = await dir.list().where((e) => e is File).toList();
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '读取目录失败: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志目录'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(ScreenUtil().setWidth(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.logsDir,
                          style: TextStyle(
                            fontSize: ScreenUtil().setSp(14),
                            color:
                                Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.logsDir),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('目录路径已复制')),
                          );
                        },
                        child: const Text('复制路径'),
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(12)),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: ScreenUtil().setSp(14),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: _files.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Theme.of(context).dividerColor,
                          height: ScreenUtil().setHeight(12),
                        ),
                        itemBuilder: (context, index) {
                          final entity = _files[index];
                          final path = entity.path;
                          final name = path.split('/').last;
                          return ListTile(
                            title: Text(name),
                            subtitle: Text(path),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () async {
                              try {
                                final res = await OpenFilex.open(path);
                                if (res.type != ResultType.done) {
                                  final message = res.message.isNotEmpty
                                      ? res.message
                                      : res.type.name;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('系统打开失败: $message'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('系统打开失败: $e')),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
