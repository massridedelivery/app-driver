import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';
import 'package:massdrive/features/loans/presentation/loan_routes.dart';

import 'loan_fixtures.dart';

/// Answers lending calls from a path → (status, body) table.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, (int, Object?)> routes;
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? _,
    Future<void>? _,
  ) async {
    final key = '${o.method} ${o.path}';
    calls.add(key);
    final hit = routes[key] ?? (404, 'Cannot ${o.method} ${o.path}');
    return ResponseBody.fromString(
      jsonEncode(hit.$2),
      hit.$1,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _doc(String kind, {bool separate = false}) => {
  'kind': kind,
  'separate': separate,
  'title': {
    'loan_agreement': 'สัญญากู้ยืมเงิน',
    'deduction_consent': 'หนังสือยินยอมให้หักรายได้',
    'privacy_notice': 'ประกาศความเป็นส่วนตัว',
  }[kind],
  'body': '# $kind\n\nข้อ 1 ทดสอบ **ตัวหนา**\n- รายการ',
};

final _terms = {
  'version': 'loan-terms-v3',
  'sha256': '9f2c0000000000e41a',
  'documents': [
    _doc('loan_agreement'),
    _doc('deduction_consent', separate: true),
    _doc('privacy_notice'),
  ],
};

final _events = [
  {
    'type': 'DISBURSEMENT',
    'amount': 3000,
    'created_at': '2026-11-19T07:20:00Z',
  },
  {
    'type': 'DEDUCTION',
    'amount': 60,
    'principal_component': 59.13,
    'interest_component': 0.87,
    'deduction_date': '2026-11-28',
    'created_at': '2026-11-28T16:00:00Z',
  },
  {
    'type': 'SHORTFALL',
    'amount': 40.64,
    'deduction_date': '2026-11-28',
    'note': 'KEEP_FLOOR',
    'created_at': '2026-11-28T16:00:01Z',
  },
];

Map<String, (int, Object?)> _routes({
  Map<String, dynamic>? loan,
  List<Object?>? apps,
}) => {
  'GET /api/driver/loans/offer': (200, offerJson()),
  'GET /api/driver/loans/eligibility': (
    200,
    {
      'text': 'คุณสมบัติผู้ขอสินเชื่อ\n• วิ่งงาน 3 เดือน',
      'rules': {
        'min_active_months': 3,
        'min_active_days_per_month': 10,
        'min_rating': 4.5,
        'step_up_limits_thb': [3000, 5000],
      },
    },
  ),
  'GET /api/driver/loans/quote': (
    200,
    {
      'can_apply': true,
      'principal': 3000,
      'term_days': 30,
      'scheduled_total': 3019.2,
      'disclosure': disclosureJson(),
      'consent_version': 'loan-terms-v3',
    },
  ),
  'GET /api/driver/loans/terms': (200, _terms),
  'GET /api/driver/loans/applications': (200, apps ?? [applicationJson()]),
  'GET /api/driver/loans/applications/A1/terms': (
    200,
    {
      ..._terms,
      'application_id': 'A1',
      'status': 'PENDING',
      'accepted_at': '2026-11-18T07:32:00Z',
      'principal': 3000,
    },
  ),
  'GET /api/driver/loans/L1/terms': (
    200,
    {
      ..._terms,
      'application_id': 'A1',
      'status': 'APPROVED',
      'accepted_at': '2026-11-18T07:32:00Z',
      'principal': 3000,
      'approved_principal': 2000,
      'loan_id': 'L1',
    },
  ),
  'GET /api/driver/loans': (200, [loan ?? loanJson()]),
  'GET /api/driver/loans/L1': (
    200,
    {'loan': loan ?? loanJson(), 'events': _events},
  ),
  'GET /api/driver/payouts/summary': (200, {'available_balance': 1250}),
};

Future<_FakeAdapter> _pump(
  WidgetTester tester,
  String location,
  Map<String, (int, Object?)> routes,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final adapter = _FakeAdapter(routes);
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = adapter;
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('HOME')),
      ),
      ...loanRoutes,
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dioProvider.overrideWithValue(dio)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

void main() {
  testWidgets('offer (2A): hero, sample cost, rights, footer', (t) async {
    await _pump(t, LoanPaths.offer, _routes());
    expect(find.text('฿8,000'), findsOneWidget);
    expect(
      find.text('ตัวอย่างค่าใช้จ่าย: กู้ 3,000 บาท 30 วัน'),
      findsOneWidget,
    );
    expect(find.text('เริ่มขอสินเชื่อ'), findsOneWidget);
    expect(find.text('ไว้ภายหลัง'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('offer not eligible: Thai line + eligibility link', (t) async {
    final r = _routes()
      ..['GET /api/driver/loans/offer'] = (
        200,
        offerJson(eligible: false, reason: 'INACTIVE_MONTHS'),
      );
    await _pump(t, LoanPaths.offer, r);
    expect(find.text('ต้องวิ่งงานต่อเนื่องอย่างน้อย 3 เดือน'), findsOneWidget);
    expect(find.text('อ่านคุณสมบัติการขอสินเชื่อ'), findsOneWidget);
    expect(find.textContaining('INACTIVE_MONTHS'), findsNothing);
  });

  testWidgets('lending off (404): back home, no message', (t) async {
    await _pump(t, LoanPaths.offer, {});
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('apply: quote → key facts → documents gated → review → submit', (
    t,
  ) async {
    final r = _routes()
      ..['POST /api/driver/loans'] = (
        202,
        applicationJson(createdAt: DateTime.now().toUtc().toIso8601String()),
      );
    final a = await _pump(t, LoanPaths.apply, r);
    await t.enterText(find.byType(TextField), '3000');
    await t.tap(find.widgetWithText(ChoiceChip, '30'));
    await t.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('฿3,019.20'), findsOneWidget);
    await t.tap(find.text('ถัดไป'));
    await t.pumpAndSettle();
    expect(find.text('สรุปข้อมูลสำคัญ'), findsOneWidget);
    await t.tap(find.text('ถัดไป: อ่านเอกสาร'));
    await t.pumpAndSettle();

    // Tick boxes start empty and disabled until the documents are read.
    final boxes = find.byType(CheckboxListTile);
    expect(boxes, findsNWidgets(2));
    for (final e in t.widgetList<CheckboxListTile>(boxes)) {
      expect(e.value, isFalse);
      expect(e.onChanged, isNull);
    }
    // Read all three in the reader (short bodies fit on screen).
    await t.tap(find.text('สัญญากู้ยืมเงิน'));
    await t.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await t.tap(find.text('อ่านจบ: ถัดไป ›'));
      await t.pumpAndSettle();
    }
    await t.tap(find.text('กลับไปยอมรับ'));
    await t.pumpAndSettle();
    await t.tap(boxes.at(0));
    await t.tap(boxes.at(1));
    await t.pumpAndSettle();
    await t.tap(find.text('ถัดไป'));
    await t.pumpAndSettle();
    expect(find.text('ยืนยันส่งคำขอ'), findsOneWidget);
    await t.tap(find.text('ยืนยันส่งคำขอ'));
    await t.pumpAndSettle();
    expect(a.calls, contains('POST /api/driver/loans'));
    expect(find.text('รอเจ้าหน้าที่อนุมัติ'), findsWidgets);
  });

  testWidgets('application pending (7E) with cancel', (t) async {
    await _pump(t, LoanPaths.application('A1'), _routes());
    expect(find.text('ตัวเลขที่ขอ'), findsOneWidget);
    expect(find.text('ยกเลิกคำขอ'), findsOneWidget);
    expect(
      find.textContaining('ยอมรับเอกสาร ฉบับ loan-terms-v3'),
      findsOneWidget,
    );
  });

  testWidgets('approved lower (8A) highlights the new instalment', (t) async {
    final r = _routes(
      apps: [applicationJson(status: 'APPROVED', approved: 2000, loanId: 'L1')],
    );
    await _pump(t, LoanPaths.application('A1'), r);
    expect(find.textContaining('อนุมัติน้อยกว่าที่ขอ'), findsOneWidget);
    expect(find.text('ถอนเงิน'), findsOneWidget);
  });

  testWidgets('rejected (9E): neutral heading, no charge line', (t) async {
    final r = _routes(apps: [applicationJson(status: 'REJECTED')]);
    await _pump(t, LoanPaths.application('A1'), r);
    expect(find.text('ⓘ คำขอยังไม่ได้รับอนุมัติ'), findsOneWidget);
    expect(find.text('ไม่มีค่าใช้จ่ายใดๆ จากคำขอนี้'), findsOneWidget);
    expect(find.textContaining('ถูกปฏิเสธ'), findsNothing);
  });

  testWidgets('applications (10B) grouped', (t) async {
    final r = _routes(
      apps: [
        applicationJson(),
        applicationJson(id: 'A0', status: 'CANCELLED'),
      ],
    );
    await _pump(t, LoanPaths.applications, r);
    expect(find.text('กำลังดำเนินการ'), findsOneWidget);
    expect(find.text('ที่ผ่านมา'), findsOneWidget);
  });

  testWidgets('loan home (11A) and revoke needs two sheets', (t) async {
    final r = _routes()
      ..['POST /api/driver/loans/L1/revoke-consent'] = (200, {'message': 'ok'});
    final a = await _pump(t, LoanPaths.loan('L1'), r);
    expect(find.text('฿1,905.04'), findsOneWidget);
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(find.text('ปิดการหักอัตโนมัติ?'), findsOneWidget);
    await t.tap(find.text('ต่อไป'));
    await t.pumpAndSettle();
    expect(
      a.calls,
      isNot(contains('POST /api/driver/loans/L1/revoke-consent')),
    );
    await t.tap(find.text('ยืนยันปิด'));
    await t.pumpAndSettle();
    expect(a.calls, contains('POST /api/driver/loans/L1/revoke-consent'));
  });

  testWidgets('behind (17A) and written off', (t) async {
    await _pump(
      t,
      LoanPaths.catchUp('L1'),
      _routes(loan: loanJson(daysBehind: 2, arrears: 201.28)),
    );
    expect(find.text('ยอดผ่อนค้างอยู่ 2 วัน'), findsOneWidget);
    expect(find.text('ชำระยอดค้าง ฿201.28'), findsOneWidget);
  });

  testWidgets('written off is payable', (t) async {
    await _pump(
      t,
      LoanPaths.loan('L1'),
      _routes(loan: loanJson(status: 'WRITTEN_OFF')),
    );
    expect(find.text('ชำระยอดคงเหลือ'), findsOneWidget);
  });

  testWidgets('paid off (16A)', (t) async {
    await _pump(
      t,
      LoanPaths.loan('L1'),
      _routes(
        loan: loanJson(status: 'PAID_OFF', paidOffAt: '2026-12-18T23:00:00Z'),
      ),
    );
    expect(find.text('ปิดยอดแล้ว'), findsOneWidget);
    expect(find.text('ไม่มียอดค้าง'), findsOneWidget);
  });

  testWidgets('history (12A)', (t) async {
    await _pump(t, LoanPaths.history('L1'), _routes());
    expect(find.text('ขาด ฿40.64'), findsOneWidget);
    expect(find.text('+฿3,000.00'), findsOneWidget);
  });

  testWidgets('pay: INSUFFICIENT_BALANCE suggests the withdrawable amount', (
    t,
  ) async {
    final r = _routes()
      ..['POST /api/driver/loans/L1/repay'] = (
        422,
        {'code': 'INSUFFICIENT_BALANCE', 'message': 'x', 'withdrawable': 1250},
      );
    await _pump(t, LoanPaths.pay('L1'), r);
    await t.tap(find.text('จ่ายบางส่วน'));
    await t.pumpAndSettle();
    await t.tap(find.text('ถัดไป'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '1500');
    await t.pumpAndSettle();
    await t.tap(find.text('ชำระ ฿1,500.00'));
    await t.pumpAndSettle();
    expect(
      find.textContaining('ยอดที่ถอนได้ในกระเป๋าไม่พอ (มี ฿1,250.00)'),
      findsOneWidget,
    );
    expect(find.text('จ่าย ฿1,250.00 แทน'), findsOneWidget);
  });

  testWidgets('morning notice (14B) partial day', (t) async {
    await _pump(t, LoanPaths.notice('L1', '2026-11-28'), _routes());
    expect(find.text('ใบสรุปการหักรายได้'), findsOneWidget);
    expect(find.text('฿40.64'), findsWidgets);
  });

  testWidgets('documents (18C) lower-amount notice', (t) async {
    await _pump(t, LoanPaths.documents('L1'), _routes());
    expect(find.text('หลักฐานการยอมรับ'), findsOneWidget);
    expect(find.text('9f2c…e41a'), findsOneWidget);
    expect(find.textContaining('เอกสารนี้แสดงยอดที่คุณขอกู้ 3,000 บาท'), findsOneWidget);
  });
}
