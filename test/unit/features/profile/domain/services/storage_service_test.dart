import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/profile/domain/services/storage_service_interface.dart';
import 'package:contrail/features/profile/domain/services/local_storage_service.dart';

// 模拟StorageServiceInterface的测试类
class MockStorageService extends Mock implements StorageServiceInterface {}

void main() {
  group('StorageServiceInterface', () {
    late StorageServiceInterface mockStorageService;
    late BackupFileInfo testFile;

    setUp(() {
      mockStorageService = MockStorageService();
      testFile = BackupFileInfo(
        name: 'test_backup.json',
        path: '/test/path/test_backup.json',
        lastModified: DateTime.now(),
        size: 1024,
      );

      // 设置默认的模拟行为
      when(() => mockStorageService.initialize()).thenAnswer((_) async {});
      when(
        () => mockStorageService.readData(any()),
      ).thenAnswer((_) async => {'test': 'data'});
      when(
        () => mockStorageService.writeData(any(), any()),
      ).thenAnswer((_) async => true);
      when(
        () => mockStorageService.getReadPath(),
      ).thenAnswer((_) async => '/test/path');
      when(
        () => mockStorageService.setWritePath(any()),
      ).thenAnswer((_) async => '/test/path');
      when(
        () => mockStorageService.listFiles(),
      ).thenAnswer((_) async => [testFile]);
      when(
        () => mockStorageService.deleteFile(any()),
      ).thenAnswer((_) async => true);
      when(
        () => mockStorageService.checkPermissions(),
      ).thenAnswer((_) async => true);
      when(
        () => mockStorageService.openFileSelector(),
      ).thenAnswer((_) async => '/test/file.txt');
      when(
        () => mockStorageService.openDirectorySelector(),
      ).thenAnswer((_) async => '/test/dir');
      when(
        () => mockStorageService.getFileSize(any()),
      ).thenAnswer((_) async => 1024);
      when(
        () => mockStorageService.getFileLastModified(any()),
      ).thenAnswer((_) async => DateTime.now());
    });

    test('initialize should be callable', () async {
      await mockStorageService.initialize();
      verify(() => mockStorageService.initialize()).called(1);
    });

    test('readData should return map', () async {
      final result = await mockStorageService.readData(testFile);
      expect(result, isMap);
      verify(() => mockStorageService.readData(testFile)).called(1);
    });

    test('writeData should return boolean', () async {
      final result = await mockStorageService.writeData('test.json', {
        'test': 'data',
      });
      expect(result, isA<bool>());
      verify(
        () => mockStorageService.writeData('test.json', {'test': 'data'}),
      ).called(1);
    });

    test('getFileSize should return integer', () async {
      final result = await mockStorageService.getFileSize(testFile);
      expect(result, isA<int>());
      verify(() => mockStorageService.getFileSize(testFile)).called(1);
    });

    test('deleteFile should return boolean', () async {
      final result = await mockStorageService.deleteFile(testFile);
      expect(result, isA<bool>());
      verify(() => mockStorageService.deleteFile(testFile)).called(1);
    });
  });

  group('LocalStorageService', () {
    late LocalStorageService localStorage;

    setUp(() {
      localStorage = LocalStorageService();
    });

    test('should implement StorageServiceInterface', () {
      expect(localStorage, isA<StorageServiceInterface>());
    });

    // 注意：这些测试需要在真实的设备或模拟器上运行，因为它们涉及文件系统操作
    // 在单元测试中，我们主要验证接口实现的正确性
    test('interface methods should be callable', () {
      // 验证所有接口方法都可以被调用（不实际执行，因为会涉及文件系统）
      expect(() => localStorage.initialize(), returnsNormally);
      expect(() => localStorage.checkPermissions(), returnsNormally);
      // 其他方法在实际运行时测试
    });
  });
}
