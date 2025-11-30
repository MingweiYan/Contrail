import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_filex/open_filex.dart';

class DebugLogsViewerPage extends StatefulWidget {
  const DebugLogsViewerPage({super.key});

  @override
  State<DebugLogsViewerPage> createState() => _DebugLogsViewerPageState();
}

class _DebugLogsViewerPageState extends State<DebugLogsViewerPage> {
  String? _logsDir;
  String? _currentFilePath;
  String _content = '';
  bool _loading = true;
  bool _showRotated = false;

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
    final filePath = _showRotated
        ? '$logsDir/error.log.1'
        : '$logsDir/error.log';
    String content = '';
    try {
      final file = File(filePath);
      if (await file.exists()) {
        content = await file.readAsString();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug日志查看'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
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
                                  final res = await OpenFilex.open(_currentFilePath!);
                                  if (res.type != ResultType.done) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('系统打开失败: ${res.message ?? res.type.name}')),
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
                                  final res = await OpenFilex.open(_logsDir!);
                                  if (res.type != ResultType.done) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('系统打开目录失败: ${res.message ?? res.type.name}')),
                                    );
                                  }
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
                            Clipboard.setData(ClipboardData(text: _currentFilePath!));
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
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(8)),
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
