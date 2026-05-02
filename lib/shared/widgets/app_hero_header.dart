import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/theme_helper.dart';

class AppHeroHeaderBadgeData {
  final IconData icon;
  final String label;

  const AppHeroHeaderBadgeData({
    required this.icon,
    required this.label,
  });
}

class AppHeroHeaderActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const AppHeroHeaderActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class AppHeroHeader extends StatelessWidget {
  const AppHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.badge,
    this.onTitleTap,
  });

  final String title;
  final String subtitle;
  final List<AppHeroHeaderActionData> actions;
  final AppHeroHeaderBadgeData? badge;
  final VoidCallback? onTitleTap;

  static final EdgeInsets _headerPadding = EdgeInsets.symmetric(
    horizontal: 24.w,
    vertical: 32.h,
  );

  @override
  Widget build(BuildContext context) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    final heroSecondaryForeground =
        ThemeHelper.visualTheme(context).heroSecondaryForeground;

    Widget titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ThemeHelper.textStyleWithTheme(
            context,
            fontSize: AppTypographyConstants.primaryHeroTitleFontSize,
            fontWeight: FontWeight.w800,
            color: heroForeground,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          subtitle,
          style: ThemeHelper.textStyleWithTheme(
            context,
            fontSize: AppTypographyConstants.primaryHeroSubtitleFontSize,
            color: heroSecondaryForeground,
          ),
        ),
      ],
    );

    if (onTitleTap != null) {
      titleBlock = GestureDetector(onTap: onTitleTap, child: titleBlock);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: _headerPadding,
      decoration: ThemeHelper.heroDecoration(context, radius: 30.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              if (badge != null) _HeaderBadge(data: badge!),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              for (int index = 0; index < actions.length; index++) ...[
                Expanded(child: _HeaderAction(data: actions[index])),
                if (index != actions.length - 1) SizedBox(width: 10.w),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.data});

  final AppHeroHeaderBadgeData data;

  @override
  Widget build(BuildContext context) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data.icon,
            size: 14.sp,
            color: heroForeground.withValues(alpha: 0.92),
          ),
          SizedBox(width: 6.w),
          Text(
            data.label,
            style: TextStyle(
              fontSize: AppTypographyConstants.primaryHeroBadgeFontSize,
              fontWeight: FontWeight.w700,
              color: heroForeground.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.data});

  final AppHeroHeaderActionData data;

  @override
  Widget build(BuildContext context) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Column(
            children: [
              Icon(data.icon, size: 20.sp, color: heroForeground),
              SizedBox(height: 8.h),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypographyConstants.primaryHeroActionTitleFontSize,
                  fontWeight: FontWeight.w700,
                  color: heroForeground,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:
                      AppTypographyConstants.primaryHeroActionSubtitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: heroForeground.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
