/// 备份文件信息模型
class BackupFileInfo {
  final String name;
  final String path;
  final DateTime lastModified;
  final int size;

  BackupFileInfo({
    required this.name,
    required this.path,
    required this.lastModified,
    required this.size,
  });

  /// 将文件大小转换为可读格式
  String get formattedSize {
    return '${(size / 1024).toStringAsFixed(2)} KB';
  }

  /// 获取格式化的最后修改时间
  String get formattedLastModified {
    return '${lastModified.year}-${lastModified.month.toString().padLeft(2, '0')}-${lastModified.day.toString().padLeft(2, '0')} ${lastModified.hour.toString().padLeft(2, '0')}:${lastModified.minute.toString().padLeft(2, '0')}:${lastModified.second.toString().padLeft(2, '0')}';
  }
}