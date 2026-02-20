import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/utils/constants.dart';

void main() {
  group('AppConstants', () {
    test('defaultHabitRichTextContent should not be null', () {
      expect(AppConstants.defaultHabitRichTextContent, isNotNull);
    });

    test('defaultHabitRichTextContent should be a non-empty string', () {
      expect(AppConstants.defaultHabitRichTextContent, isNotEmpty);
    });

    test('defaultHabitRichTextContent should contain expected content', () {
      expect(AppConstants.defaultHabitRichTextContent, contains('这些要点要记住'));
      expect(AppConstants.defaultHabitRichTextContent, contains('拉伸区法则'));
      expect(AppConstants.defaultHabitRichTextContent, contains('平台期认知'));
      expect(AppConstants.defaultHabitRichTextContent, contains('靶心练习法'));
    });
  });
}
