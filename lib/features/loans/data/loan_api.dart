import 'package:dio/dio.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/loans/domain/loan_models.dart';

/// A refused or failed lending call. Branch on [code], never on the text.
class LoanApiException implements Exception {
  const LoanApiException({
    this.statusCode,
    this.code,
    this.declineReason,
    this.withdrawable,
    this.network = false,
  });

  /// Null when no response arrived.
  final int? statusCode;

  /// `INSUFFICIENT_BALANCE`, `TERMS_OUTDATED`…
  final String? code;
  final String? declineReason;

  /// `INSUFFICIENT_BALANCE`: what the driver may spend now.
  final double? withdrawable;

  /// Timeout or no connection: the request may or may not have landed.
  final bool network;

  /// The loan routes don't exist on this server (LENDING_ENABLED off): a 404
  /// without one of the lending "not found" codes (fiber's own 404).
  bool get lendingOff =>
      statusCode == 404 &&
      code != 'LOAN_NOT_FOUND' &&
      code != 'APPLICATION_NOT_FOUND';

  /// A 404 for one loan / application that isn't the driver's.
  bool get notFound =>
      statusCode == 404 &&
      (code == 'LOAN_NOT_FOUND' || code == 'APPLICATION_NOT_FOUND');

  /// No answer we can trust: a send that may have landed (timeout, lost
  /// connection, a gateway error).
  bool get ambiguous => network || (statusCode != null && statusCode! >= 500);

  factory LoanApiException.from(DioException e) {
    final res = e.response;
    final data = res?.data;
    String? read(String k) {
      if (data is! Map) return null;
      final v = data[k]?.toString().trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    final w = data is Map ? data['withdrawable'] : null;
    return LoanApiException(
      statusCode: res?.statusCode,
      code: read('code'),
      declineReason: read('decline_reason'),
      withdrawable: w is num ? w.toDouble() : double.tryParse('${w ?? ''}'),
      network:
          res == null &&
          e.type != DioExceptionType.cancel &&
          e.type != DioExceptionType.badCertificate,
    );
  }

  @override
  String toString() => 'LoanApiException($statusCode, $code)';
}

/// `/api/driver/loans…`. Every method throws [LoanApiException].
class LoanApi {
  const LoanApi(this._dio);

  final Dio _dio;

  Future<T> _call<T>(
    Future<Response<dynamic>> Function() send,
    T Function(dynamic data) parse,
  ) async {
    try {
      final res = await send();
      return parse(res.data);
    } on DioException catch (e) {
      throw LoanApiException.from(e);
    }
  }

  static Map<String, dynamic> _map(dynamic d) =>
      d is Map ? Map<String, dynamic>.from(d) : const {};

  static List<Map<String, dynamic>> _list(dynamic d) => [
    for (final e in (d is List ? d : const []))
      if (e is Map) Map<String, dynamic>.from(e),
  ];

  Future<LoanOffer> offer() => _call(
    () => _dio.get<dynamic>(Endpoints.loanOffer),
    (d) => LoanOffer.fromJson(_map(d)),
  );

  Future<LoanEligibility> eligibility() => _call(
    () => _dio.get<dynamic>(Endpoints.loanEligibility),
    (d) => LoanEligibility.fromJson(_map(d)),
  );

  Future<LoanQuote> quote(double principal, int termDays) => _call(
    () => _dio.get<dynamic>(
      Endpoints.loanQuote,
      queryParameters: {'principal': _amount(principal), 'term_days': termDays},
    ),
    (d) => LoanQuote.fromJson(_map(d)),
  );

  Future<LoanTerms> terms(double principal, int termDays) => _call(
    () => _dio.get<dynamic>(
      Endpoints.loanTerms,
      queryParameters: {'principal': _amount(principal), 'term_days': termDays},
    ),
    (d) => LoanTerms.fromJson(_map(d)),
  );

  /// `POST /loans` → 202 with the waiting application.
  Future<LoanApplication> apply({
    required double principal,
    required int termDays,
    required LoanTerms terms,
    required Map<String, DateTime> documentsOpened,
  }) => _call(
    () => _dio.post<dynamic>(
      Endpoints.loans,
      data: applyBody(
        principal: principal,
        termDays: termDays,
        terms: terms,
        documentsOpened: documentsOpened,
      ),
    ),
    (d) => LoanApplication.fromJson(_map(d)),
  );

  /// The body of `POST /loans`. Only sent once both tick boxes are ticked.
  static Map<String, dynamic> applyBody({
    required double principal,
    required int termDays,
    required LoanTerms terms,
    required Map<String, DateTime> documentsOpened,
  }) => {
    'principal': _amount(principal),
    'term_days': termDays,
    'accept_terms': true,
    'consent_deduction': true,
    'consent_version': terms.version,
    'terms_sha256': terms.sha256,
    'documents_opened': [
      for (final e in documentsOpened.entries)
        {'kind': e.key, 'opened_at': e.value.toUtc().toIso8601String()},
    ],
  };

  Future<List<LoanApplication>> applications() => _call(
    () => _dio.get<dynamic>(Endpoints.loanApplications),
    (d) => [for (final m in _list(d)) LoanApplication.fromJson(m)],
  );

  Future<void> cancelApplication(String id) => _call(
    () => _dio.post<dynamic>(Endpoints.loanApplicationCancel(id)),
    (_) {},
  );

  Future<AcceptedLoanDocuments> applicationTerms(String id) => _call(
    () => _dio.get<dynamic>(Endpoints.loanApplicationTerms(id)),
    (d) => AcceptedLoanDocuments.fromJson(_map(d)),
  );

  Future<AcceptedLoanDocuments> loanTerms(String loanId) => _call(
    () => _dio.get<dynamic>(Endpoints.loanTermsOf(loanId)),
    (d) => AcceptedLoanDocuments.fromJson(_map(d)),
  );

  /// The driver's loans, newest first (no events).
  Future<List<Loan>> loans() => _call(
    () => _dio.get<dynamic>(Endpoints.loans),
    (d) => [for (final m in _list(d)) Loan.fromJson(m)],
  );

  Future<LoanDetail> loan(String id) => _call(
    () => _dio.get<dynamic>(Endpoints.loan(id)),
    (d) => LoanDetail.fromJson(_map(d)),
  );

  /// [amount] 0 pays the loan off in full. Returns the loan after payment.
  Future<Loan> repay(String id, double amount) => _call(
    () => _dio.post<dynamic>(
      Endpoints.loanRepay(id),
      data: {'amount': _amount(amount)},
    ),
    (d) => Loan.fromJson(_map(d)),
  );

  Future<void> revokeConsent(String id) =>
      _call(() => _dio.post<dynamic>(Endpoints.loanRevokeConsent(id)), (_) {});

  /// The wallet's withdrawable balance (`available_balance` of the payout
  /// summary), for the pay screen. Null when it can't be read.
  Future<double?> withdrawable() async {
    try {
      final res = await _dio.get<dynamic>(Endpoints.driverPayoutsSummary);
      final v = res.data is Map ? (res.data as Map)['available_balance'] : null;
      return v is num ? v.toDouble() : null;
    } on DioException {
      return null;
    }
  }

  /// Whole baht as an int, satang kept otherwise.
  static num _amount(double v) {
    final cents = (v * 100).round();
    return cents % 100 == 0 ? cents ~/ 100 : cents / 100;
  }
}
