import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/debug/clock_debug_page.dart';

void main() {
  runApp(const ClockDebugApp());
}

class ClockDebugApp extends StatelessWidget {
  const ClockDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, child) => MaterialApp(
        title: 'Clock Debug',
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.blue,
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.system,
        home: child,
      ),
      child: const ClockDebugPage(),
    );
  }
}
