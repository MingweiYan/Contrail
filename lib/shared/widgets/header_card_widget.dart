import 'package:flutter/material.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

/// 统计页面的功能卡片组件
/// 用于显示各种功能按钮，如视图切换、数据显示、操作按钮等
class StatisticsCardWidget extends StatelessWidget {
  /// 卡片的图标（可选）
  final IconData? icon;

  /// 卡片的文本内容（可选，与图标二选一）
  final String? text;

  /// 卡片的标题
  final String title;

  /// 点击事件回调
  final VoidCallback onTap;

  /// 文本样式（可选，用于自定义文本样式）
  final TextStyle? textStyle;

  /// 图标颜色（可选，用于自定义图标颜色）
  final Color? iconColor;

  const StatisticsCardWidget({
    super.key,
    this.icon,
    this.text,
    required this.title,
    required this.onTap,
    this.textStyle,
    this.iconColor,
  }) : assert(icon != null || text != null, '必须提供icon或text中的一个');

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          HeaderCardWidgetConstants.statisticsCardBorderRadius,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          HeaderCardWidgetConstants.statisticsCardBorderRadius,
        ),
        child: Container(
          width: HeaderCardWidgetConstants.statisticsCardWidth,
          height: HeaderCardWidgetConstants.statisticsCardHeight,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 根据提供的数据显示图标或文本
              if (icon != null)
                Icon(
                  icon,
                  size: HeaderCardWidgetConstants.statisticsCardIconSize,
                  color: iconColor ?? Colors.black,
                )
              else
                Text(
                  text!,
                  style:
                      textStyle ??
                      TextStyle(
                        fontSize: HeaderCardWidgetConstants
                            .statisticsCardTextFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                ),
              SizedBox(height: HeaderCardWidgetConstants.statisticsCardSpacing),
              Text(
                title,
                style: TextStyle(
                  fontSize:
                      HeaderCardWidgetConstants.statisticsCardTitleFontSize,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
