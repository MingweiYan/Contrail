import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:contrail/shared/utils/theme_helper.dart';

void main() {
  group('ThemeHelper', () {
    group('Date Format Getters', () {
      test('dateFormat should return correct format pattern', () {
        expect(ThemeHelper.dateFormat.pattern, 'yyyy-MM-dd');
      });

      test('timeFormat should return correct format pattern', () {
        expect(ThemeHelper.timeFormat.pattern, 'HH:mm');
      });

      test('dateTimeFormat should return correct format pattern', () {
        expect(ThemeHelper.dateTimeFormat.pattern, 'yyyy-MM-dd HH:mm');
      });
    });

    group('Text Contrast', () {
      test('ensureTextContrast should return same color when contrast is sufficient', () {
        const textColor = Colors.white;
        const backgroundColor = Colors.black;

        final result = ThemeHelper.ensureTextContrast(textColor, backgroundColor);

        expect(result, textColor);
      });

      test('ensureTextContrast should return white on dark background with insufficient contrast', () {
        const textColor = Colors.black54;
        const backgroundColor = Colors.black;

        final result = ThemeHelper.ensureTextContrast(textColor, backgroundColor);

        expect(result, Colors.white);
      });

      test('ensureTextContrast should return black on light background with insufficient contrast', () {
        const textColor = Colors.white54;
        const backgroundColor = Colors.white;

        final result = ThemeHelper.ensureTextContrast(textColor, backgroundColor);

        expect(result, Colors.black);
      });
    });

    group('Basic Widget Tests', () {
      testWidgets('should access colorScheme without throwing', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                final colorScheme = ThemeHelper.colorScheme(context);
                expect(colorScheme, isNotNull);
                expect(colorScheme, isA<ColorScheme>());
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('should access textTheme without throwing', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                final textTheme = ThemeHelper.textTheme(context);
                expect(textTheme, isNotNull);
                expect(textTheme, isA<TextTheme>());
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('should check isDarkMode correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: Brightness.light),
            home: Builder(
              builder: (BuildContext context) {
                expect(ThemeHelper.isDarkMode(context), false);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('should detect dark mode correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: Brightness.dark),
            home: Builder(
              builder: (BuildContext context) {
                expect(ThemeHelper.isDarkMode(context), true);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('should get button styles without throwing', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                expect(() => ThemeHelper.elevatedButtonStyle(context), returnsNormally);
                expect(() => ThemeHelper.outlinedButtonStyle(context), returnsNormally);
                expect(() => ThemeHelper.textButtonStyle(context), returnsNormally);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('should get text styles without throwing', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                expect(() => ThemeHelper.headlineLarge(context), returnsNormally);
                expect(() => ThemeHelper.headlineMedium(context), returnsNormally);
                expect(() => ThemeHelper.headlineSmall(context), returnsNormally);
                expect(() => ThemeHelper.titleLarge(context), returnsNormally);
                expect(() => ThemeHelper.titleMedium(context), returnsNormally);
                expect(() => ThemeHelper.titleSmall(context), returnsNormally);
                expect(() => ThemeHelper.bodyLarge(context), returnsNormally);
                expect(() => ThemeHelper.bodyMedium(context), returnsNormally);
                expect(() => ThemeHelper.bodySmall(context), returnsNormally);
                expect(() => ThemeHelper.labelLarge(context), returnsNormally);
                expect(() => ThemeHelper.labelMedium(context), returnsNormally);
                expect(() => ThemeHelper.labelSmall(context), returnsNormally);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('should create textStyleWithTheme without throwing', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                expect(
                  () => ThemeHelper.textStyleWithTheme(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  returnsNormally,
                );
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });
  });
}
