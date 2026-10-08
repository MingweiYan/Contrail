import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Web bootstrap contains no legacy static splash layer', () async {
    final indexHtml = await File('web/index.html').readAsString();
    final bootstrap = await File('web/flutter_bootstrap.js').readAsString();

    expect(indexHtml, isNot(contains('id="splash"')));
    expect(indexHtml, isNot(contains('splash/img/')));
    expect(indexHtml, isNot(contains('removeSplashFromWeb')));
    expect(bootstrap, isNot(contains('removeSplashFromWeb')));
    expect(bootstrap, contains('await appRunner.runApp()'));
  });
}
