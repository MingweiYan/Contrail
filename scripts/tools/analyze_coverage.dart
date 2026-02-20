import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('Error: coverage/lcov.info not found');
    return;
  }

  final lines = file.readAsLinesSync();
  
  int totalLines = 0;
  int coveredLines = 0;
  String? currentFile;
  final coverageByFile = <String, Map<String, int>>{};
  
  for (var line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      coverageByFile[currentFile] = {'total': 0, 'covered': 0};
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      final lineNumber = int.parse(parts[0]);
      final hitCount = int.parse(parts[1]);
      totalLines++;
      coverageByFile[currentFile]!['total'] = coverageByFile[currentFile]!['total']! + 1;
      if (hitCount > 0) {
        coveredLines++;
        coverageByFile[currentFile]!['covered'] = coverageByFile[currentFile]!['covered']! + 1;
      }
    }
  }
  
  final coveragePercent = (coveredLines / totalLines * 100).toStringAsFixed(2);
  
  print('=== Contrail 项目测试覆盖率报告 ===\n');
  print('总行数: $totalLines');
  print('已覆盖行数: $coveredLines');
  print('测试覆盖率: $coveragePercent%\n');
  
  print('=== 各模块覆盖率 (按覆盖率从低到高排序) ===\n');
  
  final sortedFiles = coverageByFile.entries.toList()
    ..sort((a, b) {
      final covA = a.value['covered']! / a.value['total']!;
      final covB = b.value['covered']! / b.value['total']!;
      return covA.compareTo(covB);
    });
  
  for (var entry in sortedFiles.take(20)) {
    final file = entry.key;
    final total = entry.value['total']!;
    final covered = entry.value['covered']!;
    final percent = (covered / total * 100).toStringAsFixed(1);
    print('$file: $percent% ($covered/$total)');
  }
  
  print('\n... 还有 ${sortedFiles.length - 20} 个文件\n');
  
  if (coveredLines / totalLines >= 0.8) {
    print('✓ 恭喜！测试覆盖率已达到 80% 以上！');
  } else {
    print('⚠ 测试覆盖率未达到 80%，还需要继续补充测试。');
  }
}
