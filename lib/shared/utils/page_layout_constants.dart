import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

/// 基础布局常量类 - 所有页面共用的通用布局参数
class BaseLayoutConstants {
  // 通用间距
  static final double spacingSmall = ScreenUtil().setHeight(8);
  static final double spacingMedium = ScreenUtil().setHeight(16);
  static final double spacingLarge = ScreenUtil().setHeight(24);
  static final double spacingXLarge = ScreenUtil().setHeight(32);
  
  // 通用圆角
  static final double borderRadiusSmall = ScreenUtil().setWidth(8);
  static final double borderRadiusMedium = ScreenUtil().setWidth(12);
  static final double borderRadiusLarge = ScreenUtil().setWidth(16);
  static final double borderRadiusXLarge = ScreenUtil().setWidth(20);
  
  // 通用边距
  static final EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(16),
    vertical: ScreenUtil().setHeight(8),
  );
  
  // 通用字体大小
  static final double fontSizeSmall = ScreenUtil().setSp(14);
  static final double fontSizeMedium = ScreenUtil().setSp(16);
  static final double fontSizeLarge = ScreenUtil().setSp(18);
  static final double fontSizeXLarge = ScreenUtil().setSp(20);
}

/// 数据备份页面专用常量
class DataBackupPageConstants extends BaseLayoutConstants {
  // Container内边距
  static final EdgeInsets containerPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  
  // 宽度相关参数
  static final double width_8 = ScreenUtil().setWidth(8.0);
  static final double width_16 = ScreenUtil().setWidth(16.0);
  static final double width_20 = ScreenUtil().setWidth(20.0);
  
  // 按钮相关参数
  static final double buttonHeight = ScreenUtil().setHeight(48);
  
  // 备份项相关参数
  static final double backupItemHeight = ScreenUtil().setHeight(80);
  static final double backupItemBorderRadius = ScreenUtil().setWidth(12);
  
  // 分隔线高度
  static final double dividerHeight = ScreenUtil().setHeight(1);
  
  // 字体大小相关参数
  static final double fontSize_14 = ScreenUtil().setSp(14.0);
  static final double fontSize_16 = ScreenUtil().setSp(16.0);
  static final double fontSize_18 = ScreenUtil().setSp(18.0);
  static final double fontSize_29 = ScreenUtil().setSp(29.0);
  
  // 间距相关参数
  static final double verticalSpacing = ScreenUtil().setHeight(16);
  static final double sectionSpacing = ScreenUtil().setHeight(24);
}

/// 全屏时钟页面专用常量
class FullscreenClockPageConstants extends BaseLayoutConstants {
  // 时钟与提示文字间距
  static final double clockToHintSpacing = ScreenUtil().setHeight(40.0);
  
  // 字体大小相关参数
  static final double mainClockFontSize = ScreenUtil().setSp(120.0);
  static final double hintTextFontSize = ScreenUtil().setSp(24.0);
}

/// JSON编辑器页面专用常量
class JsonEditorPageConstants extends BaseLayoutConstants {
  // 容器内边距
  static final EdgeInsets containerPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  
  // 编辑器内边距
  static final EdgeInsets editorPadding = EdgeInsets.all(ScreenUtil().setWidth(8));
  
  // 按钮相关参数
  static final double buttonVerticalPadding = ScreenUtil().setHeight(16);
  static final double buttonBorderRadius = ScreenUtil().setWidth(12);
  
  // 字体大小相关参数
  static final double descriptionFontSize = ScreenUtil().setSp(18);
  static final double buttonFontSize = ScreenUtil().setSp(20);
}

/// 习惯管理页面专用常量
class HabitManagementPageConstants extends BaseLayoutConstants {
  // 头部容器相关参数
  static final EdgeInsets headerPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(24),
    vertical: ScreenUtil().setHeight(32),
  );
  static final double headerBorderRadius = ScreenUtil().setWidth(30);
  
  // 字体大小相关参数
  static final double titleFontSize = ScreenUtil().setSp(32);
  static final double subtitleFontSize = ScreenUtil().setSp(20);
  static final double emptyStateTitleFontSize = ScreenUtil().setSp(24);
  static final double emptyStateSubtitleFontSize = ScreenUtil().setSp(18);
  static final double emptyStateIconSize = ScreenUtil().setSp(80);
  
  // 间距相关参数
  static final double smallSpacing = ScreenUtil().setHeight(8);
  static final double mediumSpacing = ScreenUtil().setHeight(12);
  static final double largeSpacing = ScreenUtil().setHeight(24);
  
  // 列表相关参数
  static final EdgeInsets listPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(16),
    vertical: ScreenUtil().setHeight(8),
  );
  static final EdgeInsets contentPadding = EdgeInsets.only(top: ScreenUtil().setHeight(24));
}

/// 添加习惯页面专用常量
class AddHabitPageConstants extends BaseLayoutConstants {
  // 头部容器相关参数
  static final EdgeInsets headerPadding = EdgeInsets.all(ScreenUtil().setWidth(24));
  
  // 表单容器相关参数
  static final EdgeInsets formPadding = EdgeInsets.all(ScreenUtil().setWidth(24));
  static final double cardBorderRadius = ScreenUtil().setWidth(16);
  static final double cardPadding = ScreenUtil().setWidth(16);
  
  // 图标选择相关参数
  static final double iconContainerSize = ScreenUtil().setWidth(100);
  static final double iconContainerRadius = ScreenUtil().setWidth(100);
  static final double iconSize = ScreenUtil().setSp(48);
  
  // 富文本编辑器相关参数
  static final double richTextMinHeight = ScreenUtil().setHeight(120);
  static final double richTextMaxHeight = ScreenUtil().setHeight(240);
  static final double editIconSize = ScreenUtil().setSp(16);
  static final double editIconSpacing = ScreenUtil().setWidth(4);
  
  // 颜色选择器相关参数
  static final double colorGridSpacing = ScreenUtil().setWidth(12);
  static final double colorBorderWidth = ScreenUtil().setWidth(1);
  static final double colorSelectedBorderWidth = ScreenUtil().setWidth(3);
  static final double colorCheckIconSize = ScreenUtil().setSp(18);
  
  // 字体大小相关参数
  static final double titleFontSize = ScreenUtil().setSp(24);
  static final double subtitleFontSize = ScreenUtil().setSp(20);
  static final double sectionTitleFontSize = ScreenUtil().setSp(18);
  static final double inputFontSize = ScreenUtil().setSp(20);
  static final double hintFontSize = ScreenUtil().setSp(20);
  
  // 间距相关参数
  static final double extraSmallSpacing = ScreenUtil().setHeight(8);
  static final double smallSpacing = ScreenUtil().setHeight(12);
  static final double mediumSpacing = ScreenUtil().setHeight(16);
  static final double largeSpacing = ScreenUtil().setHeight(24);
  static final double xLargeSpacing = ScreenUtil().setHeight(32);
  
  // 按钮相关参数
  static final EdgeInsets buttonVerticalPadding = EdgeInsets.symmetric(vertical: ScreenUtil().setHeight(16));
  static final double buttonBorderRadius = ScreenUtil().setWidth(16);
}

/// 图标选择器页面专用常量
class IconSelectorPageConstants extends BaseLayoutConstants {
  // 页面容器相关参数
  static final EdgeInsets pagePadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  
  // 搜索框相关参数
  static final double searchBorderRadius = ScreenUtil().setWidth(12);
  
  // 字体大小相关参数
  static final double emptyStateFontSize = ScreenUtil().setSp(18);
  static final double categoryTitleFontSize = ScreenUtil().setSp(20);
  static final double iconSize = ScreenUtil().setSp(28);
  
  // 间距相关参数
  static final double smallSpacing = ScreenUtil().setHeight(8);
  static final double mediumSpacing = ScreenUtil().setHeight(12);
  static final double largeSpacing = ScreenUtil().setHeight(16);
  
  // 图标网格相关参数
  static const int gridCrossAxisCount = 5;
  static final double gridCrossAxisSpacing = ScreenUtil().setWidth(16);
  static final double gridMainAxisSpacing = ScreenUtil().setHeight(16);
  static const double gridChildAspectRatio = 0.8;
  static final double iconContainerSize = ScreenUtil().setWidth(56);
  static final double selectedBorderWidth = ScreenUtil().setWidth(2);
  static final double dividerHeight = ScreenUtil().setHeight(16);
}

/// 习惯追踪页面专用常量
class HabitTrackingPageConstants extends BaseLayoutConstants {
  // 按钮相关参数
  static final EdgeInsets modeButtonPadding = EdgeInsets.symmetric(
    vertical: ScreenUtil().setHeight(12),
    horizontal: ScreenUtil().setWidth(20),
  );
  static final double buttonBorderRadius = ScreenUtil().setWidth(12);
  static final EdgeInsets controlButtonPadding = EdgeInsets.all(ScreenUtil().setWidth(24));
  static final EdgeInsets startButtonPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(48),
    vertical: ScreenUtil().setHeight(16),
  );
  static final EdgeInsets settingsButtonPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(24),
    vertical: ScreenUtil().setHeight(12),
  );
  
  // 字体大小相关参数
  static final double buttonFontSize = ScreenUtil().setSp(16);
  static final double startButtonFontSize = ScreenUtil().setSp(18);
  static final double iconSize = ScreenUtil().setSp(16);
  static final double largeIconSize = ScreenUtil().setSp(32);
  static final double pomodoroStatusFontSize = ScreenUtil().setSp(20);
  
  // 间距相关参数
  static final double extraSmallSpacing = ScreenUtil().setHeight(8);
  static final double smallSpacing = ScreenUtil().setHeight(10);
  static final double mediumSpacing = ScreenUtil().setHeight(16);
  static final double largeSpacing = ScreenUtil().setHeight(24);
  static final double extraLargeSpacing = ScreenUtil().setHeight(40);
  static final double maxLargeSpacing = ScreenUtil().setHeight(50);
  static final double buttonSpacing = ScreenUtil().setWidth(32);
  
  // 容器相关参数
  static final double descriptionHeight = ScreenUtil().setHeight(260);
  static final double settingsButtonHeight = ScreenUtil().setHeight(56);
  static final EdgeInsets descriptionMargin = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(24),
    vertical: 0,
  );
  static final EdgeInsets descriptionPadding = EdgeInsets.fromLTRB(
    ScreenUtil().setWidth(16),
    ScreenUtil().setHeight(8),
    ScreenUtil().setWidth(16),
    ScreenUtil().setHeight(16),
  );
  static final double descriptionBorderRadius = ScreenUtil().setWidth(16);
  static final double descriptionBorderWidth = ScreenUtil().setWidth(1);
  static final EdgeInsets bottomPadding = EdgeInsets.only(
    bottom: ScreenUtil().setHeight(40),
  );
  static final EdgeInsets containerPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
}

/// 全屏编辑器页面专用常量
class FullEditorPageConstants extends BaseLayoutConstants {
  // 编辑器相关参数
  static final EdgeInsets editorContainerPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  static final EdgeInsets editorPadding = EdgeInsets.all(ScreenUtil().setWidth(8));
}

/// 统计页面专用常量
class StatisticsPageConstants extends BaseLayoutConstants {
  // 头部容器相关参数
  static final double headerBorderRadius = ScreenUtil().setWidth(30);
  static final EdgeInsets headerPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(24),
    vertical: ScreenUtil().setHeight(32),
  );
  
  // 标题相关参数
  static final double titleFontSize = ScreenUtil().setSp(32);
  static final double subtitleFontSize = ScreenUtil().setSp(20);
  
  // 间距相关参数
  static final double titleSubtitleSpacing = ScreenUtil().setHeight(8);
  static final double subtitleCardSpacing = ScreenUtil().setHeight(24);
}

/// 习惯详情统计页面专用常量
class HabitDetailStatisticsPageConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final EdgeInsets moduleContainerMargin = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(16),
    vertical: ScreenUtil().setHeight(12),
  );
  static final double moduleContainerBorderRadius = ScreenUtil().setWidth(16);
  static final EdgeInsets moduleContainerPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  
  // 标题相关参数
  static final double sectionTitleFontSize = ScreenUtil().setSp(24);
  static final double timeRangeTitleFontSize = ScreenUtil().setSp(20);
  static final double timeRangeLabelFontSize = ScreenUtil().setSp(16);
  static final double completionRateFontSize = ScreenUtil().setSp(18);
  
  // 间距相关参数
  static final double titleSectionSpacing = ScreenUtil().setHeight(16);
  static final double smallSectionSpacing = ScreenUtil().setHeight(8);
  static final double statusSectionSpacing = ScreenUtil().setHeight(12);
  static final double statusIndicatorSpacing = ScreenUtil().setWidth(8);
  static final double buttonSpacing = ScreenUtil().setWidth(8);
  static final double contentSpacing = ScreenUtil().setWidth(16);
  static final double bottomSpacing = ScreenUtil().setHeight(80);
  static final EdgeInsets bodyPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  
  // 图表相关参数
  static final double chartContainerHeight = ScreenUtil().setHeight(300);
  static final EdgeInsets chartContainerPadding = EdgeInsets.only(left: ScreenUtil().setWidth(40));
  static final EdgeInsets pieChartPadding = EdgeInsets.only(right: ScreenUtil().setWidth(10));
  static final double calendarContainerHeight = ScreenUtil().setHeight(450);
  
  // 指示器相关参数
  static final double statusIndicatorSize = ScreenUtil().setWidth(16);
}

/// 个人资料页面专用常量
class ProfilePageConstants extends BaseLayoutConstants {
  // 头部容器相关参数
  static final EdgeInsets headerPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(24),
    vertical: ScreenUtil().setHeight(32),
  );
  static final double headerBorderRadius = ScreenUtil().setWidth(30);
  static final EdgeInsets contentPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  
  // 标题相关参数
  static final double titleFontSize = ScreenUtil().setSp(32);
  static final double subtitleFontSize = ScreenUtil().setSp(20);
  
  // 间距相关参数
  static final double titleSubtitleSpacing = ScreenUtil().setHeight(8);
  static final EdgeInsets cardMargin = EdgeInsets.all(ScreenUtil().setWidth(16));
  static final double cardBorderRadius = ScreenUtil().setWidth(20);
  
  // 用户信息卡片相关参数
  static final EdgeInsets userInfoPadding = EdgeInsets.all(ScreenUtil().setWidth(24));
  static final double avatarRadius = ScreenUtil().setWidth(60);
  static final double avatarIconSize = ScreenUtil().setSp(60);
  static final double avatarUsernameSpacing = ScreenUtil().setHeight(16);
  
  // 文本字段相关参数
  static final double textFieldBorderRadius = ScreenUtil().setWidth(12);
  static final EdgeInsets textFieldPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(12),
    vertical: ScreenUtil().setHeight(4),
  );
  static final double labelFontSize = ScreenUtil().setSp(26);
  static final double inputFontSize = ScreenUtil().setSp(24);
  static final double usernameButtonSpacing = ScreenUtil().setHeight(20);
  
  // 按钮相关参数
  static final EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(32),
    vertical: ScreenUtil().setHeight(12),
  );
  static final double buttonBorderRadius = ScreenUtil().setWidth(30);
  static final double buttonFontSize = ScreenUtil().setSp(18);
  
  // 设置卡片相关参数
  static final EdgeInsets settingsContainerMargin = EdgeInsets.all(ScreenUtil().setWidth(16));
  static final double settingsContainerBorderRadius = ScreenUtil().setWidth(20);
  static final double settingsCardTopBorderRadius = ScreenUtil().setWidth(20);
  
  // 列表项相关参数
  static final double listTileTitleFontSize = ScreenUtil().setSp(20);
  static final double listTileSubtitleFontSize = ScreenUtil().setSp(16);
}

/// 习惯项组件专用常量
class HabitItemWidgetConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final double containerBorderRadius = ScreenUtil().setWidth(20);
  static final EdgeInsets containerPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(20),
    vertical: ScreenUtil().setHeight(28),
  );
  static final EdgeInsets cardMargin = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(16),
    vertical: ScreenUtil().setHeight(10),
  );
  static final EdgeInsets backgroundContainerMargin = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(16),
    vertical: ScreenUtil().setHeight(10),
  );
  
  // 图标区域参数
  static final double iconContainerSize = ScreenUtil().setWidth(64);
  static final double iconContainerBorderRadius = ScreenUtil().setWidth(16);
  
  // 内容区域参数
  static final double contentSpacing = ScreenUtil().setWidth(20);
  static final double contentRightPadding = ScreenUtil().setWidth(60);
  
  // 文本相关参数
  static final double habitNameFontSize = ScreenUtil().setSp(18);
  static final double habitDescriptionFontSize = ScreenUtil().setSp(16);
  static final double completedTodayFontSize = ScreenUtil().setSp(12);
  
  // 间距相关参数
  static final double nameDescriptionSpacing = ScreenUtil().setHeight(4);
  static final double descriptionProgressSpacing = ScreenUtil().setHeight(8);
  static final double progressIndicatorHeight = 4.0;
  static final double progressIndicatorSpacing = ScreenUtil().setHeight(4);
  
  // 右侧操作按钮参数
  static final double actionButtonRight = ScreenUtil().setWidth(24);
  static final double actionButtonTop = ScreenUtil().setHeight(50);
  static final double actionButtonSize = ScreenUtil().setWidth(44);
  static final double actionButtonBorderRadius = ScreenUtil().setWidth(12);
  static final double actionButtonIconSize = ScreenUtil().setSp(20);
  
  // 滑动删除参数
  static final double deleteIconSpacing = ScreenUtil().setWidth(16);
  static final double deleteTextIconSpacing = ScreenUtil().setWidth(24);
}

/// 番茄钟设置对话框专用常量
class PomodoroSettingsDialogConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final double dialogBorderRadius = ScreenUtil().setWidth(24);
  static final EdgeInsets dialogPadding = EdgeInsets.all(ScreenUtil().setWidth(24));
  
  // 标题相关参数
  static final double titleFontSize = ScreenUtil().setSp(24);
  static final double titleSpacing = ScreenUtil().setHeight(24);
  
  // 标签相关参数
  static final double labelFontSize = ScreenUtil().setSp(22);
  static final double labelValueSpacing = ScreenUtil().setHeight(8);
  
  // 值显示参数
  static final double valueFontSize = ScreenUtil().setSp(20);
  
  // 按钮相关参数
  static final double buttonBorderRadius = ScreenUtil().setWidth(12);
  static final EdgeInsets buttonPadding = EdgeInsets.all(ScreenUtil().setWidth(12));// 图标相关参数
  static final double buttonIconSize = ScreenUtil().setSp(20);
  static final double buttonSpacing = ScreenUtil().setWidth(16);
  
  // 间距相关参数
  static final double sectionSpacing = ScreenUtil().setHeight(20);
  static final double buttonTopSpacing = ScreenUtil().setHeight(24);
}

/// 统计详情视图专用常量
class StatisticsDetailViewConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final EdgeInsets containerMargin = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(16),
    vertical: ScreenUtil().setHeight(12),
  );
  static final double containerBorderRadius = ScreenUtil().setWidth(16);
  static final EdgeInsets containerPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  
  // 文本相关参数
  static final double titleFontSize = ScreenUtil().setSp(24);
  static final double subtitleFontSize = ScreenUtil().setSp(20);
  static final double legendFontSize = ScreenUtil().setSp(18);
  
  // 间距相关参数
  static final double titleSpacing = ScreenUtil().setHeight(16);
  static final double legendItemSpacing = ScreenUtil().setWidth(12);
  static final double legendRunSpacing = ScreenUtil().setHeight(8);
  static final double bottomSpacing = ScreenUtil().setHeight(80);
}

/// 日历视图专用常量
class CalendarViewConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final EdgeInsets containerMargin = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(16),
    vertical: ScreenUtil().setHeight(12),
  );
  static final double containerBorderRadius = ScreenUtil().setWidth(16);
  static final EdgeInsets containerPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  
  // 文本相关参数
  static final double titleFontSize = ScreenUtil().setSp(24);
  
  // 间距相关参数
  static final double titleSpacing = ScreenUtil().setHeight(16);
}

/// 时间轴视图专用常量
class TimelineViewConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final EdgeInsets containerMargin = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(16),
    vertical: ScreenUtil().setHeight(12),
  );
  static final double containerBorderRadius = ScreenUtil().setWidth(16);
  static final EdgeInsets containerPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  
  // 文本相关参数
  static final double titleFontSize = ScreenUtil().setSp(24);
  
  // 间距相关参数
  static final double titleSpacing = ScreenUtil().setHeight(16);
  static final double buttonTopSpacing = ScreenUtil().setHeight(24);
}

/// 补充打卡对话框专用常量
class SupplementCheckInDialogConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final double dialogBorderRadius = ScreenUtil().setWidth(24);
  static final EdgeInsets dialogPadding = EdgeInsets.all(ScreenUtil().setWidth(24));
  
  // 标题相关参数
  static final double titleFontSize = ScreenUtil().setSp(24);
  static final double titleSpacing = ScreenUtil().setHeight(24);
  
  // 标签相关参数
  static final double labelFontSize = ScreenUtil().setSp(18);
  static final double labelSpacing = ScreenUtil().setHeight(8);
  static final double timeLabelFontSize = ScreenUtil().setSp(20);
  
  // 下拉框相关参数
  static final double dropdownBorderRadius = ScreenUtil().setWidth(12);
  static final EdgeInsets dropdownPadding = EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(12));
  
  // 间距相关参数
  static final double sectionSpacing = ScreenUtil().setHeight(20);
  static final double dateTimeSectionSpacing = ScreenUtil().setHeight(16);
  
  // 按钮相关参数
  static final double buttonBorderRadius = ScreenUtil().setWidth(12);
  static final double buttonHeight = ScreenUtil().setHeight(50);
  static final double buttonFontSize = ScreenUtil().setSp(18);
  static final double buttonSpacing = ScreenUtil().setHeight(16);
  static final EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(24),
    vertical: ScreenUtil().setHeight(12),
  );
  static final double buttonBottomSpacing = ScreenUtil().setHeight(24);
  
  // 输入框相关参数
  static final double inputHeight = ScreenUtil().setHeight(50);
  static final double inputFontSize = ScreenUtil().setSp(16);
  
  // 列表相关参数
  static final double listItemHeight = ScreenUtil().setHeight(60);
  static final double listItemFontSize = ScreenUtil().setSp(18);
  
  // 时长选择相关参数
  static final double durationLabelFontSize = ScreenUtil().setSp(18);
  static final double durationSliderSpacing = ScreenUtil().setHeight(8);
  static final double durationTextFontSize = ScreenUtil().setSp(18);
}

/// 统计图表组件专用常量
class StatisticsChartWidgetConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final EdgeInsets containerMargin = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(16),
    vertical: ScreenUtil().setHeight(8),
  );
  static final double containerBorderRadius = ScreenUtil().setWidth(16);
  static final EdgeInsets containerPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  
  // 文本相关参数
  static final double chartTitleFontSize = ScreenUtil().setSp(18);
  
  // 图表相关参数
  static final double lineWidth = ScreenUtil().setWidth(3);
  static final double dotRadiusSelected = ScreenUtil().setWidth(6);
  static final double dotRadiusNormal = ScreenUtil().setWidth(4);
  static final double dotStrokeWidth = ScreenUtil().setWidth(2);
  
  // 标题相关参数
  static final EdgeInsets titlePadding = EdgeInsets.all(ScreenUtil().setWidth(8));
}



/// 时间轴视图组件专用常量
class TimelineViewWidgetConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final EdgeInsets containerPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(16),
    vertical: ScreenUtil().setHeight(12),
  );
  static final double contentBorderRadius = ScreenUtil().setWidth(12);
  static final EdgeInsets contentPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  static final double containerBorderRadius = ScreenUtil().setWidth(16);
  static final EdgeInsets headerPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(24),
    vertical: ScreenUtil().setHeight(24),
  );
  
  // 文本相关参数
  static final double titleFontSize = ScreenUtil().setSp(20);
  static final double subtitleFontSize = ScreenUtil().setSp(14);
  static final double habitNameFontSize = ScreenUtil().setSp(20);
  static final double timeFontSize = ScreenUtil().setSp(16);
  static final double durationFontSize = ScreenUtil().setSp(16);
  
  // 时间轴相关参数
  static final double timelineWidth = ScreenUtil().setWidth(2);
  static final double timelineItemSpacing = ScreenUtil().setHeight(24);
  static final double timelineIconSize = ScreenUtil().setWidth(40);
  static final double timelineDotSize = ScreenUtil().setWidth(12);
  static final double timelineLeft = ScreenUtil().setWidth(26);
  static final double timelineTop = ScreenUtil().setHeight(6);
  static final double timelineMainWidth = ScreenUtil().setWidth(3);
  
  // 节点相关参数
  static final double nodeContainerWidth = ScreenUtil().setWidth(56);
  static final double nodeContainerHeight = ScreenUtil().setHeight(48);
  static final double nodeSize = ScreenUtil().setWidth(48);
  static final double nodeBorderWidth = ScreenUtil().setWidth(2);
  static final double nodeIconSize = ScreenUtil().setSp(40);
  static final double emptyNodeSize = ScreenUtil().setWidth(20);
  
  // 阴影相关参数
  static final double nodeShadowSpreadRadius = ScreenUtil().setWidth(2);
  static final double nodeShadowBlurRadius = ScreenUtil().setWidth(4);
  static final double contentShadowSpreadRadius = ScreenUtil().setWidth(2);
  static final double contentShadowBlurRadius = ScreenUtil().setWidth(8);
  static final double contentShadowOffsetY = ScreenUtil().setHeight(2);
  
  // 间距相关参数
  static final double itemSpacing = ScreenUtil().setHeight(16);
  static final double contentLeftMargin = ScreenUtil().setWidth(12);
  static final double timeSpacing = ScreenUtil().setHeight(6);
}

/// 备份恢复确认对话框专用常量
class BackupRestoreConfirmationDialogConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final double dialogBorderRadius = ScreenUtil().setWidth(20);
  static final EdgeInsets dialogPadding = EdgeInsets.all(ScreenUtil().setWidth(20));
  
  // 文本相关参数
  static final double titleFontSize = ScreenUtil().setSp(18);
  static final double contentFontSize = ScreenUtil().setSp(18);
  static final double buttonFontSize = ScreenUtil().setSp(18);
  
  // 按钮相关参数
  static final double buttonBorderRadius = ScreenUtil().setWidth(12);
}

/// 备份删除确认对话框专用常量
class BackupDeleteConfirmationDialogConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final double dialogBorderRadius = ScreenUtil().setWidth(20);
  static final EdgeInsets dialogPadding = EdgeInsets.all(ScreenUtil().setWidth(20));
  
  // 文本相关参数
  static final double titleFontSize = ScreenUtil().setSp(18);
  static final double contentFontSize = ScreenUtil().setSp(18);
  static final double buttonFontSize = ScreenUtil().setSp(18);
  
  // 按钮相关参数
  static final double buttonBorderRadius = ScreenUtil().setWidth(12);
}

/// 头部卡片组件专用常量
class HeaderCardWidgetConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final double cardBorderRadius = ScreenUtil().setWidth(30);
  static final EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: ScreenUtil().setWidth(24),
    vertical: ScreenUtil().setHeight(32),
  );
  
  // 统计卡片组件参数
  static final double statisticsCardBorderRadius = ScreenUtil().setWidth(12);
  static final double statisticsCardWidth = ScreenUtil().setWidth(80);
  static final double statisticsCardHeight = ScreenUtil().setHeight(80);
  static final double statisticsCardIconSize = ScreenUtil().setSp(28);
  static final double statisticsCardTextFontSize = ScreenUtil().setSp(20);
  static final double statisticsCardTitleFontSize = ScreenUtil().setSp(16);
  static final double statisticsCardSpacing = ScreenUtil().setHeight(4);
}

/// 时钟组件专用常量
class ClockWidgetConstants extends BaseLayoutConstants {
  // 文本相关参数
  static final double clockFontSize = ScreenUtil().setSp(96);
  static final double amPmFontSize = ScreenUtil().setSp(32);
  static final double dateFontSize = ScreenUtil().setSp(24);
  static final double weekdayFontSize = ScreenUtil().setSp(18);
  static final double timeFontSize = ScreenUtil().setSp(48);
  static final double modeTextFontSize = ScreenUtil().setSp(24);
  
  // 容器相关参数
  static final double shadowBlurRadius = ScreenUtil().setWidth(15);
  static final double shadowOffsetY = ScreenUtil().setHeight(5);
  
  // 图表相关参数
  static final double circleStrokeWidth = ScreenUtil().setWidth(14);
  
  // 间距相关参数
  static final double timeModeSpacing = ScreenUtil().setHeight(12);
}





/// 主题选择页面专用常量
class ThemeSelectionPageConstants extends BaseLayoutConstants {
  // 标题相关参数
  static final double titleFontSize = ScreenUtil().setSp(24);
  
  // 间距相关参数
  static final double titleGridSpacing = ScreenUtil().setHeight(12);
  static final double gridCrossAxisSpacing = ScreenUtil().setWidth(16);
  static final double gridMainAxisSpacing = ScreenUtil().setWidth(16);
  
  // 网格相关参数
  static const double gridChildAspectRatio = 2.0 / 1;
  
  // 边框相关参数
  static final double selectedBorderWidth = ScreenUtil().setWidth(3);
  static final double borderWidth = ScreenUtil().setWidth(1);
  static final double borderRadius = ScreenUtil().setWidth(12);
  
  // 容器相关参数
  static final EdgeInsets containerPadding = EdgeInsets.all(ScreenUtil().setWidth(16));
  
  // 文本相关参数
  static final double themeNameFontSize = ScreenUtil().setSp(20);
  
  // 图标相关参数
  static final double checkIconSpacing = ScreenUtil().setHeight(8);
  static final double checkIconSize = ScreenUtil().setSp(22);
}

/// 个性化设置页面专用常量
class PersonalizationSettingsPageConstants extends BaseLayoutConstants {
  // 容器相关参数
  static final double containerTopMargin = ScreenUtil().setHeight(16);
  static final EdgeInsets containerPadding = EdgeInsets.all(ScreenUtil().setWidth(20));
  static final double containerBorderRadius = ScreenUtil().setWidth(20);
  
  // 文本相关参数
  static final double titleFontSize = ScreenUtil().setSp(22);
  static final double descriptionFontSize = ScreenUtil().setSp(16);
  static final double optionFontSize = ScreenUtil().setSp(18);
  static final double hintFontSize = ScreenUtil().setSp(14);
  
  // 间距相关参数
  static final double titleDescriptionSpacing = ScreenUtil().setHeight(8);
  static final double descriptionOptionsSpacing = ScreenUtil().setHeight(20);
  static final double optionsSpacing = ScreenUtil().setWidth(16);
  static final double containerBottomMargin = ScreenUtil().setHeight(16);
  
  // 单选框相关参数
  static final double radioBorderRadius = ScreenUtil().setWidth(12);
}

/// 统计分享结果页面专用常量
class StatsShareResultPageConstants extends BaseLayoutConstants {
  // 标题相关参数
  static final double sectionTitleFontSize = ScreenUtil().setSp(20);
  static final double axisLabelFontSize = ScreenUtil().setSp(18);
  static final double pieChartTitleFontSize = ScreenUtil().setSp(18);
  static final double activePieChartTitleFontSize = ScreenUtil().setSp(18);
  static final double pieChartLegendFontSize = ScreenUtil().setSp(18);
  
  // 间距相关参数
  static final double titleChartSpacing = ScreenUtil().setHeight(20);
  static final double pieChartPadding = ScreenUtil().setHeight(20);
  static final double pieChartLegendSpacing = ScreenUtil().setHeight(12);
  static final double pieChartLegendIconSpacing = ScreenUtil().setWidth(6);
  
  // 图表相关参数
  static final double chartHeight = ScreenUtil().setHeight(300);
  static final double pieChartHeight = ScreenUtil().setHeight(220);
  static final double pieChartRadius = ScreenUtil().setWidth(80);
  static final double activePieChartRadius = ScreenUtil().setWidth(100);
  static final double pieChartBorderWidth = ScreenUtil().setWidth(3);
  static final double centerSpaceRadius = ScreenUtil().setWidth(50);
  static final double sectionsSpace = ScreenUtil().setWidth(2);
  static final double pieChartLegendIconSize = ScreenUtil().setWidth(12);
  static final EdgeInsets pieChartTitlePadding = EdgeInsets.symmetric(
    vertical: ScreenUtil().setHeight(6),
    horizontal: ScreenUtil().setWidth(12),
  );
  
  // 容器相关参数
  static final double buttonBorderRadius = ScreenUtil().setWidth(8);
  static final double cardBorderRadius = ScreenUtil().setWidth(16);
  static final double cardPadding = ScreenUtil().setWidth(16);
  static final double smallCardBorderRadius = ScreenUtil().setWidth(12);
  
  // 间距相关参数
  static final double contentPadding = ScreenUtil().setWidth(20);
  static final double smallSpacing = ScreenUtil().setHeight(10);
  static final double sectionSpacing = ScreenUtil().setHeight(16);
  static final double largeSectionSpacing = ScreenUtil().setHeight(30);
  static final double hugeSectionSpacing = ScreenUtil().setHeight(60);
  static final double cardMargin = ScreenUtil().setHeight(12);
  
  // 字体相关参数
  static final double largeFontSize = ScreenUtil().setSp(22);
  
  // 图例相关参数
  static final EdgeInsets pieChartLegendPadding = EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(10));
  static final double pieChartLegendHorizontalSpacing = ScreenUtil().setWidth(20);
  static final double pieChartLegendVerticalSpacing = ScreenUtil().setHeight(12);
  static final double pieChartLegendTitleSpacing = ScreenUtil().setHeight(20);
}

/// 保留的页面布局常量类，用于兼容已有的页面
/// 注意：新页面应使用各个页面特定的常量类
class PageLayoutConstants {
  /// 获取页面容器的边距配置
  /// 根据habit_management_page.dart中的配置，左右边距为16，上下边距为0
  static EdgeInsets getPageContainerPadding() {
    return EdgeInsets.only(
      left: ScreenUtil().setWidth(16),
      right: ScreenUtil().setWidth(16),
      top: ScreenUtil().setWidth(0),
      bottom: ScreenUtil().setWidth(0),
    );
  }

  

  /// 获取水平间距
  static double getHorizontalSpacing() {
    return ScreenUtil().setWidth(16);
  }

  /// 获取垂直间距
  static double getVerticalSpacing() {
    return ScreenUtil().setHeight(16);
  }

  /// 获取头部内边距
  static EdgeInsets getHeaderPadding() {
    return EdgeInsets.symmetric(
      horizontal: ScreenUtil().setWidth(24),
      vertical: ScreenUtil().setHeight(32),
    );
  }

  /// 获取头部边框圆角
  static double getHeaderBorderRadius() {
    return ScreenUtil().setWidth(30);
  }

  /// 获取卡片边框圆角
  static double getCardBorderRadius() {
    return ScreenUtil().setWidth(20);
  }
}