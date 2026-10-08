import 'package:flutter/material.dart';
import 'package:contrail/shared/layout/responsive_layout.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/theme_helper.dart';

class AdaptiveNavigationItem {
  const AdaptiveNavigationItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// A shared application shell that changes navigation chrome, not pages.
///
/// Compact windows keep the mobile bottom bar. Wider windows expose a rail so
/// the content can use the available vertical space while retaining the same
/// page widgets and state.
class AdaptiveNavigationScaffold extends StatelessWidget {
  const AdaptiveNavigationScaffold({
    super.key,
    required this.body,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const bottomNavigationKey = Key('adaptive-bottom-navigation');
  static const navigationRailKey = Key('adaptive-navigation-rail');

  final Widget body;
  final List<AdaptiveNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty);
    assert(selectedIndex >= 0 && selectedIndex < items.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (ResponsiveLayout.usesExpandedNavigation(constraints.maxWidth)) {
          return _buildExpanded(context, constraints.maxWidth);
        }
        return _buildCompact(context);
      },
    );
  }

  Widget _buildExpanded(BuildContext context, double width) {
    final visualTheme = ThemeHelper.visualTheme(context);
    final isExtended = ResponsiveLayout.usesExtendedNavigation(width);

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
              child: Container(
                decoration: ThemeHelper.navigationDecoration(context),
                clipBehavior: Clip.antiAlias,
                child: NavigationRail(
                  key: navigationRailKey,
                  extended: isExtended,
                  minWidth: 72,
                  minExtendedWidth: 208,
                  groupAlignment: -0.72,
                  backgroundColor: Colors.transparent,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: isExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.selected,
                  indicatorColor: visualTheme.navSelectedBackground,
                  selectedIconTheme: IconThemeData(
                    color: visualTheme.navSelectedForeground,
                    size: 22,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: visualTheme.navUnselectedForeground,
                    size: 22,
                  ),
                  selectedLabelTextStyle: TextStyle(
                    color: visualTheme.navSelectedForeground,
                    fontSize: AppTypographyConstants.bottomNavLabelFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: visualTheme.navUnselectedForeground,
                    fontSize: AppTypographyConstants.bottomNavLabelFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  destinations: [
                    for (final item in items)
                      NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(item.label),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: ResponsivePageFrame(child: body)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final visualTheme = ThemeHelper.visualTheme(context);

    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            key: bottomNavigationKey,
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: AppTypographyConstants.bottomNavBarVerticalPadding,
            ),
            decoration: ThemeHelper.navigationDecoration(context),
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: item.label,
                    child: InkWell(
                      onTap: () => onDestinationSelected(index),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: AppTypographyConstants
                              .bottomNavItemVerticalPadding,
                        ),
                        decoration: isSelected
                            ? ThemeHelper.selectedNavigationItemDecoration(
                                context,
                              )
                            : BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                              ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              size: 19,
                              color: isSelected
                                  ? visualTheme.navSelectedForeground
                                  : visualTheme.navUnselectedForeground,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppTypographyConstants
                                      .bottomNavLabelFontSize,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? visualTheme.navSelectedForeground
                                      : visualTheme.navUnselectedForeground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
