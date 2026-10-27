import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/common/widgets/slide_to_confirm.dart';

void main() {
  Future<int Function()> pump(
    WidgetTester t, {
    bool enabled = true,
    bool loading = false,
  }) async {
    var fired = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SlideToConfirm(
                label: 'เลื่อนเพื่อรับงาน',
                color: Colors.green,
                enabled: enabled,
                loading: loading,
                onConfirmed: () => fired++,
              ),
            ),
          ),
        ),
      ),
    );
    return () => fired;
  }

  Finder knob() => find.byIcon(Icons.keyboard_double_arrow_right_rounded);

  testWidgets('a full slide confirms once', (t) async {
    final fired = await pump(t);
    expect(find.text('เลื่อนเพื่อรับงาน'), findsOneWidget);
    await t.drag(knob(), const Offset(300, 0));
    await t.pumpAndSettle();
    expect(fired(), 1);
  });

  testWidgets('a short slide or a tap does nothing', (t) async {
    final fired = await pump(t);
    await t.drag(knob(), const Offset(80, 0));
    await t.pumpAndSettle();
    await t.tap(knob());
    await t.pumpAndSettle();
    expect(fired(), 0);
  });

  testWidgets('disabled or loading ignores the slide', (t) async {
    final fired = await pump(t, enabled: false);
    await t.drag(knob(), const Offset(300, 0));
    await t.pumpAndSettle();
    expect(fired(), 0);

    final fired2 = await pump(t, loading: true);
    await t.drag(find.byType(CircularProgressIndicator), const Offset(300, 0));
    await t.pump(const Duration(milliseconds: 300));
    expect(fired2(), 0);
  });

  testWidgets('the label sits in the middle of the track', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SlideToConfirm(
                label: 'รับงาน',
                color: Colors.green,
                onConfirmed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    final track = t.getRect(find.byType(SlideToConfirm));
    final label = t.getRect(find.text('รับงาน'));
    expect(label.center.dx, moreOrLessEquals(track.center.dx, epsilon: 1));
    expect(label.left, greaterThan(t.getRect(knob()).right));
  });

  testWidgets('a long label clears the knob instead of centring', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              child: SlideToConfirm(
                label: 'เลื่อนเมื่อรับผู้โดยสารแล้วและพร้อมออกเดินทาง',
                color: Colors.green,
                onConfirmed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    final label = t.getRect(find.byType(Text));
    expect(label.left, greaterThanOrEqualTo(t.getRect(knob()).right));
    expect(t.takeException(), isNull);
  });
}
