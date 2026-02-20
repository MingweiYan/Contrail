import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/shared/utils/color_helper.dart';

void main() {
  group('ColorHelper', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('getAllColors', () {
      test('should return predefined colors when no custom colors', () async {
        final result = await ColorHelper.getAllColors();

        expect(result, isNotNull);
        expect(result.length, greaterThan(0));
      });
    });

    group('getCustomColors', () {
      test('should return empty list when no custom colors saved', () async {
        final result = await ColorHelper.getCustomColors();

        expect(result, isNotNull);
        expect(result, isEmpty);
      });
    });

    group('addCustomColor', () {
      test('should add custom color when not exists', () async {
        const customColor = Color(0xFF123456);

        await ColorHelper.addCustomColor(customColor);
        final result = await ColorHelper.getCustomColors();

        expect(result, isNotEmpty);
        expect(result.any((c) => c.value == customColor.value), true);
      });

      test('should not add duplicate custom color', () async {
        const customColor = Color(0xFF123456);

        await ColorHelper.addCustomColor(customColor);
        await ColorHelper.addCustomColor(customColor);
        final result = await ColorHelper.getCustomColors();

        expect(result.where((c) => c.value == customColor.value).length, 1);
      });

      test('should not add predefined color as custom', () async {
        const predefinedColor = Colors.blue;

        await ColorHelper.addCustomColor(predefinedColor);
        final result = await ColorHelper.getCustomColors();

        expect(result.any((c) => c.value == predefinedColor.value), false);
      });
    });

    group('removeCustomColor', () {
      test('should remove custom color', () async {
        const customColor = Color(0xFF123456);

        await ColorHelper.addCustomColor(customColor);
        await ColorHelper.removeCustomColor(customColor);
        final result = await ColorHelper.getCustomColors();

        expect(result.any((c) => c.value == customColor.value), false);
      });

      test('should not remove predefined color', () async {
        const predefinedColor = Colors.blue;

        await ColorHelper.removeCustomColor(predefinedColor);
        final result = await ColorHelper.getAllColors();

        expect(result.any((c) => c.value == predefinedColor.value), true);
      });
    });

    group('isPredefinedColor', () {
      test('should return true for predefined color', () {
        expect(ColorHelper.isPredefinedColor(Colors.blue), true);
      });

      test('should return false for custom color', () {
        const customColor = Color(0xFF123456);
        expect(ColorHelper.isPredefinedColor(customColor), false);
      });
    });
  });
}
