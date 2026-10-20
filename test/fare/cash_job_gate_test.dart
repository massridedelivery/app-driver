import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/friendly_error.dart';
import 'package:massdrive/features/income/domain/models/cash_job_gate.dart';
import 'package:massdrive/features/income/presentation/widgets/cash_job_gate_card.dart';
import 'package:massdrive/features/incoming_job/domain/accept_outcome.dart';

/// BE dev115: below the cash-job limit only cash jobs stop; QR / card jobs and
/// going online never do.
Map<String, dynamic> summary({
  required double balance,
  required bool canCash,
  double threshold = -20,
  Map<String, dynamic>? warning,
}) => {
  'credit_balance': balance,
  'can_receive_cash_jobs': canCash,
  'cash_job_block_balance': threshold,
  'reason': canCash ? '' : 'CASH_JOBS_BLOCKED',
  'can_receive_jobs': true,
  'credit_warning': ?warning,
};

DioException http(int status, Object data) => DioException(
  requestOptions: RequestOptions(path: '/accept'),
  response: Response(
    requestOptions: RequestOptions(path: '/accept'),
    statusCode: status,
    data: data,
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  group('CashJobGate from /payouts/summary', () {
    test('−฿19.99: cash jobs still allowed, nothing to show', () {
      final g = CashJobGate.fromSummary(
        summary(balance: -19.99, canCash: true),
      );
      expect(g.cashBlocked, isFalse);
      expect(g.hasNotice, isFalse);
    });

    test('−฿20.01: cash blocked, BE copy and numbers on the card', () {
      final g = CashJobGate.fromSummary(
        summary(
          balance: -20.01,
          canCash: false,
          warning: {
            'title': 'งานเงินสดถูกระงับ',
            'message':
                'ยอดเครดิตต่ำกว่าเกณฑ์ รับได้เฉพาะงานที่จ่ายผ่าน QR/บัตร',
          },
        ),
      );
      expect(g.cashBlocked, isTrue);
      expect(g.hasNotice, isTrue);
      expect(g.title, 'งานเงินสดถูกระงับ');
      expect(g.message, contains('QR/บัตร'));
      expect(g.statusLine, 'รับได้เฉพาะงาน QR/บัตร · ยอด -฿20.01 · เกณฑ์ -฿20');
    });

    test('blocked without credit_warning falls back to the default copy', () {
      final g = CashJobGate.fromSummary(summary(balance: -35, canCash: false));
      expect(g.title, CashJobGate.defaultBlockedTitle);
      expect(g.message, CashJobGate.defaultBlockedMessage);
      expect(g.statusLine, 'รับได้เฉพาะงาน QR/บัตร · ยอด -฿35 · เกณฑ์ -฿20');
    });

    test('topped back above the limit → allowed again at once', () {
      final g = CashJobGate.fromSummary(summary(balance: 15, canCash: true));
      expect(g.cashBlocked, isFalse);
    });

    test('threshold comes from the BE (admin set −฿50), never hard-coded', () {
      final g = CashJobGate.fromSummary(
        summary(balance: -35, canCash: true, threshold: -50),
      );
      expect(g.blockBalance, -50);
      expect(g.cashBlocked, isFalse); // −35 is above −50
    });

    test('low-credit warning only informs, never blocks', () {
      final g = CashJobGate.fromSummary(
        summary(
          balance: -15,
          canCash: true,
          warning: {
            'title': 'เครดิตเหลือน้อย',
            'message': 'เติมเครดิตก่อนถึงเกณฑ์',
          },
        ),
      );
      expect(g.cashBlocked, isFalse);
      expect(g.hasNotice, isTrue);
      expect(g.title, 'เครดิตเหลือน้อย');
      expect(g.statusLine, 'ยอด -฿15 · เกณฑ์ -฿20');
    });

    test('can_receive_jobs is ignored; a missing flag never blocks', () {
      final g = CashJobGate.fromSummary({
        'credit_balance': -600,
        'can_receive_jobs': false,
      });
      expect(g.cashBlocked, isFalse);
      expect(g.blockBalance, isNull);
    });
  });

  group('accept refused for the cash-job limit', () {
    test('food and messenger 403 bodies are recognised', () {
      expect(
        isCashJobBlockedError(
          http(403, {
            'error':
                'wallet balance is below the cash-job limit: top up to take cash orders',
          }),
        ),
        isTrue,
      );
      expect(
        isCashJobBlockedError(
          http(403, {
            'error': 'driver is blocked from cash-on-delivery orders',
          }),
        ),
        isTrue,
      );
      expect(
        isCashJobBlockedError(http(403, {'code': 'CASH_JOBS_BLOCKED'})),
        isTrue,
      );
      expect(isCashJobBlockedError(const CashJobBlockedException()), isTrue);
    });

    test('other 403s and non-403s are not a cash block', () {
      expect(
        isCashJobBlockedError(http(403, {'code': 'account_suspended'})),
        isFalse,
      );
      expect(
        isCashJobBlockedError(http(403, {'code': 'documents_not_verified'})),
        isFalse,
      );
      expect(
        isCashJobBlockedError(http(409, {'error': 'cash-job limit'})),
        isFalse,
      );
      expect(isCashJobBlockedError(Exception('x')), isFalse);
    });

    test('shown as the block copy, not "เซสชันหมดอายุ"', () {
      expect(
        friendlyErrorMessage(
          http(403, {
            'error': 'driver is blocked from cash-on-delivery orders',
          }),
        ),
        CashJobGate.defaultBlockedMessage,
      );
      expect(
        acceptOutcomeMessage(AcceptOutcome.cashBlocked),
        CashJobGate.defaultBlockedMessage,
      );
    });
  });

  testWidgets('home notice shows status line and opens top-up', (tester) async {
    var tapped = false;
    final gate = CashJobGate.fromSummary(summary(balance: -35, canCash: false));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CashJobNotice(gate: gate, onTopUp: () => tapped = true),
        ),
      ),
    );
    expect(find.text('งานเงินสดถูกระงับ'), findsOneWidget);
    expect(
      find.text('รับได้เฉพาะงาน QR/บัตร · ยอด -฿35 · เกณฑ์ -฿20'),
      findsOneWidget,
    );
    expect(find.textContaining('รับงานไม่ได้'), findsNothing);
    await tester.tap(find.text('เติมเครดิต'));
    expect(tapped, isTrue);
  });
}
