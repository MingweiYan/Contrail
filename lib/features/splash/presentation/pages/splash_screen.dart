import 'package:flutter/material.dart';
import 'package:contrail/core/routing/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 显示2秒后跳转到主页
    Future.delayed(const Duration(seconds: 2), () {
      AppRouter.router.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: Colors.white,
        child: SizedBox.expand(
          child: Image.asset(
            'assets/images/cover2_1.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
