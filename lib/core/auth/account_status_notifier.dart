import 'package:flutter/foundation.dart';

/// Why the driver can no longer use the app.
enum AccountRestriction {
  /// The driver account was deleted.
  deleted,

  /// The account still exists but has been suspended by the company.
  suspended,
}

/// App-wide flag for a driver whose account was deleted or suspended.
///
/// Like [SessionNotifier] this is a plain singleton so the Dio interceptors can
/// set it, and the router listens to it: while restricted, every location
/// except the "contact the company" screen and settings redirects there.
/// Cleared whenever the session changes (login / logout).
class AccountStatusNotifier extends ChangeNotifier {
  AccountStatusNotifier._();

  static final AccountStatusNotifier instance = AccountStatusNotifier._();

  AccountRestriction? _restriction;

  AccountRestriction? get restriction => _restriction;
  bool get isRestricted => _restriction != null;

  void markRestricted(AccountRestriction restriction) {
    if (_restriction == restriction) return;
    _restriction = restriction;
    notifyListeners();
  }

  void clear() {
    if (_restriction == null) return;
    _restriction = null;
    notifyListeners();
  }
}

/// Backend contract: any authenticated endpoint — including `POST
/// /auth/refresh` and, for a suspended driver, `/auth/otp/send` and
/// `/auth/otp/verify` — answers HTTP 403 with a machine-readable `code`:
///
///   403 {"error": "account suspended", "code": "account_suspended"}
///   403 {"error": "account deleted",   "code": "account_deleted"}
///
/// Only the code is trusted (never the error wording); other 403s — e.g.
/// `documents_not_verified` — are ordinary business errors.
AccountRestriction? detectAccountRestriction({
  required int? statusCode,
  required Object? data,
}) {
  if (statusCode != 403 || data is! Map) return null;
  switch (data['code']?.toString()) {
    case 'account_deleted':
      return AccountRestriction.deleted;
    case 'account_suspended':
      return AccountRestriction.suspended;
  }
  return null;
}

/// Shown on the login / OTP screens when sign-in is refused because the
/// account is suspended (or deleted).
const String accountRestrictedLoginMessage =
    'บัญชีของคุณถูกระงับ กรุณาติดต่อบริษัท';

/// Thrown by the sign-in API calls when the backend refuses a suspended or
/// deleted driver, so the login / OTP screens can offer a call button.
class AccountRestrictedLoginException implements Exception {
  const AccountRestrictedLoginException(this.restriction);

  final AccountRestriction restriction;

  @override
  String toString() => 'Exception: $accountRestrictedLoginMessage';
}
