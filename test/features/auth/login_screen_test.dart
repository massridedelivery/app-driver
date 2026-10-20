import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/auth/presentation/controllers/login_controller.dart';
import 'package:massdrive/features/auth/presentation/screens/login_screen.dart';
import 'package:massdrive/features/auth/presentation/widgets/auth_style.dart';

void main() {
  group('normalizeThaiPhone', () {
    test('adds the leading 0 after the +66 prefix', () {
      expect(normalizeThaiPhone('812345678'), '0812345678');
    });
    test('keeps a number typed with its leading 0', () {
      expect(normalizeThaiPhone('0653333333'), '0653333333');
    });
    test('drops non-digits and stays empty when cleared', () {
      expect(normalizeThaiPhone('81-234 5678'), '0812345678');
      expect(normalizeThaiPhone(''), '');
    });
  });

  group('isValidThaiPhone', () {
    test('needs 10 digits starting with 0', () {
      expect(isValidThaiPhone('0812345678'), isTrue);
      expect(isValidThaiPhone('081234567'), isFalse);
      expect(isValidThaiPhone('08123456789'), isFalse);
      expect(isValidThaiPhone(''), isFalse);
    });
  });

  group('LoginScreen', () {
    Future<ProviderContainer> pump(WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      return container;
    }

    bool buttonEnabled(WidgetTester tester) => tester
        .widget<AuthPrimaryButton>(find.byType(AuthPrimaryButton))
        .enabled;

    testWidgets('phone only: logo, +66 field, OTP button, no email', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byType(MassDriveLogoTile), findsOneWidget);
      expect(find.text('ยินดีต้อนรับคนขับ'), findsOneWidget);
      expect(find.text('+66'), findsOneWidget);
      expect(find.text('ขอรหัส OTP'), findsOneWidget);
      expect(find.textContaining('อีเมล'), findsNothing);
      expect(find.textContaining('Email'), findsNothing);
    });

    testWidgets('OTP button enables once a full number is typed', (
      tester,
    ) async {
      final container = await pump(tester);
      expect(buttonEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField), '81234567');
      await tester.pump();
      expect(buttonEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField), '812345678');
      await tester.pump();
      expect(buttonEnabled(tester), isTrue);
      expect(
        container.read(loginControllerProvider).phoneNumber,
        '0812345678',
      );
    });

    testWidgets('a number typed with its leading 0 also works', (
      tester,
    ) async {
      final container = await pump(tester);
      await tester.enterText(find.byType(TextField), '0653333333');
      await tester.pump();
      expect(buttonEnabled(tester), isTrue);
      expect(
        container.read(loginControllerProvider).phoneNumber,
        '0653333333',
      );
    });
  });
}
