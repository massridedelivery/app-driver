import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/features/auth/presentation/screens/otp_screen.dart';

void main() {
  test('formatCountdown shows mm:ss', () {
    expect(formatCountdown(const Duration(minutes: 3)), '03:00');
    expect(formatCountdown(const Duration(seconds: 59)), '00:59');
    expect(formatCountdown(const Duration(seconds: 5)), '00:05');
    expect(formatCountdown(Duration.zero), '00:00');
  });

  testWidgets('resend unlocks only after the 60-second countdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OtpScreen(phoneNumber: '0653333333', refId: 'abcd1234'),
        ),
      ),
    );

    expect(find.textContaining('01:00', findRichText: true), findsOneWidget);
    expect(find.text('รับรหัส OTP ใหม่'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('00:59', findRichText: true), findsOneWidget);

    await tester.pump(const Duration(seconds: 58));
    expect(find.textContaining('00:01', findRichText: true), findsOneWidget);
    expect(find.text('รับรหัส OTP ใหม่'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('รับรหัส OTP ใหม่'), findsOneWidget);
    expect(
      find.textContaining('ขอรหัสใหม่ได้ใน', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('แก้ไขเบอร์โทรศัพท์ goes back to the phone screen', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('login')),
        GoRoute(
          path: '/otp',
          builder: (_, _) => const OtpScreen(phoneNumber: '0653333333'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    router.push('/otp');
    await tester.pumpAndSettle();
    await tester.tap(find.text('แก้ไขเบอร์โทรศัพท์'));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
  });
}
