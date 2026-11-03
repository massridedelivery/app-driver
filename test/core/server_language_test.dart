import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/data/sources/api_error.dart';
import 'package:massdrive/core/managers/api/header_interceptor.dart';
import 'package:massdrive/core/utils/device_language.dart';
import 'package:massdrive/core/utils/friendly_error.dart';
import 'package:massdrive/features/incoming_job/domain/accept_outcome.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';
import 'package:massdrive/features/payment/domain/collection_amounts.dart';
import 'package:shared_preferences/shared_preferences.dart';

DioException _http(int code, Object? body) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: req, statusCode: code, data: body),
  );
}

class _Capture extends RequestInterceptorHandler {
  RequestOptions? options;
  @override
  void next(RequestOptions requestOptions) => options = requestOptions;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Accept-Language', () {
    test('is the phone language as a tag', () {
      expect(deviceLanguageTag(const Locale('th', 'TH')), 'th-TH');
      expect(deviceLanguageTag(const Locale('en', 'US')), 'en-US');
      expect(deviceLanguageTag(const Locale('und')), 'th');
    });

    test('X-Lang is th or en', () {
      expect(deviceLangCode(const Locale('th', 'TH')), 'th');
      expect(deviceLangCode(const Locale('en', 'GB')), 'en');
      // The backend knows only th and en; anything else reads as Thai.
      expect(deviceLangCode(const Locale('ja')), 'th');
    });

    test('goes on every request through the app Dio', () async {
      SharedPreferences.setMockInitialValues({});
      final handler = _Capture();
      await HeaderInterceptor().onRequest(RequestOptions(path: '/x'), handler);
      expect(handler.options?.headers['Accept-Language'], deviceLanguageTag());
      expect(handler.options?.headers['X-Lang'], deviceLangCode());
    });
  });

  group('server messages are shown as received', () {
    test('message first, then error', () {
      expect(
        ApiError.messageFromBody({'message': 'งานนี้มีคนรับแล้ว', 'error': 'x y'}),
        'งานนี้มีคนรับแล้ว',
      );
      expect(
        ApiError.messageFromBody({'error': 'This job was already taken'}),
        'This job was already taken',
      );
    });

    test('a bare code or an empty field is not a message', () {
      expect(ApiError.messageFromBody({'error': 'job_taken'}), isNull);
      expect(ApiError.messageFromBody({'message': '  '}), isNull);
      expect(ApiError.messageFromBody('plain'), isNull);
    });

    test('a 403 with a reason shows the reason, not "เซสชันหมดอายุ"', () {
      expect(
        friendlyErrorMessage(_http(403, {'message': 'บัญชีของคุณถูกระงับชั่วคราว'})),
        'บัญชีของคุณถูกระงับชั่วคราว',
      );
      expect(
        friendlyErrorMessage(_http(403, {'error': 'documents_not_verified'})),
        'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',
      );
    });

    test('a taken job shows what the backend said, else ours', () {
      expect(
        acceptFailureMessage(
          AcceptOutcome.taken,
          _http(409, {'code': 'job_taken', 'message': 'มีไรเดอร์คนอื่นรับงานนี้แล้ว'}),
        ),
        'มีไรเดอร์คนอื่นรับงานนี้แล้ว',
      );
      expect(
        acceptFailureMessage(
          AcceptOutcome.taken,
          _http(409, {'code': 'job_taken', 'error': 'job_taken'}),
        ),
        'มีคนรับงานนี้ไปแล้ว',
      );
      expect(
        acceptFailureMessage(AcceptOutcome.failed, Exception('timeout')),
        'รับงานไม่สำเร็จ กรุณาลองใหม่',
      );
    });
  });

  // A parcel paid partly with points: the fee to collect is amount_due (49 −
  // 20 points = 29), while driver_earnings stay on the full fee.
  test('a parcel paid partly with points collects amount_due', () {
    final order = MessengerOrder.fromJson({
      'id': 'p1',
      'fare': 49,
      'amount_due': 29,
      'payment_method': 'CASH',
      'driver_earnings': {
        'commission_rate': 0.2,
        'commission': 10,
        'driver_net': 39,
      },
    });
    expect(order.feeDue, 29);
    expect(
      CollectionAmounts.resolve(messenger: true, routeAmount: order.feeDue).fee,
      29,
    );
    expect(order.driverEarnings?.commissionLine, 'ค่าคอม 20% (฿10)');
    expect(order.driverEarnings?.driverNet, 39);
  });
}
