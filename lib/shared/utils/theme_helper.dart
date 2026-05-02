import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/theme/visual_theme_tokens.dart';
import '../../core/state/theme_provider.dart';
import '../../shared/models/theme_model.dart' as app_theme;
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 主题辅助类，提供统一的主题访问方法和增强的主题能力
class ThemeHelper {
  /// 获取当前主题的颜色方案
  static ColorScheme colorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  /// 获取当前主题的文本主题
  static TextTheme textTheme(BuildContext context) {
    return Theme.of(context).textTheme;
  }

  /// 主色调 - 用于关键操作、高亮元素
  static Color primary(BuildContext context) {
    return colorScheme(context).primary;
  }

  /// 主色调上的文本颜色
  static Color onPrimary(BuildContext context) {
    return colorScheme(context).onPrimary;
  }

  /// 次要颜色 - 用于次要操作
  static Color secondary(BuildContext context) {
    return colorScheme(context).secondary;
  }

  /// 次要颜色上的文本颜色
  static Color onSecondary(BuildContext context) {
    return colorScheme(context).onSecondary;
  }

  /// 背景色
  static Color background(BuildContext context) {
    return colorScheme(context).surface;
  }

  /// 背景上的文本颜色
  static Color onBackground(BuildContext context) {
    return colorScheme(context).onSurface;
  }

  /// 表面色 - 用于卡片、对话框等
  static Color surface(BuildContext context) {
    return colorScheme(context).surface;
  }

  /// 表面上的文本颜色
  static Color onSurface(BuildContext context) {
    return colorScheme(context).onSurface;
  }

  /// 变体表面色 - 用于分组列表项、卡片背景等
  static Color surfaceVariant(BuildContext context) {
    return colorScheme(context).surfaceContainerHighest;
  }

  /// 变体表面上的文本颜色
  static Color onSurfaceVariant(BuildContext context) {
    return colorScheme(context).onSurfaceVariant;
  }

  /// 错误色
  static Color error(BuildContext context) {
    return colorScheme(context).error;
  }

  /// 错误色上的文本颜色
  static Color onError(BuildContext context) {
    return colorScheme(context).onError;
  }

  /// 边框颜色
  static Color outline(BuildContext context) {
    return colorScheme(context).outline;
  }

  /// 判断当前是否为深色主题
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// 获取标题样式
  static TextStyle headlineLarge(BuildContext context) {
    return textTheme(context).headlineLarge!;
  }

  static TextStyle headlineMedium(BuildContext context) {
    return textTheme(context).headlineMedium!;
  }

  static TextStyle headlineSmall(BuildContext context) {
    return textTheme(context).headlineSmall!;
  }

  /// 获取标题样式（旧版）
  static TextStyle titleLarge(BuildContext context) {
    return textTheme(context).titleLarge!;
  }

  static TextStyle titleMedium(BuildContext context) {
    return textTheme(context).titleMedium!;
  }

  static TextStyle titleSmall(BuildContext context) {
    return textTheme(context).titleSmall!;
  }

  /// 获取正文样式
  static TextStyle bodyLarge(BuildContext context) {
    return textTheme(context).bodyLarge!;
  }

  static TextStyle bodyMedium(BuildContext context) {
    return textTheme(context).bodyMedium!;
  }

  static TextStyle bodySmall(BuildContext context) {
    return textTheme(context).bodySmall!;
  }

  /// 获取标签样式
  static TextStyle labelLarge(BuildContext context) {
    return textTheme(context).labelLarge!;
  }

  static TextStyle labelMedium(BuildContext context) {
    return textTheme(context).labelMedium!;
  }

  static TextStyle labelSmall(BuildContext context) {
    return textTheme(context).labelSmall!;
  }

  /// 创建具有主题颜色的TextStyle，自动适应深色/浅色主题
  static TextStyle textStyleWithTheme(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Color? darkModeColor,
    Color? backgroundColor,
    TextDecoration? decoration,
  }) {
    // 如果提供了深色模式专用颜色，则在深色模式下使用该颜色
    final effectiveColor = isDarkMode(context) && darkModeColor != null
        ? darkModeColor
        : (color ?? onSurface(context));

    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: effectiveColor,
      backgroundColor: backgroundColor,
      decoration: decoration,
    );
  }

  /// 应用主题到ElevatedButton
  static ButtonStyle elevatedButtonStyle(
    BuildContext context, {
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    EdgeInsetsGeometry? padding,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? primary(context),
      foregroundColor: foregroundColor ?? onPrimary(context),
      elevation: elevation,
      padding: padding,
    );
  }

  /// 应用主题到OutlinedButton
  static ButtonStyle outlinedButtonStyle(
    BuildContext context, {
    Color? foregroundColor,
    Color? sideColor,
    double? sideWidth,
    EdgeInsetsGeometry? padding,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor ?? primary(context),
      side: BorderSide(
        color: sideColor ?? outline(context),
        width: sideWidth ?? 1.0,
      ),
      padding: padding,
    );
  }

  /// 应用主题到TextButton
  static ButtonStyle textButtonStyle(
    BuildContext context, {
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
  }) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor ?? primary(context),
      padding: padding,
    );
  }

  /// 获取带有主题颜色的卡片样式
  static CardTheme cardTheme(BuildContext context) {
    return CardTheme(
      color: surface(context),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
        side: BorderSide(
          color: outline(context),
          width: ScreenUtil().setWidth(0.5),
        ),
      ),
    );
  }

  static VisualThemeTokens visualTheme(BuildContext context) {
    final extension = Theme.of(context).extension<VisualThemeTokens>();
    if (extension != null) {
      return extension;
    }

    final theme = currentTheme(context);
    return theme.tokensForBrightness(Theme.of(context).brightness);
  }

  static app_theme.AppTheme currentTheme(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false).currentTheme;
  }

  /// 获取当前主题的背景样式
  static app_theme.BackgroundStyle getBackgroundStyle(BuildContext context) {
    final theme = currentTheme(context);
    return isDarkMode(context)
        ? theme.darkBackgroundStyle
        : theme.lightBackgroundStyle;
  }

  /// 根据当前主题生成背景装饰
  static BoxDecoration? generateBackgroundDecoration(BuildContext context) {
    return BoxDecoration(gradient: visualTheme(context).backgroundGradient);
  }

  static BoxDecoration panelDecoration(
    BuildContext context, {
    bool secondary = false,
    double radius = 24,
    bool highlight = false,
  }) {
    final theme = visualTheme(context);
    return BoxDecoration(
      color: secondary ? theme.panelSecondaryColor : theme.panelColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlight ? theme.panelHighlightColor : theme.panelBorderColor,
      ),
      boxShadow: theme.panelShadow,
    );
  }

  static BoxDecoration heroDecoration(
    BuildContext context, {
    double radius = 28,
  }) {
    final theme = visualTheme(context);
    return BoxDecoration(
      gradient: theme.heroGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: theme.panelBorderColor),
      boxShadow: theme.panelShadow,
    );
  }

  static BoxDecoration navigationDecoration(
    BuildContext context, {
    double radius = 24,
  }) {
    final theme = visualTheme(context);
    return BoxDecoration(
      color: theme.navBackground,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: theme.panelBorderColor),
      boxShadow: theme.panelShadow,
    );
  }

  static BoxDecoration selectedNavigationItemDecoration(BuildContext context) {
    final theme = visualTheme(context);
    return BoxDecoration(
      color: theme.navSelectedBackground,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: theme.panelBorderColor),
    );
  }

  static BoxDecoration listCardDecoration(
    BuildContext context, {
    double radius = 22,
  }) {
    return panelDecoration(context, radius: radius);
  }

  static BoxDecoration settingCardDecoration(
    BuildContext context, {
    double radius = 22,
  }) {
    return panelDecoration(context, secondary: true, radius: radius);
  }

  static List<Color> splashColors(BuildContext context) {
    final theme = visualTheme(context);
    return [theme.splashBackground, theme.splashTitleColor];
  }

  /// 根据当前主题样式处理图标
  static Widget styledIcon(
    BuildContext context,
    IconData iconData, {
    double size = 24.0,
    Color? color,
    double? padding,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final iconStyle = themeProvider.currentTheme.iconStyle;
    final defaultColor = color ?? ThemeHelper.primary(context);

    switch (iconStyle) {
      case app_theme.IconStyle.outlined:
        return Container(
          padding: padding != null ? EdgeInsets.all(padding) : null,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: defaultColor,
              width: ScreenUtil().setWidth(1.5),
            ),
          ),
          child: Icon(iconData, size: size, color: defaultColor),
        );

      case app_theme.IconStyle.filled:
        return Container(
          padding: padding != null ? EdgeInsets.all(padding) : null,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: defaultColor,
          ),
          child: Icon(
            iconData,
            size: size,
            color: ThemeHelper.onPrimary(context),
          ),
        );

      case app_theme.IconStyle.gradient:
        return Container(
          padding: padding != null ? EdgeInsets.all(padding) : null,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [defaultColor, defaultColor.withOpacity(0.7)],
            ),
          ),
          child: Icon(
            iconData,
            size: size,
            color: ThemeHelper.onPrimary(context),
          ),
        );

      case app_theme.IconStyle.defaultStyle:
        return Icon(iconData, size: size, color: defaultColor);
    }
  }

  /// 创建带有背景覆盖的图标
  static Widget iconWithBackground(
    BuildContext context,
    IconData iconData, {
    double size = 24.0,
    double backgroundSize = 40.0,
    Color? iconColor,
    Color? backgroundColor,
    BoxShape shape = BoxShape.circle,
    double? borderWidth,
    Color? borderColor,
  }) {
    final defaultIconColor = iconColor ?? ThemeHelper.onPrimary(context);
    final defaultBackgroundColor =
        backgroundColor ?? ThemeHelper.primary(context);
    final defaultBorderColor = borderColor ?? ThemeHelper.outline(context);

    return Container(
      width: backgroundSize,
      height: backgroundSize,
      decoration: BoxDecoration(
        shape: shape,
        color: defaultBackgroundColor,
        border: borderWidth != null
            ? Border.all(color: defaultBorderColor, width: borderWidth)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: ScreenUtil().setWidth(3),
            offset: Offset(0, ScreenUtil().setHeight(2)),
          ),
        ],
      ),
      child: Center(
        child: Icon(iconData, size: size, color: defaultIconColor),
      ),
    );
  }

  /// 创建带有覆盖效果的图标
  static Widget iconWithOverlay(
    BuildContext context,
    IconData iconData, {
    double size = 24.0,
    Color? color,
    double? padding,
    Widget? overlay,
    Alignment overlayAlignment = Alignment.bottomRight,
  }) {
    final defaultColor = color ?? ThemeHelper.primary(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(iconData, size: size, color: defaultColor),
        if (overlay != null)
          Positioned.fill(
            child: Align(alignment: overlayAlignment, child: overlay),
          ),
      ],
    );
  }

  /// 获取主题背景装饰
  static BoxDecoration backgroundDecoration(
    BuildContext context, {
    bool usePattern = false,
  }) {
    return generateBackgroundDecoration(context) ??
        BoxDecoration(color: background(context));
  }

  /// 获取主题输入框装饰
  static InputDecoration inputDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool filled = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: surface(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(8)),
        borderSide: BorderSide(color: outline(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(8)),
        borderSide: BorderSide(
          color: primary(context),
          width: ScreenUtil().setWidth(2),
        ),
      ),
      labelStyle: TextStyle(color: onSurfaceVariant(context)),
      hintStyle: TextStyle(color: onSurfaceVariant(context)),
    );
  }

  /// 确保文本颜色与背景有足够对比度
  static Color ensureTextContrast(Color textColor, Color backgroundColor) {
    // 计算对比度
    final double textLuminance = textColor.computeLuminance();
    final double bgLuminance = backgroundColor.computeLuminance();
    final double contrast = (textLuminance > bgLuminance)
        ? (textLuminance + 0.05) / (bgLuminance + 0.05)
        : (bgLuminance + 0.05) / (textLuminance + 0.05);

    // 如果对比度不足，返回更适合的颜色
    if (contrast < 4.5) {
      return bgLuminance > 0.5 ? Colors.black : Colors.white;
    }

    return textColor;
  }

  /// 获取与背景色对比度最佳的文本颜色
  static Color getOptimalTextColor(
    BuildContext context,
    Color backgroundColor,
  ) {
    // 获取主题中的文本颜色选项
    final textColors = [
      onSurface(context),
      onBackground(context),
      Colors.black,
      Colors.white,
    ];

    // 找出对比度最高的颜色
    Color bestColor = textColors.first;
    double bestContrast = 0.0;

    for (final color in textColors) {
      final double colorLuminance = color.computeLuminance();
      final double bgLuminance = backgroundColor.computeLuminance();
      final double contrast = (colorLuminance > bgLuminance)
          ? (colorLuminance + 0.05) / (bgLuminance + 0.05)
          : (bgLuminance + 0.05) / (colorLuminance + 0.05);

      if (contrast > bestContrast) {
        bestContrast = contrast;
        bestColor = color;
      }
    }

    return bestColor;
  }

  /// 创建带阴影的容器，自动适应深色/浅色主题
  static Widget shadowedContainer(
    BuildContext context,
    Widget child, {
    double borderRadius = 16.0,
    double elevation = 4.0,
  }) {
    final shadowOpacity = isDarkMode(context) ? 0.1 : 0.05;

    return Container(
      decoration: BoxDecoration(
        color: surface(context),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(shadowOpacity * elevation),
            blurRadius: ScreenUtil().setWidth(4 * elevation),
            offset: Offset(0, ScreenUtil().setHeight(2 * elevation)),
          ),
        ],
      ),
      child: child,
    );
  }

  /// 创建渐变背景的容器
  static Widget gradientContainer(
    BuildContext context,
    Widget child, {
    double borderRadius = 16.0,
    List<Color>? colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? [primary(context), secondary(context)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }

  /// 创建带背景图标的按钮
  static Widget iconButtonWithBackground(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed, {
    Color? backgroundColor,
    Color? iconColor,
    double size = 24.0,
    double backgroundSize = 48.0,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: iconWithBackground(
        context,
        icon,
        backgroundSize: backgroundSize,
        iconColor: iconColor,
        backgroundColor: backgroundColor,
      ),
      padding: EdgeInsets.zero,
    );
  }

  /// 创建高亮文本
  static Text highlightedText(
    BuildContext context,
    String text, {
    TextStyle? style,
    Color? highlightColor,
  }) {
    return Text(
      text,
      style: (style ?? TextStyle()).copyWith(
        color: highlightColor ?? primary(context),
      ),
    );
  }

  /// 创建带渐变效果的文本
  static Widget gradientText(
    BuildContext context,
    String text, {
    TextStyle? style,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [primary(context), secondary(context)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: (style ?? TextStyle()).copyWith(
          color: Colors.white, // 渐变文本需要设置为白色
        ),
      ),
    );
  }

  /// 获取主题的时间格式
  static DateFormat get dateFormat {
    return DateFormat('yyyy-MM-dd');
  }

  /// 获取主题的时间格式
  static DateFormat get timeFormat {
    return DateFormat('HH:mm');
  }

  /// 获取主题的日期时间格式
  static DateFormat get dateTimeFormat {
    return DateFormat('yyyy-MM-dd HH:mm');
  }
}
