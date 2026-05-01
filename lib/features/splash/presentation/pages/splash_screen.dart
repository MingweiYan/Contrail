import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' show ScreenUtil;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:contrail/core/routing/app_router.dart';
import 'package:contrail/shared/utils/theme_helper.dart';

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
    final splashColors = ThemeHelper.splashColors(context);
    final visualTheme = ThemeHelper.visualTheme(context);
    final illustrationSize = ScreenUtil().screenWidth * 0.62;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeHelper.generateBackgroundDecoration(context)?.gradient,
          color: splashColors.first,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -ScreenUtil().setHeight(80),
              right: -ScreenUtil().setWidth(50),
              child: Container(
                width: ScreenUtil().setWidth(220),
                height: ScreenUtil().setWidth(220),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeHelper.primary(context).withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -ScreenUtil().setHeight(40),
              left: -ScreenUtil().setWidth(30),
              child: Container(
                width: ScreenUtil().setWidth(180),
                height: ScreenUtil().setWidth(180),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: visualTheme.heroSecondaryForeground.withValues(
                    alpha: 0.10,
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(24)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ScreenUtil().setWidth(14),
                        vertical: ScreenUtil().setHeight(8),
                      ),
                      decoration: BoxDecoration(
                        color: visualTheme.panelColor.withValues(alpha: 0.56),
                        borderRadius: BorderRadius.circular(
                          ScreenUtil().setWidth(999),
                        ),
                        border: Border.all(color: visualTheme.panelBorderColor),
                      ),
                      child: Text(
                        'FOCUS / HABIT / TRACE',
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(11),
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                          color: visualTheme.heroForeground,
                        ),
                      ),
                    ),
                    SizedBox(height: ScreenUtil().setHeight(28)),
                    Container(
                      width: illustrationSize,
                      height: illustrationSize,
                      padding: EdgeInsets.all(ScreenUtil().setWidth(20)),
                      decoration: ThemeHelper.panelDecoration(
                        context,
                        secondary: true,
                        radius: ScreenUtil().setWidth(36),
                      ),
                      child: SvgPicture.asset(
                        'assets/images/cover.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: ScreenUtil().setHeight(28)),
                    Text(
                      'Contrail',
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(36),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: splashColors.last,
                      ),
                    ),
                    SizedBox(height: ScreenUtil().setHeight(12)),
                    Text(
                      'Every step leaves a trace',
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(17),
                        color: visualTheme.heroSecondaryForeground,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: ScreenUtil().setHeight(18)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ScreenUtil().setWidth(16),
                        vertical: ScreenUtil().setHeight(10),
                      ),
                      decoration: BoxDecoration(
                        color: visualTheme.panelColor.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(
                          ScreenUtil().setWidth(16),
                        ),
                        border: Border.all(color: visualTheme.panelBorderColor),
                      ),
                      child: Text(
                        '专注记录 · 习惯沉淀 · 数据回看',
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(13),
                          fontWeight: FontWeight.w600,
                          color: ThemeHelper.onBackground(
                            context,
                          ).withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
