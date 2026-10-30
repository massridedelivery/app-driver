import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/call/domain/call_kind.dart';
import 'package:massdrive/features/call/domain/call_models.dart';
import 'package:massdrive/features/call/domain/call_state.dart';
import 'package:massdrive/features/call/presentation/controllers/call_controller.dart';
import 'package:massdrive/features/call/presentation/screens/call_screen.dart';

class _EndedCall extends CallController {
  @override
  CallState build() => const CallState(
    phase: CallPhase.ended,
    endReason: CallEndReason.hangup,
    call: CallInfo(
      callId: 'c1',
      kind: CallKind.ride,
      jobId: 'j1',
      peerName: 'เมริการ์ พรมมาแบน',
    ),
  );
}

void main() {
  testWidgets('a plain hang-up keeps the name, status and "ปิด" centred', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [callControllerProvider.overrideWith(_EndedCall.new)],
        child: MaterialApp(home: CallScreen(onDisposed: () {})),
      ),
    );
    await tester.pump();

    final centre = tester.getSize(find.byType(CallScreen)).width / 2;
    for (final text in ['เมริการ์ พรมมาแบน', 'วางสายแล้ว', 'ปิด']) {
      expect(
        tester.getCenter(find.text(text)).dx,
        moreOrLessEquals(centre, epsilon: 1),
        reason: text,
      );
    }

    // Let the 2 s auto-close and the timer ticker go.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
