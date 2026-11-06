import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

Future<void> downloadReportPng(Uint8List imageBytes, String fileName) async {
  final blob = Blob([imageBytes.toJS].toJS, BlobPropertyBag(type: 'image/png'));
  final url = URL.createObjectURL(blob);
  try {
    final link = HTMLAnchorElement()
      ..href = url
      ..download = '$fileName.png';
    document.body?.append(link);
    link.click();
    link.remove();
  } finally {
    URL.revokeObjectURL(url);
  }
}
