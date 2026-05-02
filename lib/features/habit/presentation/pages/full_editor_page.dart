import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/theme_helper.dart';

class FullEditorPage extends StatefulWidget {
  final String? initialContent; // 初始富文本内容
  final String placeholder; // 占位符文本

  const FullEditorPage({
    Key? key,
    this.initialContent,
    required this.placeholder,
  }) : super(key: key);

  @override
  State<FullEditorPage> createState() => _FullEditorPageState();
}

class _FullEditorPageState extends State<FullEditorPage> {
  late QuillController _controller;

  @override
  void initState() {
    super.initState();

    // 初始化富文本控制器
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      try {
        final json = jsonDecode(widget.initialContent!);
        _controller = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        logger.warning('解析富文本内容失败: $e');
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return Scaffold(
      body: Container(
        decoration: ThemeHelper.generateBackgroundDecoration(context),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: FullEditorPageConstants.editorContainerPadding,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: ThemeHelper.heroDecoration(context, radius: 24),
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '完整文本编辑',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: heroForeground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.placeholder,
                              style: TextStyle(
                                fontSize: 14,
                                color: ThemeHelper.visualTheme(
                                  context,
                                ).heroSecondaryForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeaderAction(
                            context,
                            icon: Icons.arrow_back_rounded,
                            label: '返回',
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 10),
                          _buildHeaderAction(
                            context,
                            icon: Icons.save_rounded,
                            label: '保存',
                            onTap: _saveAndExit,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: ThemeHelper.panelDecoration(
                    context,
                    secondary: true,
                    radius: 22,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: QuillSimpleToolbar(
                    controller: _controller,
                    config: const QuillSimpleToolbarConfig(),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: ThemeHelper.panelDecoration(
                      context,
                      radius: 24,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: QuillEditor.basic(
                        controller: _controller,
                        config: QuillEditorConfig(
                          padding: FullEditorPageConstants.editorPadding,
                          placeholder: widget.placeholder,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: heroForeground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: heroForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 现在使用Flutter Quill提供的默认编辑器和工具栏功能，无需自定义实现

  // 保存并退出

  // 保存并退出
  void _saveAndExit() {
    try {
      // 获取文档内容
      final document = _controller.document;

      // 处理文档内容，移除开头的空白行
      final processedDocument = _removeLeadingEmptyLines(document);

      // 转换为JSON字符串
      final descriptionDelta = processedDocument.toDelta().toJson();
      final descriptionJson = jsonEncode(descriptionDelta);
      logger.debug('保存完整编辑的富文本内容: $descriptionJson');

      // 返回上一页并带回结果
      Navigator.pop(context, descriptionJson);
    } catch (e) {
      logger.warning('保存富文本内容失败: $e');

      // 显示错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: ${e.toString()}'),
          backgroundColor: ThemeHelper.visualTheme(context).destructiveColor,
        ),
      );
    }
  }

  // 移除文档开头的空白行
  Document _removeLeadingEmptyLines(Document document) {
    final lines = document.toPlainText().split('\n');

    // 如果文档为空或只有空白行，直接返回原文档
    if (lines.isEmpty || lines.every((line) => line.trim().isEmpty)) {
      return document;
    }

    // 查找第一个非空白行的索引
    int firstNonEmptyLineIndex = 0;
    while (firstNonEmptyLineIndex < lines.length &&
        lines[firstNonEmptyLineIndex].trim().isEmpty) {
      firstNonEmptyLineIndex++;
    }

    // 如果没有找到非空白行，返回原文档
    if (firstNonEmptyLineIndex >= lines.length) {
      return document;
    }

    // 如果第一个非空白行就是第一行，不需要处理
    if (firstNonEmptyLineIndex == 0) {
      return document;
    }

    // 创建新的文档，只包含非空白行开始的内容
    final newDocument = Document();
    final remainingContent = lines.sublist(firstNonEmptyLineIndex).join('\n');

    try {
      // 将处理后的纯文本转换回富文本文档
      newDocument.insert(0, remainingContent);
      return newDocument;
    } catch (e) {
      logger.warning('处理文档内容时出错: $e');
      // 如果处理失败，返回原文档
      return document;
    }
  }
}
