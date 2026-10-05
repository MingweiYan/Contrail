import 'package:contrail/shared/widgets/scroll_to_top_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows after scrolling and returns to the top', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            controller: controller,
            itemCount: 20,
            itemExtent: 100,
            itemBuilder: (context, index) => Text('Item $index'),
          ),
          floatingActionButton: ScrollToTopFab(
            controller: controller,
            showAfter: 200,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);

    controller.jumpTo(400);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await tester.pumpAndSettle();

    expect(controller.offset, 0);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);
  });
}
