import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/features/habit/presentation/widgets/pomodoro_settings_dialog.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('PomodoroSettingsDialog', () {
    testWidgets('应该显示标题和设置项', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    PomodoroSettingsDialog.show(
                      context: context,
                      workDuration: 25,
                      shortBreakDuration: 5,
                      pomodoroRounds: 4,
                      isPomodoroMode: true,
                      isSettingsVisible: true,
                      onSettingsChanged: (_, __, ___, ____) {},
                    );
                  },
                  child: const Text('显示设置'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示设置'));
      await tester.pumpAndSettle();

      expect(find.text('番茄钟设置'), findsOneWidget);
      expect(find.text('工作时长'), findsOneWidget);
      expect(find.text('休息时长'), findsOneWidget);
      expect(find.text('番茄钟轮数'), findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('应该显示初始值', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    PomodoroSettingsDialog.show(
                      context: context,
                      workDuration: 25,
                      shortBreakDuration: 5,
                      pomodoroRounds: 4,
                      isPomodoroMode: true,
                      isSettingsVisible: true,
                      onSettingsChanged: (_, __, ___, ____) {},
                    );
                  },
                  child: const Text('显示设置'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示设置'));
      await tester.pumpAndSettle();

      expect(find.text('25 分钟'), findsOneWidget);
      expect(find.text('5 分钟'), findsOneWidget);
      expect(find.text('4 轮'), findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('应该有确定按钮', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    PomodoroSettingsDialog.show(
                      context: context,
                      workDuration: 25,
                      shortBreakDuration: 5,
                      pomodoroRounds: 4,
                      isPomodoroMode: true,
                      isSettingsVisible: true,
                      onSettingsChanged: (_, __, ___, ____) {},
                    );
                  },
                  child: const Text('显示设置'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示设置'));
      await tester.pumpAndSettle();

      expect(find.text('确定'), findsOneWidget);
      
      tester.view.reset();
    });
  });
}
