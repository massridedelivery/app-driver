import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/loans/data/loan_api.dart';
import 'package:massdrive/features/loans/domain/loan_apply_logic.dart';
import 'package:massdrive/features/loans/domain/loan_history.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';
import 'package:massdrive/features/loans/domain/loan_notice.dart';
import 'package:massdrive/features/loans/domain/loan_paths.dart';

import 'loan_fixtures.dart';

DioException _err(int? status, [Object? body, DioExceptionType? type]) {
  final req = RequestOptions(path: '/api/driver/loans');
  return DioException(
    requestOptions: req,
    type:
        type ??
        (status == null
            ? DioExceptionType.connectionTimeout
            : DioExceptionType.badResponse),
    response: status == null
        ? null
        : Response(requestOptions: req, statusCode: status, data: body),
  );
}

void main() {
  group('LoanApiException', () {
    test('a route 404 means lending is off; a loan 404 does not', () {
      expect(
        LoanApiException.from(
          _err(404, 'Cannot GET /api/driver/loans/offer'),
        ).lendingOff,
        isTrue,
      );
      final notFound = LoanApiException.from(
        _err(404, {'code': 'LOAN_NOT_FOUND', 'message': 'loan not found'}),
      );
      expect(notFound.lendingOff, isFalse);
      expect(notFound.notFound, isTrue);
    });

    test('reads code, decline_reason and withdrawable', () {
      final e = LoanApiException.from(
        _err(422, {
          'code': 'INSUFFICIENT_BALANCE',
          'message': 'x',
          'withdrawable': 1250.5,
        }),
      );
      expect(e.code, 'INSUFFICIENT_BALANCE');
      expect(e.withdrawable, 1250.5);
      final d = LoanApiException.from(
        _err(422, {'code': 'NOT_ELIGIBLE', 'decline_reason': 'LOW_RATING'}),
      );
      expect(d.declineReason, 'LOW_RATING');
    });

    test('timeouts and 5xx are ambiguous', () {
      expect(LoanApiException.from(_err(null)).ambiguous, isTrue);
      expect(LoanApiException.from(_err(502)).ambiguous, isTrue);
      expect(
        LoanApiException.from(_err(400, {'code': 'INVALID_REQUEST'})).ambiguous,
        isFalse,
      );
    });
  });

  group('POST /loans error codes', () {
    ApplyErrorAction act(int? s, [Map<String, dynamic>? body]) =>
        applyErrorAction(LoanApiException.from(_err(s, body)));

    test('maps each code', () {
      expect(
        act(400, {'code': 'TERMS_OUTDATED'}),
        ApplyErrorAction.termsOutdated,
      );
      expect(
        act(400, {'code': 'CONSENT_REQUIRED'}),
        ApplyErrorAction.consentMissing,
      );
      expect(act(409, {'code': 'OPEN_LOAN'}), ApplyErrorAction.conflict);
      expect(
        act(409, {'code': 'PENDING_APPLICATION'}),
        ApplyErrorAction.conflict,
      );
      expect(
        act(422, {'code': 'NOT_ELIGIBLE', 'decline_reason': 'LOW_RATING'}),
        ApplyErrorAction.declined,
      );
      expect(
        act(400, {'code': 'INVALID_REQUEST'}),
        ApplyErrorAction.fixFigures,
      );
      expect(act(404), ApplyErrorAction.leave);
      expect(act(null), ApplyErrorAction.check);
      expect(act(500, {'message': 'internal error'}), ApplyErrorAction.check);
      expect(
        act(400, {'message': 'invalid request body'}),
        ApplyErrorAction.failed,
      );
    });

    test('repay codes', () {
      RepayErrorAction r(int? s, [Map<String, dynamic>? b]) =>
          repayErrorAction(LoanApiException.from(_err(s, b)));
      expect(
        r(422, {'code': 'INSUFFICIENT_BALANCE', 'withdrawable': 10}),
        RepayErrorAction.insufficient,
      );
      expect(r(409, {'code': 'LOAN_NOT_OPEN'}), RepayErrorAction.refresh);
      expect(r(409, {'code': 'LOAN_CHANGED'}), RepayErrorAction.refresh);
      expect(r(null), RepayErrorAction.check);
      expect(r(404), RepayErrorAction.leave);
    });
  });

  test('apply body: both consents, version, hash, documents_opened', () {
    final terms = LoanTerms(
      version: 'loan-terms-v3',
      sha256: 'abc',
      documents: const [],
    );
    final body = LoanApi.applyBody(
      principal: 3000,
      termDays: 30,
      terms: terms,
      documentsOpened: {'loan_agreement': DateTime.utc(2026, 11, 18, 7, 30)},
    );
    expect(body['principal'], 3000);
    expect(body['principal'], isA<int>());
    expect(body['accept_terms'], isTrue);
    expect(body['consent_deduction'], isTrue);
    expect(body['consent_version'], 'loan-terms-v3');
    expect(body['terms_sha256'], 'abc');
    expect(body['documents_opened'], [
      {'kind': 'loan_agreement', 'opened_at': '2026-11-18T07:30:00.000Z'},
    ]);
  });

  test('after an ambiguous send: only the matching fresh PENDING one', () {
    final sentAt = DateTime.utc(2026, 11, 18, 7, 33);
    List<LoanApplication> apps(Map<String, dynamic> j) => [
      LoanApplication.fromJson(j),
    ];
    expect(
      findSubmittedApplication(
        apps(applicationJson()),
        principal: 3000,
        termDays: 30,
        sentAt: sentAt,
      )?.id,
      'A1',
    );
    expect(
      findSubmittedApplication(
        apps(applicationJson()),
        principal: 2000,
        termDays: 30,
        sentAt: sentAt,
      ),
      isNull,
    );
    expect(
      findSubmittedApplication(
        apps(applicationJson(status: 'CANCELLED')),
        principal: 3000,
        termDays: 30,
        sentAt: sentAt,
      ),
      isNull,
    );
    expect(
      findSubmittedApplication(
        apps(applicationJson(createdAt: '2026-11-18T07:00:00Z')),
        principal: 3000,
        termDays: 30,
        sentAt: sentAt,
      ),
      isNull,
    );
  });

  test('chips stay inside the offer range', () {
    expect(termChoices(30, 180), [30, 45, 60, 90, 120, 180]);
    expect(termChoices(14, 90), [14, 30, 45, 60, 90]);
    expect(amountChoices(500, 8000), [500, 1000, 3000, 8000]);
    expect(amountChoices(500, 2000), [500, 1000, 2000]);
  });

  test('quote declined vs a figures problem', () {
    expect(
      isQuoteDeclined(
        const LoanQuote(canApply: false, declineReason: 'LOW_RATING'),
      ),
      isTrue,
    );
    expect(
      isQuoteDeclined(
        const LoanQuote(canApply: false, problem: 'AMOUNT_TOO_LOW'),
      ),
      isFalse,
    );
    expect(isQuoteDeclined(const LoanQuote(canApply: true)), isFalse);
  });

  test('part-payment preview settles interest first', () {
    final l = Loan.fromJson(loanJson());
    final p = repayPreview(l, 500);
    expect(p.interest, 0.78);
    expect(p.principal, 499.22);
    expect(p.balanceAfter, 1405.04);
  });

  group('pushes', () {
    test('route by data.type', () {
      expect(
        loanPushRoute({
          'type': 'loan_approved',
          'application_id': 'A1',
          'loan_id': 'L1',
        }),
        '/loans/applications/A1',
      );
      expect(
        loanPushRoute({'type': 'loan_rejected', 'application_id': 'A2'}),
        '/loans/applications/A2',
      );
      expect(
        loanPushRoute({
          'type': 'loan_daily_notice',
          'loan_id': 'L1',
          'day': '2026-11-28',
        }),
        '/loans/loan/L1/day/2026-11-28',
      );
      expect(
        loanPushRoute({
          'type': 'loan_daily_notice',
          'loan_id': 'L1',
          'day': 'bad',
        }),
        '/loans/loan/L1',
      );
      expect(loanPushRoute({'type': 'payout_approved'}), isNull);
      expect(isLoanPush({'type': 'loan_rejected'}), isTrue);
    });
  });

  group('history and notice', () {
    LoanDetail detail(
      List<Map<String, dynamic>> events, {
      Map<String, dynamic>? loan,
    }) => LoanDetail.fromJson({'loan': loan ?? loanJson(), 'events': events});
    final events = [
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

    test('grouped by Bangkok day, newest first', () {
      final g = groupEventsByDay(detail(events).events);
      expect(g.map((e) => e.day), [
        DateTime(2026, 11, 28),
        DateTime(2026, 11, 19),
      ]);
      expect(g.first.events.map((e) => e.type), ['DEDUCTION', 'SHORTFALL']);
    });

    test('signs', () {
      LoanEventView v(String type, [double amount = 10]) =>
          eventView(LoanEvent(type: type, amount: amount));
      expect(v('DISBURSEMENT', 3000).amount, '+฿3,000.00');
      expect(v('DISBURSEMENT').positive, isTrue);
      expect(v('DEDUCTION', 100.64).amount, '−฿100.64');
      expect(v('SHORTFALL', 40.64).amount, 'ขาด ฿40.64');
      expect(v('INTEREST_WAIVER', 2.42).amount, 'ลดดอกเบี้ย ฿2.42');
      expect(v('PAUSE', 0).amount, isNull);
      expect(showsEventNote('PAUSE'), isTrue);
      expect(showsEventNote('INTEREST_WAIVER'), isFalse);
    });

    test('notice kinds', () {
      final day = DateTime(2026, 11, 28);
      final partial = loanNoticeFor(detail(events), day);
      expect(partial.kind, LoanNoticeKind.partial);
      expect(partial.deducted, 60);
      expect(partial.shortfall, 40.64);
      expect(partial.asked, 100.64);
      expect(partial.reason, 'KEEP_FLOOR');
      expect(partial.interest, 0.87);

      expect(
        loanNoticeFor(detail(events.sublist(0, 2)), day).kind,
        LoanNoticeKind.full,
      );
      expect(
        loanNoticeFor(detail([events[0], events[2]]), day).kind,
        LoanNoticeKind.nothing,
      );
      expect(
        loanNoticeFor(detail(events), DateTime(2026, 11, 29)).kind,
        LoanNoticeKind.noData,
      );
      expect(
        loanNoticeFor(
          detail(const [], loan: loanJson(pausedUntil: '2026-11-30')),
          day,
        ).kind,
        LoanNoticeKind.paused,
      );
      expect(
        loanNoticeFor(
          detail(
            const [],
            loan: loanJson(consentRevokedAt: '2026-11-27T02:00:00Z'),
          ),
          day,
        ).kind,
        LoanNoticeKind.autoOff,
      );
    });
  });
}
