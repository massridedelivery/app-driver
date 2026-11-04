import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/home/presentation/widgets/online_toggle_button.dart';

Future<void> _pump(WidgetTester tester, bool online, VoidCallback onTap) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: OnlineToggleButton(isOnline: online, onTap: onTap),
          ),
        ),
      ),
    );

void main() {
  testWidgets('offline: a "เริ่มรับงาน" pill in the middle', (tester) async {
    var taps = 0;
    await _pump(tester, false, () => taps++);
    expect(find.text('เริ่มรับงาน'), findsOneWidget);
    final center = tester.getCenter(find.byType(Material).last);
    expect(center.dx, closeTo(400 / 2, 1));
    await tester.tap(find.text('เริ่มรับงาน'));
    expect(taps, 1);
  });

  testWidgets('online: a small button on the right, no label', (tester) async {
    var taps = 0;
    await _pump(tester, true, () => taps++);
    expect(find.text('เริ่มรับงาน'), findsNothing);
    expect(find.bySemanticsLabel('ปิดรับงาน'), findsOneWidget);
    final rect = tester.getRect(find.byType(InkWell));
    expect(rect.width, 52);
    expect(rect.right, closeTo(400 - 16, 1));
    await tester.tap(find.byType(InkWell));
    expect(taps, 1);
  });
}
