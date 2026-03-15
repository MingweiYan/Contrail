import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _DemoBadge extends StatefulWidget {
  final Duration duration;
  const _DemoBadge({required this.duration});
  @override
  State<_DemoBadge> createState() => _DemoBadgeState();
}

class _DemoBadgeState extends State<_DemoBadge> {
  late Duration _d = widget.duration;
  void set(Duration d) => setState(() => _d = d);
  @override
  Widget build(BuildContext context) {
    final hours = _d.inHours;
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              children: [
                Container(color: Colors.green),
                if (hours > 0)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, a) =>
                          ScaleTransition(scale: a, child: child),
                      child: Container(
                        key: ValueKey(hours),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: Colors.white,
                        child: Text('${hours}h'),
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
}

void main() {
  testWidgets('小时徽标演示', (tester) async {
    final demo = _DemoBadge(duration: const Duration(minutes: 70));
    await tester.pumpWidget(demo);
    expect(find.text('1h'), findsOneWidget);

    final state = tester.state(find.byType(_DemoBadge)) as _DemoBadgeState;
    state.set(const Duration(minutes: 130));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('2h'), findsOneWidget);
  });
}
