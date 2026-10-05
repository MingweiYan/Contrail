import 'package:flutter/material.dart';

import 'package:contrail/shared/utils/page_layout_constants.dart';

class ScrollToTopFab extends StatelessWidget {
  const ScrollToTopFab({
    super.key,
    required this.controller,
    this.showAfter = HeroHeaderPageConstants.scrollToTopThreshold,
  });

  final ScrollController controller;
  final double showAfter;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final isVisible =
            controller.hasClients && controller.offset >= showAfter;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: isVisible
              ? FloatingActionButton.small(
                  key: const ValueKey('scroll-to-top'),
                  heroTag: null,
                  tooltip: '回到顶部',
                  onPressed: _scrollToTop,
                  child: const Icon(Icons.keyboard_arrow_up_rounded),
                )
              : const SizedBox.shrink(key: ValueKey('scroll-to-top-hidden')),
        );
      },
    );
  }

  void _scrollToTop() {
    if (!controller.hasClients) {
      return;
    }
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }
}
