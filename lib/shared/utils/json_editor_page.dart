import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:contrail/shared/utils/logger.dart';

class JsonEditorPage extends StatefulWidget {
  const JsonEditorPage({Key? key}) : super(key: key);

  @override
  State<JsonEditorPage> createState() => _JsonEditorPageState();
}

class _JsonEditorPageState extends State<JsonEditorPage> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // 初始化富文本控制器，预加载一个默认的JSON模板
    // 使用raw string语法避免控制字符问题
    final defaultJson = r'''
      [
        {"insert":" \n"}
      ]
    ''';
    // 移除字符串中的所有空格和换行符，确保JSON格式正确
    final cleanJson = defaultJson.replaceAll(RegExp(r'\s+'), '');
    
    try {
      final json = jsonDecode(cleanJson);
      _controller = QuillController(
        document: Document.fromJson(json),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      logger.warning('初始化富文本控制器失败: $e');
      _controller = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('JSON编辑器'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _outputAndExit,
            tooltip: '输出JSON并返回',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 编辑说明
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '编辑以下JSON数据，点击右上角保存按钮输出并返回',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
            // 富文本工具栏
            QuillSimpleToolbar(
              controller: _controller,
              config: const QuillSimpleToolbarConfig(),
            ),
            
            // 富文本编辑区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: QuillEditor.basic(
                  controller: _controller,
                  config: QuillEditorConfig(
                    padding: const EdgeInsets.all(8),
                    placeholder: '在此编辑富文本内容...',
                    autoFocus: true,
                    expands: false,
                    scrollable: true,
                    showCursor: true,
                  ),
                ),
              ),
            ),
            // 输出按钮
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _outputAndExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(double.infinity, 0),
                ),
                child: const Text(
                  '📋 输出JSON并返回',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 输出JSON并返回
  void _outputAndExit() {
    try {
      // 获取文档内容并转换为JSON
      final document = _controller.document;
      final descriptionDelta = document.toDelta().toJson();
      final descriptionJson = jsonEncode(descriptionDelta);
      
      if (descriptionJson.isEmpty) {
        logger.warning('JSON内容为空');
        _showToast('JSON内容为空');
        return;
      }
      
      // 使用增强的分段打印方法，确保完整显示
      _printLongJsonWithHeaders(descriptionJson);
      
      // 显示成功消息
      _showToast('JSON数据已完整输出到日志');
      
      // 返回JSON字符串
      Navigator.pop(context, descriptionJson);
    } catch (e) {
      logger.error('JSON格式无效: $e');
      _showToast('JSON格式无效，请检查后重试');
    }
  }
  
  // 增强的分段打印方法，使用小标题分隔，确保完整显示
  void _printLongJsonWithHeaders(String jsonString) {
    const int maxLength = 500; // 更小的分段大小，确保每个段都能完整显示
    
    // 打印开始标记和总长度信息
    logger.debug('=' * 50);
    logger.debug('开始输出JSON数据 - 总长度: ${jsonString.length} 字符');
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
      logger.debug('【分段 $segmentIndex】 字符范围: $start-$end');
      logger.debug(segment);
      
      start = end;
      segmentIndex++;
    }
    
    // 打印结束标记
    logger.debug('=' * 50);
    logger.debug('JSON数据输出完成，共分成 ${segmentIndex-1} 段');
    logger.debug('=' * 50);
  }

  // 显示Toast提示
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}