/// Router locations of the loan screens (registered in `loan_routes.dart`).
abstract final class LoanPaths {
  /// Offer / not eligible (screen 2).
  static const offer = '/loans';
  static const eligibility = '/loans/eligibility';

  /// Amount → key facts → documents → review (screens 3–6).
  static const apply = '/loans/apply';

  /// My applications (screen 10).
  static const applications = '/loans/applications';

  /// One application: waiting / approved / rejected / record (7, 8, 9).
  static String application(String id) => '/loans/applications/$id';
  static String applicationDocuments(String id) =>
      '/loans/applications/$id/documents';

  /// Loan home, or paid off (11, 16).
  static String loan(String id) => '/loans/loan/$id';

  /// Behind / past due / written off (17).
  static String catchUp(String id) => '/loans/loan/$id/catch-up';
  static String history(String id) => '/loans/loan/$id/history';
  static String pay(String id) => '/loans/loan/$id/pay';

  /// The morning notice for [day] (`YYYY-MM-DD`, Bangkok) (14).
  static String notice(String id, String day) => '/loans/loan/$id/day/$day';
  static String documents(String id) => '/loans/loan/$id/documents';
}

/// Where a lending push opens, or null when it isn't one (`data.type`
/// loan_approved / loan_rejected / loan_daily_notice).
String? loanPushRoute(Map<String, dynamic> data) {
  String? s(String k) {
    final v = data[k]?.toString().trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  switch (s('type')) {
    case 'loan_approved':
      final app = s('application_id');
      if (app != null) return LoanPaths.application(app);
      final loan = s('loan_id');
      return loan != null ? LoanPaths.loan(loan) : LoanPaths.applications;
    case 'loan_rejected':
      final app = s('application_id');
      return app != null ? LoanPaths.application(app) : LoanPaths.applications;
    case 'loan_daily_notice':
      final loan = s('loan_id');
      if (loan == null) return null;
      final day = s('day');
      final valid = day != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day);
      return valid ? LoanPaths.notice(loan, day) : LoanPaths.loan(loan);
    default:
      return null;
  }
}

bool isLoanPush(Map<String, dynamic> data) => loanPushRoute(data) != null;
