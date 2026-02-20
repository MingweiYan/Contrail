import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/time_management_util.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';

class PersonalizationSettingsPage extends StatefulWidget {
  const PersonalizationSettingsPage({super.key});

  @override
  State<PersonalizationSettingsPage> createState() =>
      _PersonalizationSettingsPageState();
}

class _PersonalizationSettingsPageState
    extends State<PersonalizationSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('个性化设置'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: ThemeHelper.onPrimary(context),
      ),
      body: ChangeNotifierProvider(
        create: (context) => PersonalizationProvider()..initialize(),
        child: Container(
          decoration:
              ThemeHelper.generateBackgroundDecoration(context) ??
              BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
          padding: PageLayoutConstants.getPageContainerPadding(),
          width: double.infinity,
          height: double.infinity,
          child: Consumer<PersonalizationProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 周起始日设置模块
                    Container(
                      margin: EdgeInsets.only(
                        top: PersonalizationSettingsPageConstants
                            .containerTopMargin,
                      ),
                      padding:
                          PersonalizationSettingsPageConstants.containerPadding,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(
                          PersonalizationSettingsPageConstants
                              .containerBorderRadius,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 模块标题
                          Text(
                            '每周第一天',
                            style: TextStyle(
                              fontSize: PersonalizationSettingsPageConstants
                                  .titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: ThemeHelper.onBackground(context),
                            ),
                          ),
                          SizedBox(
                            height: PersonalizationSettingsPageConstants
                                .titleDescriptionSpacing,
                          ),

                          // 说明文字
                          Text(
                            '选择每周的起始日期，影响日历显示和周统计数据',
                            style: TextStyle(
                              fontSize: PersonalizationSettingsPageConstants
                                  .descriptionFontSize,
                              color: ThemeHelper.onBackground(
                                context,
                              ).withOpacity(0.7),
                            ),
                          ),
                          SizedBox(
                            height: PersonalizationSettingsPageConstants
                                .descriptionOptionsSpacing,
                          ),

                          // 单选选择器
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // 周天选项
                              Expanded(
                                child: RadioListTile<WeekStartDay>(
                                  title: Text(
                                    '周天',
                                    style: TextStyle(
                                      fontSize:
                                          PersonalizationSettingsPageConstants
                                              .optionFontSize,
                                      color:
                                          provider.weekStartDay ==
                                              WeekStartDay.sunday
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : ThemeHelper.onBackground(context),
                                    ),
                                  ),
                                  value: WeekStartDay.sunday,
                                  groupValue: provider.weekStartDay,
                                  onChanged: (value) {
                                    if (value != null) {
                                      provider.setWeekStartDay(value);
                                    }
                                  },
                                  activeColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  tileColor:
                                      provider.weekStartDay ==
                                          WeekStartDay.sunday
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.1)
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      PersonalizationSettingsPageConstants
                                          .radioBorderRadius,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: PersonalizationSettingsPageConstants
                                    .optionsSpacing,
                              ),
                              // 周一选项
                              Expanded(
                                child: RadioListTile<WeekStartDay>(
                                  title: Text(
                                    '周一',
                                    style: TextStyle(
                                      fontSize:
                                          PersonalizationSettingsPageConstants
                                              .optionFontSize,
                                      color:
                                          provider.weekStartDay ==
                                              WeekStartDay.monday
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : ThemeHelper.onBackground(context),
                                    ),
                                  ),
                                  value: WeekStartDay.monday,
                                  groupValue: provider.weekStartDay,
                                  onChanged: (value) {
                                    if (value != null) {
                                      provider.setWeekStartDay(value);
                                    }
                                  },
                                  activeColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  tileColor:
                                      provider.weekStartDay ==
                                          WeekStartDay.monday
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.1)
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      PersonalizationSettingsPageConstants
                                          .radioBorderRadius,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 保存提示
                    Padding(
                      padding: EdgeInsets.only(
                        top: PersonalizationSettingsPageConstants
                            .containerBottomMargin,
                      ),
                      child: Text(
                        '设置会自动保存并在下次应用启动时生效',
                        style: TextStyle(
                          fontSize:
                              PersonalizationSettingsPageConstants.hintFontSize,
                          color: ThemeHelper.onBackground(
                            context,
                          ).withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
