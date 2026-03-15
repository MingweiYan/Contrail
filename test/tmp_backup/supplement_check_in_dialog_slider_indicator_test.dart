import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/features/habit/presentation/widgets/supplement_check_in_dialog.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';

class FakeHabitRepository implements HabitRepository {
  @override
  Future<void> addHabit(Habit habit) async {}
  @override
  Future<void> deleteHabit(String id) async {}
  @override
  Future<Habit?> getHabitById(String id) async => null;
  @override
  Future<List<Habit>> getHabits() async => [];
  @override
  Future<void> updateHabit(Habit habit) async {}
}

void main() {
  testWidgets('补充打卡滑动条气泡始终显示且文本同步', (tester) async {
    final updateUseCase = UpdateHabitUseCase(FakeHabitRepository());
    final habit = Habit(id: '1', name: '测试习惯', trackTime: true);

    late BuildContext parent;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, child) => MaterialApp(home: child!),
        child: Builder(
          builder: (context) {
            parent = context;
            return SupplementCheckInDialog(
              habits: [habit],
              updateHabitUseCase: updateUseCase,
              onRefresh: () {},
              parentContext: parent,
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dropdownFinder = find.byWidgetPredicate((w) => w is DropdownButton);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('测试习惯').last);
    await tester.pumpAndSettle();

    expect(find.byType(SliderTheme), findsOneWidget);
    final sliderTheme = tester.widget<SliderTheme>(find.byType(SliderTheme));
    expect(sliderTheme.data.showValueIndicator, ShowValueIndicator.always);

    final sliderFinder = find.byType(Slider);
    var sliderWidget = tester.widget<Slider>(sliderFinder);
    expect(sliderWidget.label, '30 分钟');

    sliderWidget.onChanged?.call(60.0);
    await tester.pump();

    expect(find.text('60 分钟'), findsWidgets);
  });
}
