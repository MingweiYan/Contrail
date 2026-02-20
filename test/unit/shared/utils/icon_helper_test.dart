import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:contrail/shared/utils/icon_helper.dart';

void main() {
  group('IconHelper', () {
    group('getIconData', () {
      test('should return default icon when name is null', () {
        final result = IconHelper.getIconData(null, logError: false);

        expect(result, equals(Icons.book));
      });

      test('should return default icon when name is empty', () {
        final result = IconHelper.getIconData('', logError: false);

        expect(result, equals(Icons.book));
      });

      test('should return correct icon for valid name', () {
        final result = IconHelper.getIconData('book', logError: false);

        expect(result, equals(Icons.book));
      });

      test('should return default icon for invalid name', () {
        final result = IconHelper.getIconData('invalid_icon_name', logError: false);

        expect(result, equals(Icons.book));
      });
    });

    group('getIconName', () {
      test('should return default icon name when iconData is null', () {
        final result = IconHelper.getIconName(null);

        expect(result, equals('book'));
      });

      test('should return correct name for valid iconData', () {
        final result = IconHelper.getIconName(Icons.book);

        expect(result, equals('book'));
      });

      test('should return default name for unknown iconData', () {
        final unknownIcon = const IconData(0x1234);
        final result = IconHelper.getIconName(unknownIcon);

        expect(result, equals('book'));
      });
    });

    group('getIconsByCategory', () {
      test('should return map with categories and icons', () {
        final result = IconHelper.getIconsByCategory();

        expect(result, isNotNull);
        expect(result, isNotEmpty);
        expect(result.containsKey('学习类'), isTrue);
        expect(result['学习类'], isNotEmpty);
      });
    });
  });
}
