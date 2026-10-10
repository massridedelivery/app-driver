import 'package:flutter/foundation.dart';

/// Why the driver can no longer use the app.
enum AccountRestriction {
  /// The driver account was deleted (the profile no longer exists).
  deleted,

  /// The account still exists but has been suspended / banned by the company.
  suspended,
}

/// App-wide flag for a driver whose account was deleted or suspended while
/// they still hold a valid session.
///
/// Like [SessionNotifier] this is a plain singleton so the Dio interceptor can
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
    // Don't downgrade "deleted" to "suspended" if both signals arrive.
    if (_restriction == AccountRestriction.deleted) return;
    _restriction = restriction;
    notifyListeners();
  }

  void clear() {
    if (_restriction == null) return;
    _restriction = null;
    notifyListeners();
  }
}

/// Error wording the backend may use for a suspended/banned account. Kept
/// specific on purpose: a bare "blocked" would also match unrelated 403s such
/// as COD-blocked on a messenger job.
final RegExp _suspendedWording = RegExp(
  r'suspend|banned|\bban\b|deactivat|account (is |has been )?(disabled|locked|inactive|terminated)',
  caseSensitive: false,
);

const Set<String> _restrictedStatusValues = {
  'suspended',
  'banned',
  'deactivated',
  'disabled',
  'terminated',
};

/// Shown on the login / OTP screens when the backend refuses a deleted or
/// suspended driver at sign-in.
const String accountRestrictedLoginMessage =
    'บัญชีของคุณถูกระงับหรือถูกลบ กรุณาติดต่อบริษัท โทร 065-6924555';

/// True when a sign-in error (OTP send / verify) says the account is deleted
/// or suspended, so the login screens show [accountRestrictedLoginMessage].
bool isAccountRestrictedLoginError(int? statusCode, Object? data) {
  final error = data is Map
      ? (data['error'] ?? data['message'])?.toString()
      : null;
  if (error == null) return false;
  if (statusCode == 403 && _suspendedWording.hasMatch(error)) return true;
  return RegExp(
    r'account (was |has been |is )?deleted|user deleted',
    caseSensitive: false,
  ).hasMatch(error);
}

/// Decide from an API reply whether the driver's account is deleted or
/// suspended. Returns null for everything else.
///
/// Known contract (dev API): a deleted driver still holds a valid token, but
/// `GET /api/driver/profile` answers `404 {"error": "profile not found"}`.
/// Suspension isn't specified yet, so we accept the likely shapes: a 403 whose
/// error says suspended/banned/deactivated, or a profile payload carrying an
/// account-status field.
AccountRestriction? detectAccountRestriction({
  required int? statusCode,
  required Object? data,
  required bool isProfileEndpoint,
}) {
  final error = data is Map
      ? (data['error'] ?? data['message'])?.toString()
      : null;

  if (isProfileEndpoint &&
      statusCode == 404 &&
      (error ?? '').toLowerCase().contains('profile not found')) {
    return AccountRestriction.deleted;
  }

  if (statusCode == 403 && error != null && _suspendedWording.hasMatch(error)) {
    return AccountRestriction.suspended;
  }

  // A successful profile read that itself says the account is restricted.
  if (isProfileEndpoint && statusCode == 200 && data is Map) {
    final accountStatus = data['account_status']?.toString().toLowerCase();
    if (accountStatus == 'deleted') return AccountRestriction.deleted;
    if (accountStatus != null &&
        (_restrictedStatusValues.contains(accountStatus) ||
            accountStatus == 'inactive')) {
      return AccountRestriction.suspended;
    }
    // `status` is normally the online state (online/offline/busy); only the
    // explicit restriction values count.
    final status = data['status']?.toString().toLowerCase();
    if (status != null && _restrictedStatusValues.contains(status)) {
      return AccountRestriction.suspended;
    }
    if (data['is_suspended'] == true || data['is_banned'] == true) {
      return AccountRestriction.suspended;
    }
    if (data['deleted_at'] != null) return AccountRestriction.deleted;
  }

  return null;
}
