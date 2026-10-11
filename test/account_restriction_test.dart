import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/auth/account_status_notifier.dart';
import 'package:massdrive/core/utils/friendly_error.dart';

void main() {
  AccountRestriction? detect(int? code, Object? data) =>
      detectAccountRestriction(statusCode: code, data: data);

  test('403 code=account_deleted / account_suspended', () {
    expect(
      detect(403, {'error': 'account deleted', 'code': 'account_deleted'}),
      AccountRestriction.deleted,
    );
    expect(
      detect(403, {'error': 'account suspended', 'code': 'account_suspended'}),
      AccountRestriction.suspended,
    );
  });

  test('only the code counts, never the wording', () {
    expect(detect(403, {'error': 'account suspended'}), isNull);
    expect(detect(404, {'error': 'profile not found'}), isNull);
  });

  test('other 403s and other statuses are not restrictions', () {
    expect(detect(403, {'error': 'documents_not_verified'}), isNull);
    expect(detect(400, {'code': 'account_suspended'}), isNull);
    expect(detect(200, {'code': 'account_suspended'}), isNull);
    expect(detect(403, 'plain text'), isNull);
  });

  test('sign-in exception shows the Thai contact message', () {
    const e = AccountRestrictedLoginException(AccountRestriction.suspended);
    expect(friendlyErrorMessage(e), accountRestrictedLoginMessage);
  });

  test('notifier flags and clears', () {
    final n = AccountStatusNotifier.instance..clear();
    n.markRestricted(AccountRestriction.suspended);
    expect(n.restriction, AccountRestriction.suspended);
    n.clear();
    expect(n.isRestricted, isFalse);
  });
}
