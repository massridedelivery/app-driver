import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/auth/account_status_notifier.dart';
import 'package:massdrive/core/managers/api/profile_error_interceptor.dart';

/// Runs a 403 account_deleted reply for a request sent with [sentToken]
/// through the interceptor, with [storedToken] as the current session.
Future<void> _deletedReply({String? sentToken, String? storedToken}) async {
  final req = RequestOptions(
    path: '/api/driver/jobs',
    headers: {if (sentToken != null) 'Authorization': 'Bearer $sentToken'},
  );
  final err = DioException(
    requestOptions: req,
    response: Response(
      requestOptions: req,
      statusCode: 403,
      data: {'error': 'account deleted', 'code': 'account_deleted'},
    ),
  );
  final handler = _Handler();
  final done = handler.settled;
  ProfileErrorInterceptor(
    currentToken: () async => storedToken,
  ).onError(err, handler);
  await done;
}

class _Handler extends ErrorInterceptorHandler {
  Future<void> get settled => future.then((_) {}, onError: (_) {});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(AccountStatusNotifier.instance.clear);

  test('bearerToken reads the Authorization header', () {
    expect(bearerToken({'Authorization': 'Bearer abc'}), 'abc');
    expect(bearerToken({'authorization': 'Bearer abc'}), 'abc');
    expect(bearerToken({'Authorization': 'Basic abc'}), isNull);
    expect(bearerToken({}), isNull);
  });

  test('a 403 for the current token flags the account', () async {
    await _deletedReply(sentToken: 't1', storedToken: 't1');
    expect(
      AccountStatusNotifier.instance.restriction,
      AccountRestriction.deleted,
    );
  });

  test('a late 403 for the previous account is ignored', () async {
    await _deletedReply(sentToken: 'old', storedToken: 'new');
    expect(AccountStatusNotifier.instance.isRestricted, isFalse);
  });

  test('a 403 without a bearer token (sign-in) still flags', () async {
    await _deletedReply(storedToken: null);
    expect(AccountStatusNotifier.instance.isRestricted, isTrue);
  });
}
