import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' show ScreenUtil;
import 'package:flutter_svg/flutter_svg.dart';
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
      body: Container(
        color: Colors.white, // 使用白色背景，与原配置保持一致
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 显示SVG图像
              SizedBox(
                width: ScreenUtil().setWidth(800),
                height: ScreenUtil().setHeight(800),
                child: SvgPicture.asset(
                  'assets/images/cover.svg',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: ScreenUtil().setHeight(40)),
              // 应用名称或其他文字
              Text(
                'Contrail',
                style: TextStyle(
                  fontSize: ScreenUtil().setSp(36),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
