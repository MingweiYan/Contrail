import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/features/statistics/presentation/pages/habit_detail_statistics_page.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/theme/visual_theme_definitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('详情统计保留目标达成率但不展示完成天数', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final today = DateTime.now();
    final habit = Habit(id: 'read', name: '阅读', trackTime: true, targetDays: 20)
      ..trackingDurations[today] = const [
        Duration(minutes: 10),
        Duration(minutes: 20),
      ];

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PersonalizationProvider(),
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: HabitDetailStatisticsPage(habit: habit),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('记录次数'), findsOneWidget);
    expect(find.text('2 次'), findsOneWidget);
    expect(find.text('专注时长'), findsWidgets);
    expect(find.text('30 分'), findsOneWidget);
    expect(find.text('目标达成率'), findsOneWidget);
    expect(find.text('完成率'), findsNothing);
    expect(find.text('已有记录'), findsNothing);
    expect(find.text('距离目标'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
