import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/home/presentation/widgets/online_toggle_button.dart';

Future<void> _pump(WidgetTester tester, bool online, VoidCallback onTap) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OnlineToggleButton(isOnline: online, onTap: onTap),
          ),
        ),
      ),
    );

void main() {
  testWidgets('offline: a wide "เริ่มรับงาน" pill', (tester) async {
    var taps = 0;
    await _pump(tester, false, () => taps++);
    expect(find.text('เริ่มรับงาน'), findsOneWidget);
    await tester.tap(find.text('เริ่มรับงาน'));
    expect(taps, 1);
  });

  testWidgets('online: a small 52×52 button, no label', (tester) async {
    var taps = 0;
    await _pump(tester, true, () => taps++);
    expect(find.text('เริ่มรับงาน'), findsNothing);
    expect(find.bySemanticsLabel('ปิดรับงาน'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InkWell)), const Size(52, 52));
    await tester.tap(find.byType(InkWell));
    expect(taps, 1);
  });
}
