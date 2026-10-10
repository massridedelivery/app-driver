import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/auth/account_status_notifier.dart';

void main() {
  AccountRestriction? detect(int? code, Object? data, {bool profile = true}) =>
      detectAccountRestriction(
        statusCode: code,
        data: data,
        isProfileEndpoint: profile,
      );

  test('deleted driver: profile 404 "profile not found"', () {
    expect(detect(404, {'error': 'profile not found'}),
        AccountRestriction.deleted);
  });

  test('404 on other endpoints is not a deletion', () {
    expect(detect(404, {'error': 'no active offer found'}, profile: false),
        isNull);
    expect(detect(404, {'error': 'profile not found'}, profile: false), isNull);
  });

  test('403 with suspension wording on any endpoint', () {
    expect(detect(403, {'error': 'driver account suspended'}, profile: false),
        AccountRestriction.suspended);
    expect(detect(403, {'error': 'Account has been deactivated'}),
        AccountRestriction.suspended);
    expect(detect(403, {'message': 'user is banned'}, profile: false),
        AccountRestriction.suspended);
  });

  test('ordinary 403 business errors are not a suspension', () {
    expect(detect(403, {'error': 'documents_not_verified'}, profile: false),
        isNull);
    expect(detect(403, {'error': 'COD blocked: settle your debt'},
            profile: false),
        isNull);
  });

  test('profile 200 carrying an account status', () {
    expect(detect(200, {'account_status': 'suspended'}),
        AccountRestriction.suspended);
    expect(detect(200, {'is_banned': true}), AccountRestriction.suspended);
    expect(detect(200, {'deleted_at': '2026-10-10T00:00:00Z'}),
        AccountRestriction.deleted);
  });

  test('normal profile and online status values are fine', () {
    expect(detect(200, {'status': 'offline', 'is_verified': false}), isNull);
    expect(detect(200, {'status': 'online'}), isNull);
  });

  test('notifier flags, never downgrades deleted, and clears', () {
    final n = AccountStatusNotifier.instance..clear();
    n.markRestricted(AccountRestriction.deleted);
    n.markRestricted(AccountRestriction.suspended);
    expect(n.restriction, AccountRestriction.deleted);
    n.clear();
    expect(n.isRestricted, isFalse);
  });
}
