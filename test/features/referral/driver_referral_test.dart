import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:massdrive/features/referral/data/referral_api.dart';
import 'package:massdrive/features/referral/domain/driver_referral.dart';
import 'package:massdrive/features/referral/presentation/referral_providers.dart';
import 'package:massdrive/features/referral/presentation/screens/referral_screen.dart';
import 'package:massdrive/features/referral/presentation/widgets/referral_code_field.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_type.dart';

Map<String, dynamic> _info({
  bool enabled = true,
  bool canApply = true,
  String? applyBefore = '2026-12-01T03:00:00Z',
  Map<String, dynamic>? referredBy,
}) => {
  'enabled': enabled,
  'code': 'DK7PQ2M',
  'share_message': 'สมัครขับกับ Mass Move ใส่โค้ด DK7PQ2M ตอนสมัคร',
  'required_jobs': 10,
  'window_days': 30,
  'bonus_baht': 100,
  'referee_bonus_baht': 0,
  'summary': {
    'invited': 3,
    'pending': 1,
    'completed': 1,
    'expired': 1,
    'earned_baht': 100,
  },
  'referrals': [
    {
      'id': 'r1',
      'name': 'วิชัย ม.',
      'status': 'PENDING',
      'completed_jobs': 6,
      // Frozen when the code was applied: differs from today's 10 / ฿100.
      'required_jobs': 8,
      'waiting_approval': false,
      'deadline_at': '2026-12-05T10:00:00Z',
      'bonus_baht': 80,
      'paid_at': null,
      'created_at': '2026-11-05T10:00:00Z',
    },
    {
      'id': 'r2',
      'name': 'สมศรี ก.',
      'status': 'PENDING',
      'completed_jobs': 0,
      'required_jobs': 10,
      'waiting_approval': true,
      'deadline_at': null,
      'bonus_baht': 100,
      'paid_at': null,
      'created_at': '2026-11-04T10:00:00Z',
    },
  ],
  'referred_by': referredBy,
  'can_apply_code': canApply,
  'apply_before': applyBefore,
};

class _FakeApi implements ReferralApi {
  _FakeApi(this.info, {this.applyError});

  Map<String, dynamic> info;
  final ReferralApplyException? applyError;
  final applied = <String>[];

  @override
  Future<ReferralInfo> get() async => ReferralInfo.fromJson(info);

  @override
  Future<ReferralProgress?> apply(String code) async {
    applied.add(code);
    if (applyError case final e?) throw e;
    info = _info(
      canApply: false,
      referredBy: {'id': 'x', 'code': code, 'status': 'PENDING'},
    );
    return null;
  }
}

Future<void> _pump(WidgetTester t, Widget child, _FakeApi api) async {
  t.view.physicalSize = const Size(1080, 3000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [referralApiProvider.overrideWithValue(api)],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('th_TH'));

  group('ReferralInfo', () {
    test('parses the invite screen', () {
      final i = ReferralInfo.fromJson(_info());
      expect(i.enabled, isTrue);
      expect(i.code, 'DK7PQ2M');
      expect(i.summary.invited, 3);
      expect(i.summary.earnedBaht, 100);
      expect(i.referrals, hasLength(2));
      expect(i.referrals.first.requiredJobs, 8);
      expect(i.referrals.first.bonusBaht, 80);
      expect(i.referrals.first.progress, 0.75);
      expect(i.referrals.last.waitingApproval, isTrue);
      expect(i.referrals.last.deadlineAt, isNull);
    });

    test('the rule reads from the response', () {
      expect(
        ReferralInfo.fromJson(_info()).ruleText,
        'เพื่อนวิ่งครบ 10 งานภายใน 30 วัน รับ ฿100',
      );
    });

    test('the code field closes at apply_before; null = still open', () {
      final i = ReferralInfo.fromJson(_info());
      expect(i.canApplyAt(DateTime.utc(2026, 11, 30)), isTrue);
      expect(i.canApplyAt(DateTime.utc(2026, 12, 2)), isFalse);
      final open = ReferralInfo.fromJson(_info(applyBefore: null));
      expect(open.canApplyAt(DateTime.utc(2030)), isTrue);
      final off = ReferralInfo.fromJson(_info(canApply: false));
      expect(off.canApplyAt(DateTime.utc(2026, 11, 30)), isFalse);
    });

    test('off, with no code yet', () {
      final i = ReferralInfo.fromJson({'enabled': false, 'code': null});
      expect(i.enabled, isFalse);
      expect(i.code, isNull);
      expect(i.referrals, isEmpty);
    });
  });

  group('apply errors', () {
    test('every code has its own Thai message', () {
      for (final code in [
        'driver_referral_disabled',
        'driver_referral_invalid_code',
        'driver_referral_self',
        'driver_referral_mutual',
        'driver_referral_already_used',
        'driver_referral_window_closed',
        'driver_referral_not_driver',
      ]) {
        final m = ReferralApplyException(code, 'english').message;
        expect(m, isNot(contains('english')), reason: code);
      }
    });

    test("an unknown code shows the server's message", () {
      expect(
        const ReferralApplyException(
          'new_code',
          'ข้อความจากเซิร์ฟเวอร์',
        ).message,
        'ข้อความจากเซิร์ฟเวอร์',
      );
    });

    test('a field that can never succeed closes', () {
      expect(
        const ReferralApplyException(
          'driver_referral_window_closed',
          null,
        ).closesField,
        isTrue,
      );
      expect(
        const ReferralApplyException(
          'driver_referral_invalid_code',
          null,
        ).closesField,
        isFalse,
      );
    });
  });

  test('DRIVER_REFERRAL_BONUS is its own credit row', () {
    final t = TransactionType.fromString('DRIVER_REFERRAL_BONUS');
    expect(t, TransactionType.driverReferralBonus);
    expect(t.isCredit, isTrue);
    expect(t.toApiString(), 'DRIVER_REFERRAL_BONUS');
    expect(driverReferralBonusLabel, 'โบนัสชวนเพื่อนมาขับ');
  });

  test('the bonus push is recognised by its type', () {
    expect(
      isDriverReferralBonusPush({
        'type': 'driver_referral_bonus',
        'referral_id': 'r1',
        'role': 'referrer',
        'amount': '100',
        'deeplink': '/wallet',
      }),
      isTrue,
    );
    expect(isDriverReferralBonusPush({'type': 'payout_completed'}), isFalse);
  });

  group('screens', () {
    testWidgets('invite screen: code, rule and each referral on its own '
        'rules', (t) async {
      await _pump(t, const ReferralScreen(), _FakeApi(_info()));
      expect(find.text('DK7PQ2M'), findsOneWidget);
      expect(
        find.text('เพื่อนวิ่งครบ 10 งานภายใน 30 วัน รับ ฿100'),
        findsOneWidget,
      );
      expect(find.text('แชร์โค้ดให้เพื่อน'), findsOneWidget);
      expect(find.text('วิ่งแล้ว 6/8 งาน'), findsOneWidget);
      expect(find.text('โบนัส ฿80'), findsOneWidget);
      expect(find.text('รออนุมัติ'), findsOneWidget);
    });

    testWidgets('a disabled program shows no invite', (t) async {
      await _pump(t, const ReferralScreen(), _FakeApi(_info(enabled: false)));
      expect(find.text('DK7PQ2M'), findsNothing);
      expect(find.text('ยังไม่เปิดให้ชวนเพื่อนตอนนี้'), findsOneWidget);
    });

    testWidgets('entering a code applies it, then shows it as used', (t) async {
      final api = _FakeApi(_info(applyBefore: null));
      await _pump(t, const ReferralCodeCard(), api);
      await t.enterText(find.byType(TextField), ' ab12cd ');
      await t.tap(find.text('ใช้โค้ด'));
      await t.pumpAndSettle();
      expect(api.applied, ['ab12cd']);
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('สมัครด้วยโค้ดผู้แนะนำ'), findsOneWidget);
    });

    testWidgets('a refused code shows its Thai message under the field', (
      t,
    ) async {
      final api = _FakeApi(
        _info(applyBefore: null),
        applyError: const ReferralApplyException(
          'driver_referral_self',
          'cannot use your own referral code',
        ),
      );
      await _pump(t, const ReferralCodeCard(), api);
      await t.enterText(find.byType(TextField), 'DK7PQ2M');
      await t.tap(find.text('ใช้โค้ด'));
      await t.pumpAndSettle();
      expect(find.text('ใช้โค้ดของตัวเองไม่ได้'), findsOneWidget);
    });

    testWidgets('program off: no code field, even with can_apply_code', (
      t,
    ) async {
      await _pump(
        t,
        const ReferralCodeCard(),
        _FakeApi(_info(enabled: false, applyBefore: null)),
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.text('มีโค้ดผู้แนะนำไหม?'), findsNothing);
    });

    testWidgets('switched on by admin: shows on the next load', (t) async {
      final api = _FakeApi(_info(enabled: false, applyBefore: null));
      await _pump(t, const ReferralCodeCard(), api);
      expect(find.byType(TextField), findsNothing);

      // Admin turns it on; the screen is opened again (autoDispose refetch).
      api.info = _info(applyBefore: null);
      await t.pumpWidget(const SizedBox());
      await _pump(t, const ReferralCodeCard(), api);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('no field when the backend no longer offers it', (t) async {
      await _pump(
        t,
        const ReferralCodeCard(),
        _FakeApi(_info(canApply: false)),
      );
      expect(find.byType(TextField), findsNothing);
    });
  });
}
