import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/home/presentation/widgets/home_coach_marks.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A stand-in home with the four tour targets, top to bottom.
class _FakeHome extends StatelessWidget {
  const _FakeHome();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const Spacer(),
        SizedBox(
          key: HomeCoachMarks.onlineButton,
          width: 200,
          height: 52,
          child: const Text('online'),
        ),
        SizedBox(
          key: HomeCoachMarks.statusCard,
          width: 300,
          height: 40,
          child: const Text('status'),
        ),
        Row(
          children: [
            SizedBox(key: HomeCoachMarks.incomeMenu, width: 60, height: 60),
            SizedBox(key: HomeCoachMarks.serviceMenu, width: 60, height: 60),
          ],
        ),
        const SizedBox(height: 40),
      ],
    ),
  );
}

Future<bool> _seen() async =>
    (await SharedPreferences.getInstance()).getBool(HomeCoachMarks.seenKey) ??
    false;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('first visit: 4 steps, ถัดไป to the end, then never again', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _FakeHome()));
    final ctx = tester.element(find.byType(_FakeHome));

    HomeCoachMarks.maybeShow(ctx);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('กดเพื่อเริ่มรับงาน'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('ข้าม'), findsOneWidget);

    for (final title in ['สถานะการรับงาน', 'รายได้ของคุณ', 'ประเภทบริการ']) {
      await tester.tap(find.text('ถัดไป'));
      await tester.pump();
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('ข้าม'), findsNothing);

    await tester.tap(find.text('เริ่มใช้งาน'));
    await tester.pumpAndSettle();
    expect(find.byType(CoachMarksOverlay), findsNothing);
    expect(await _seen(), isTrue);

    // Seen: the next home visit stays quiet.
    HomeCoachMarks.maybeShow(ctx);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byType(CoachMarksOverlay), findsNothing);
  });

  testWidgets('ข้าม ends the tour and counts as seen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _FakeHome()));
    HomeCoachMarks.show(tester.element(find.byType(_FakeHome)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ข้าม'));
    await tester.pumpAndSettle();
    expect(find.byType(CoachMarksOverlay), findsNothing);
    expect(await _seen(), isTrue);
  });

  testWidgets('replay from Settings: reset makes it show again', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({HomeCoachMarks.seenKey: true});
    await HomeCoachMarks.reset();
    await tester.pumpWidget(const MaterialApp(home: _FakeHome()));

    HomeCoachMarks.maybeShow(tester.element(find.byType(_FakeHome)));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('กดเพื่อเริ่มรับงาน'), findsOneWidget);
  });
}
