import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/shared/models/theme_model.dart' as app_theme;
import 'package:contrail/shared/theme/custom_theme_palette.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/theme_helper.dart';

class CustomThemeEditorPage extends StatefulWidget {
  final String themeId;
  final CustomThemePalette initialPalette;
  final CustomThemePalette defaultPalette;
  final String sourceThemeName;

  const CustomThemeEditorPage({
    super.key,
    required this.themeId,
    required this.initialPalette,
    required this.defaultPalette,
    required this.sourceThemeName,
  });

  @override
  State<CustomThemeEditorPage> createState() => _CustomThemeEditorPageState();
}

class _CustomThemeEditorPageState extends State<CustomThemeEditorPage> {
  late TextEditingController _nameController;
  late CustomThemePalette _palette;

  @override
  void initState() {
    super.initState();
    _palette = widget.initialPalette;
    _nameController = TextEditingController(text: widget.initialPalette.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visualTheme = ThemeHelper.visualTheme(context);
    final onHero = visualTheme.heroForeground;

    return Scaffold(
      body: Container(
        decoration:
            ThemeHelper.generateBackgroundDecoration(context) ??
            BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: PageLayoutConstants.getPageContainerPadding(),
            child: Column(
              children: [
                _buildHeader(context, onHero),
                SizedBox(height: BaseLayoutConstants.spacingLarge),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 2.w,
                      right: 2.w,
                      bottom: BaseLayoutConstants.spacingLarge,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPreviewPanel(context),
                        SizedBox(height: BaseLayoutConstants.spacingLarge),
                        _buildModePanel(context),
                        SizedBox(height: BaseLayoutConstants.spacingMedium),
                        _buildTemplatePanel(context),
                        SizedBox(height: BaseLayoutConstants.spacingMedium),
                        _buildColorEditorPanel(context),
                        SizedBox(height: BaseLayoutConstants.spacingLarge),
                        _buildActionBar(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color onHero) {
    return Container(
      decoration: ThemeHelper.heroDecoration(context, radius: 28.r),
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          _buildHeaderButton(
            context,
            icon: Icons.arrow_back_rounded,
            label: '返回',
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '编辑主题',
                  style: TextStyle(
                    fontSize: AppTypographyConstants.secondaryHeroTitleFontSize,
                    fontWeight: FontWeight.w800,
                    color: onHero,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '当前正在编辑「${widget.sourceThemeName}」；保存后会直接覆盖这张主题，随时也可以恢复默认值。',
                  style: TextStyle(
                    fontSize:
                        AppTypographyConstants.secondaryHeroSubtitleFontSize,
                    height: 1.6,
                    color: onHero.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(BuildContext context) {
    final previewForeground = _foregroundFor(_palette.backgroundStart);

    return Container(
      width: double.infinity,
      decoration: ThemeHelper.settingCardDecoration(context, radius: 24.r),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelTitle(
            context,
            title: '实时预览',
            subtitle: '先看整体气质，再决定颜色要不要继续细调。',
          ),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _palette.backgroundStart,
                  Color.lerp(
                        _palette.backgroundStart,
                        _palette.backgroundEnd,
                        0.55,
                      ) ??
                      _palette.backgroundStart,
                  _palette.backgroundEnd,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_palette.heroStart, _palette.heroEnd],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.trim().isEmpty
                            ? '我的主题'
                            : _nameController.text.trim(),
                        style: TextStyle(
                          fontSize: AppTypographyConstants.previewTitleFontSize,
                          fontWeight: FontWeight.w800,
                          color: _foregroundFor(
                            Color.lerp(_palette.heroStart, _palette.heroEnd, 0.5) ??
                                _palette.heroStart,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        _palette.preferredMode == app_theme.ThemeMode.light
                            ? '浅色系主题预览'
                            : '深色系主题预览',
                        style: TextStyle(
                          fontSize:
                              AppTypographyConstants.previewSubtitleFontSize,
                          color: _foregroundFor(
                            Color.lerp(_palette.heroStart, _palette.heroEnd, 0.5) ??
                                _palette.heroStart,
                          ).withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniPanel(
                        foreground: previewForeground,
                        title: '导航',
                        accent: _palette.navSelected,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildMiniPanel(
                        foreground: previewForeground,
                        title: '面板',
                        accent: _palette.accent,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _buildPreviewSwatch(_palette.backgroundStart),
                    _buildPreviewSwatch(_palette.heroEnd),
                    _buildPreviewSwatch(_palette.accent),
                    _buildPreviewSwatch(_palette.destructive),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPanel({
    required Color foreground,
    required String title,
    required Color accent,
  }) {
    return Container(
      height: 82.h,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppTypographyConstants.previewSubtitleFontSize,
              fontWeight: FontWeight.w700,
              color: foreground.withValues(alpha: 0.76),
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            height: 10.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999.r),
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 58.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999.r),
                  color: accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSwatch(Color color) {
    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
    );
  }

  Widget _buildModePanel(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ThemeHelper.settingCardDecoration(context, radius: 24),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelTitle(
            context,
            title: '主题模式',
            subtitle: '选择这组主题默认按浅色还是深色呈现。',
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _buildModeChip(
                  context,
                  label: '浅色',
                  selected: _palette.preferredMode == app_theme.ThemeMode.light,
                  onTap: () {
                    setState(() {
                      _palette = _palette.copyWith(
                        preferredMode: app_theme.ThemeMode.light,
                      );
                    });
                  },
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildModeChip(
                  context,
                  label: '深色',
                  selected: _palette.preferredMode != app_theme.ThemeMode.light,
                  onTap: () {
                    setState(() {
                      _palette = _palette.copyWith(
                        preferredMode: app_theme.ThemeMode.dark,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SwitchListTile.adaptive(
            value: _palette.useGlass,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '保留玻璃质感',
              style: TextStyle(
                fontSize: AppTypographyConstants.formLabelFontSize,
                fontWeight: FontWeight.w700,
                color: ThemeHelper.onBackground(context),
              ),
            ),
            subtitle: Text(
              '关闭后会更偏实体面板，打开后会更轻一点。',
              style: TextStyle(
                fontSize: AppTypographyConstants.formHelperFontSize,
                height: 1.5,
                color: ThemeHelper.onBackground(context).withValues(alpha: 0.66),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _palette = _palette.copyWith(useGlass: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePanel(BuildContext context) {
    final templates = CustomThemePalette.suggestedTemplates();

    return Container(
      width: double.infinity,
      decoration: ThemeHelper.settingCardDecoration(context, radius: 24),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelTitle(
            context,
            title: '快速套用模板',
            subtitle: '先从一个方向开始，再微调颜色会更高效。',
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: templates.map((template) {
              final selected = template.name == _palette.name &&
                  template.accentValue == _palette.accentValue;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _palette = template;
                    _nameController.text = template.name;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: selected
                        ? ThemeHelper.primary(context).withValues(alpha: 0.12)
                        : ThemeHelper.visualTheme(context).panelColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: selected
                          ? ThemeHelper.primary(context)
                          : ThemeHelper.visualTheme(context).panelBorderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTinyColor(template.heroStart),
                      SizedBox(width: 6.w),
                      _buildTinyColor(template.heroEnd),
                      SizedBox(width: 8.w),
                      Text(
                        template.name,
                        style: TextStyle(
                          fontSize: AppTypographyConstants.cardSubtitleFontSize,
                          fontWeight: FontWeight.w700,
                          color: ThemeHelper.onBackground(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyColor(Color color) {
    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  Widget _buildColorEditorPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ThemeHelper.settingCardDecoration(context, radius: 24),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelTitle(
            context,
            title: '主题颜色',
            subtitle: '点击每一项可直接输入十六进制颜色，例如 #50B9FF。',
          ),
          SizedBox(height: 14.h),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '主题名称',
              hintText: '例如：我的海盐薄暮',
            ),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 14.h),
          _buildColorItem(
            context,
            title: '背景渐变 A',
            color: _palette.backgroundStart,
            onTap: () => _editColor(
              title: '背景渐变 A',
              currentColor: _palette.backgroundStart,
              onChanged: (color) {
                setState(() {
                  _palette = _palette.copyWith(
                    backgroundStartValue: color.toARGB32(),
                  );
                });
              },
            ),
          ),
          _buildColorItem(
            context,
            title: '背景渐变 B',
            color: _palette.backgroundEnd,
            onTap: () => _editColor(
              title: '背景渐变 B',
              currentColor: _palette.backgroundEnd,
              onChanged: (color) {
                setState(() {
                  _palette = _palette.copyWith(
                    backgroundEndValue: color.toARGB32(),
                  );
                });
              },
            ),
          ),
          _buildColorItem(
            context,
            title: 'Hero 主色',
            color: _palette.heroStart,
            onTap: () => _editColor(
              title: 'Hero 主色',
              currentColor: _palette.heroStart,
              onChanged: (color) {
                setState(() {
                  _palette = _palette.copyWith(heroStartValue: color.toARGB32());
                });
              },
            ),
          ),
          _buildColorItem(
            context,
            title: 'Hero 辅色',
            color: _palette.heroEnd,
            onTap: () => _editColor(
              title: 'Hero 辅色',
              currentColor: _palette.heroEnd,
              onChanged: (color) {
                setState(() {
                  _palette = _palette.copyWith(heroEndValue: color.toARGB32());
                });
              },
            ),
          ),
          _buildColorItem(
            context,
            title: '主强调色',
            color: _palette.accent,
            onTap: () => _editColor(
              title: '主强调色',
              currentColor: _palette.accent,
              onChanged: (color) {
                setState(() {
                  _palette = _palette.copyWith(accentValue: color.toARGB32());
                });
              },
            ),
          ),
          _buildColorItem(
            context,
            title: '面板底色',
            color: _palette.panel,
            onTap: () => _editColor(
              title: '面板底色',
              currentColor: _palette.panel,
              onChanged: (color) {
                setState(() {
                  _palette = _palette.copyWith(panelValue: color.toARGB32());
                });
              },
            ),
          ),
          _buildColorItem(
            context,
            title: '边框色',
            color: _palette.panelBorder,
            onTap: () => _editColor(
              title: '边框色',
              currentColor: _palette.panelBorder,
              onChanged: (color) {
                setState(() {
                  _palette = _palette.copyWith(
                    panelBorderValue: color.toARGB32(),
                  );
                });
              },
            ),
          ),
          _buildColorItem(
            context,
            title: '导航选中色',
            color: _palette.navSelected,
            onTap: () => _editColor(
              title: '导航选中色',
              currentColor: _palette.navSelected,
              onChanged: (color) {
                setState(() {
                  _palette = _palette.copyWith(
                    navSelectedValue: color.toARGB32(),
                  );
                });
              },
            ),
          ),
          _buildColorItem(
            context,
            title: '危险色',
            color: _palette.destructive,
            onTap: () => _editColor(
              title: '危险色',
              currentColor: _palette.destructive,
              onChanged: (color) {
                setState(() {
                  _palette = _palette.copyWith(
                    destructiveValue: color.toARGB32(),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorItem(
    BuildContext context, {
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: ThemeHelper.visualTheme(context).panelColor,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: ThemeHelper.visualTheme(context).panelBorderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTypographyConstants.formLabelFontSize,
                    fontWeight: FontWeight.w700,
                    color: ThemeHelper.onBackground(context),
                  ),
                ),
              ),
              Text(
                _toHex(color),
                style: TextStyle(
                  fontSize: AppTypographyConstants.formHelperFontSize,
                  color: ThemeHelper.onBackground(context).withValues(alpha: 0.66),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.edit_outlined,
                size: 18.sp,
                color: ThemeHelper.primary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              await context.read<ThemeProvider>().resetThemeOverride(
                widget.themeId,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已恢复当前主题的默认值')),
              );
              Navigator.pop(context);
            },
            child: const Text('恢复默认'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final nextPalette = _palette.copyWith(
                name: _nameController.text.trim().isEmpty
                    ? widget.defaultPalette.name
                    : _nameController.text.trim(),
              );
              await context.read<ThemeProvider>().saveThemeOverride(
                widget.themeId,
                nextPalette,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('主题已保存并应用')),
              );
              Navigator.pop(context);
            },
            child: const Text('保存并应用'),
          ),
        ),
      ],
    );
  }

  Widget _buildModeChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: selected
              ? ThemeHelper.primary(context).withValues(alpha: 0.12)
              : ThemeHelper.visualTheme(context).panelColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected
                ? ThemeHelper.primary(context)
                : ThemeHelper.visualTheme(context).panelBorderColor,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypographyConstants.buttonLabelFontSize,
              fontWeight: FontWeight.w700,
              color: ThemeHelper.onBackground(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelTitle(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTypographyConstants.panelTitleFontSize,
            fontWeight: FontWeight.w800,
            color: ThemeHelper.onBackground(context),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: AppTypographyConstants.panelSubtitleFontSize,
            height: 1.6,
            color: ThemeHelper.onBackground(context).withValues(alpha: 0.66),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final visualTheme = ThemeHelper.visualTheme(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18.sp, color: visualTheme.heroForeground),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypographyConstants.secondaryHeroButtonFontSize,
                  fontWeight: FontWeight.w700,
                  color: visualTheme.heroForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editColor({
    required String title,
    required Color currentColor,
    required ValueChanged<Color> onChanged,
  }) async {
    Color draftColor = currentColor;
    final result = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('编辑$title'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 64.h,
                      decoration: BoxDecoration(
                        color: draftColor,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _toHex(draftColor),
                        style: TextStyle(
                          fontSize: AppTypographyConstants.formLabelFontSize,
                          fontWeight: FontWeight.w700,
                          color: _foregroundFor(draftColor),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    ColorPicker(
                      pickerColor: draftColor,
                      onColorChanged: (color) {
                        setDialogState(() {
                          draftColor = color;
                        });
                      },
                      labelTypes: const [],
                      pickerAreaHeightPercent: 0.78,
                      enableAlpha: false,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '当前颜色：${_toHex(draftColor)}',
                      style: TextStyle(
                        fontSize: AppTypographyConstants.dialogMetaFontSize,
                        color: ThemeHelper.onBackground(
                          context,
                        ).withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, draftColor);
                  },
                  child: const Text('应用'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      onChanged(result);
    }
  }

  String _toHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Color _foregroundFor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF18263D);
  }
}
