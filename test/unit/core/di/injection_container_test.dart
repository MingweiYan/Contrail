import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:contrail/core/di/injection_container.dart';

void main() {
  group('InjectionContainer', () {
    test('sl 应该是 GetIt 实例', () {
      expect(sl, isA<GetIt>());
    });

    test('应该能够注册和获取单例服务', () {
      sl.reset();
      const testValue = 42;
      sl.registerSingleton<int>(testValue);
      
      final result = sl<int>();
      
      expect(result, testValue);
    });

    test('应该能够注册和获取工厂服务', () {
      sl.reset();
      int callCount = 0;
      sl.registerFactory<int>(() {
        callCount++;
        return callCount;
      });
      
      final result1 = sl<int>();
      final result2 = sl<int>();
      
      expect(result1, 1);
      expect(result2, 2);
    });

    test('应该能够注册和获取懒加载单例', () {
      sl.reset();
      int callCount = 0;
      sl.registerLazySingleton<int>(() {
        callCount++;
        return 42;
      });
      
      expect(callCount, 0);
      
      final result = sl<int>();
      
      expect(result, 42);
      expect(callCount, 1);
    });

    test('检查是否注册了服务', () {
      sl.reset();
      sl.registerSingleton<int>(42);
      
      expect(sl.isRegistered<int>(), true);
      expect(sl.isRegistered<String>(), false);
    });

    test('应该能够通过类型和名称注册服务', () {
      sl.reset();
      sl.registerSingleton<int>(1, instanceName: 'one');
      sl.registerSingleton<int>(2, instanceName: 'two');
      
      expect(sl<int>(instanceName: 'one'), 1);
      expect(sl<int>(instanceName: 'two'), 2);
    });
  });
}
