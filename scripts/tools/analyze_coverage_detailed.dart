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
  
  print('='*80);
  print(' Contrail 项目测试覆盖率详细报告 ');
  print('='*80);
  print('');
  print('总行数: $totalLines');
  print('已覆盖行数: $coveredLines');
  print('测试覆盖率: $coveragePercent%');
  print('');
  
  final modules = <String, List<MapEntry<String, Map<String, int>>>>{};
  
  for (var entry in coverageByFile.entries) {
    final file = entry.key;
    String module;
    
    if (file.contains('/core/')) {
      module = 'core';
    } else if (file.contains('/features/habit/')) {
      module = 'habit';
    } else if (file.contains('/features/statistics/')) {
      module = 'statistics';
    } else if (file.contains('/features/profile/')) {
      module = 'profile';
    } else if (file.contains('/shared/')) {
      module = 'shared';
    } else {
      module = 'other';
    }
    
    if (!modules.containsKey(module)) {
      modules[module] = [];
    }
    modules[module]!.add(entry);
  }
  
  for (var moduleEntry in modules.entries) {
    final moduleName = moduleEntry.key;
    final files = moduleEntry.value;
    
    int moduleTotalLines = 0;
    int moduleCoveredLines = 0;
    
    print('');
    print('-'*80);
    print(' 📦 $moduleName 模块');
    print('-'*80);
    
    for (var fileEntry in files) {
      final filePath = fileEntry.key;
      final total = fileEntry.value['total']!;
      final covered = fileEntry.value['covered']!;
      
      moduleTotalLines += total;
      moduleCoveredLines += covered;
      
      final percent = total > 0 ? (covered / total * 100).toStringAsFixed(1) : '0.0';
      final shortPath = filePath.replaceFirst(RegExp(r'^.*?lib/'), 'lib/');
      final status = covered == 0 ? '❌' : (covered == total ? '✅' : '⚠️');
      
      print('$status $shortPath: $percent% ($covered/$total)');
    }
    
    final modulePercent = moduleTotalLines > 0 
      ? (moduleCoveredLines / moduleTotalLines * 100).toStringAsFixed(1) 
      : '0.0';
    
    print('');
    print('📊 $moduleName 模块总计: $modulePercent% ($moduleCoveredLines/$moduleTotalLines)');
  }
  
  print('');
  print('='*80);
  
  if (coveredLines / totalLines >= 0.8) {
    print('✓ 恭喜！测试覆盖率已达到 80% 以上！');
  } else {
    print('⚠ 测试覆盖率未达到 80%，还需要继续补充测试。');
  }
  print('='*80);
  
  print('\n📋 关键发现:');
  print('');
  print('❌ 完全未覆盖的模块/文件:');
  
  for (var moduleEntry in modules.entries) {
    final moduleName = moduleEntry.key;
    final files = moduleEntry.value;
    
    for (var fileEntry in files) {
      final filePath = fileEntry.key;
      final total = fileEntry.value['total']!;
      final covered = fileEntry.value['covered']!;
      
      if (covered == 0 && total > 0) {
        final shortPath = filePath.replaceFirst(RegExp(r'^.*?lib/'), 'lib/');
        print('  - $shortPath ($total 行)');
      }
    }
  }
  
  print('\n✅ 完全覆盖的文件:');
  for (var moduleEntry in modules.entries) {
    final moduleName = moduleEntry.key;
    final files = moduleEntry.value;
    
    for (var fileEntry in files) {
      final filePath = fileEntry.key;
      final total = fileEntry.value['total']!;
      final covered = fileEntry.value['covered']!;
      
      if (covered == total && total > 0) {
        final shortPath = filePath.replaceFirst(RegExp(r'^.*?lib/'), 'lib/');
        print('  - $shortPath ($total 行)');
      }
    }
  }
}
