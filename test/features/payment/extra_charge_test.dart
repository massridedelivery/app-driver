import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/managers/api/api_manager.dart';
import 'package:massdrive/core/models/socket_message_model.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/call/presentation/controllers/call_availability.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/incoming_job/presentation/states/incoming_job_state.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';
import 'package:massdrive/features/messenger/presentation/controllers/messenger_controller.dart';
import 'package:massdrive/features/messenger/presentation/states/messenger_state.dart';
import 'package:massdrive/features/payment/data/payment_api_service.dart';
import 'package:massdrive/features/payment/domain/extra_charge.dart';
import 'package:massdrive/features/payment/presentation/screens/payment_screen.dart';
import 'package:massdrive/features/review/data/customer_review_api.dart';

IncomingJobModel _ride({
  double toll = 0,
  double other = 0,
  String? note,
  double? due,
  String method = 'CASH',
  String? paymentStatus,
}) => IncomingJobModel(
  jobId: 'r1',
  pickupAddress: 'a',
  dropoffAddress: 'b',
  pickupLat: 13.7,
  pickupLng: 100.5,
  dropoffLat: 13.8,
  dropoffLng: 100.6,
  netIncome: 100,
  amountDue: due ?? 100 + toll + other,
  tollFee: toll,
  otherFee: other,
  otherFeeNote: note,
  paymentMethod: method,
  paymentStatus: paymentStatus,
);

/// The ride on the server: refreshActiveJob reads it back after a PUT.
class _Jobs extends IncomingJobController {
  _Jobs(this.job, this.server);
  final IncomingJobModel? job;
  final IncomingJobModel Function() server;

  @override
  IncomingJobState build() => IncomingJobState(currentJob: job);

  @override
  Future<IncomingJobModel?> refreshActiveJob() async {
    final fresh = server();
    state = state.copyWith(currentJob: fresh);
    return fresh;
  }
}

class _Messenger extends MessengerController {
  _Messenger(this.order);
  final MessengerOrder? order;
  @override
  MessengerState build() => MessengerState(activeOrder: order);
}

class _Sock implements SocketService {
  @override
  Stream<SocketMessageModel> get messages => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _Calls extends CallAvailability {
  @override
  CallAvailabilityState build() => const CallAvailabilityState(enabled: false);
}

/// Records what was sent; [fail] turns every PUT into a 409 with a message.
class _Api extends PaymentApiService {
  _Api() : super(dio: Dio());
  final calls = <String>[];
  double toll = 0, other = 0;
  String note = '';
  DioException? fail;
  final intents = <double>[];

  /// The QR asks for the server's amount_due at the time it is minted.
  double Function() amountDue = () => 0;

  @override
  Future<ResponseData> createIntent({
    required String orderId,
    required bool messenger,
  }) async {
    intents.add(amountDue());
    return ResponseData(
      data: {
        'intent_id': 'i${intents.length}',
        'status': 'AWAITING_PAYMENT',
        'amount': amountDue(),
        'qr_code_url': 'https://qr.test/${intents.length}.png',
      },
      isSuccessful: true,
      errorStatusCode: 200,
    );
  }

  @override
  Future<ResponseData> getIntent(String intentId) async => ResponseData(
    data: {'status': 'AWAITING_PAYMENT'},
    isSuccessful: true,
    errorStatusCode: 200,
  );

  void _check() {
    if (fail != null) throw fail!;
  }

  @override
  Future<void> setRideToll({required String jobId, required double toll}) async {
    _check();
    calls.add('toll $jobId $toll');
    this.toll = toll;
  }

  @override
  Future<void> setRideOtherFee({
    required String jobId,
    required double fee,
    required String note,
  }) async {
    _check();
    calls.add('other $jobId $fee $note');
    other = fee;
    this.note = note;
  }

  @override
  Future<Map<String, dynamic>> setParcelOtherFee({
    required String orderId,
    required double fee,
    required String note,
  }) async {
    _check();
    calls.add('parcel $orderId $fee $note');
    // Fee 63, promo 10, parking 40 → amount_due 93; the driver keeps 90.
    return {
      'id': orderId,
      'fare': 63,
      'amount_due': 63 - 10 + fee,
      'other_fee': fee,
      'other_fee_note': note,
      'payment_method': 'CASH',
      'payer': 'RECIPIENT',
      'driver_earnings': {
        'commission_rate': 0.2,
        'commission': 13,
        'driver_net': 50 + fee,
      },
    };
  }
}

DioException _conflict(String message) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: req,
      statusCode: 409,
      data: {'message': message},
    ),
  );
}

Future<_Api> _open(
  WidgetTester tester,
  PaymentScreen screen, {
  IncomingJobModel? ride,
  MessengerOrder? order,
}) async {
  final api = _Api()..amountDue = () => 0;
  api.amountDue = () => 100 + api.toll + api.other;
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        incomingJobControllerProvider.overrideWith(
          () => _Jobs(
            ride,
            () => _ride(toll: api.toll, other: api.other, note: api.note),
          ),
        ),
        messengerControllerProvider.overrideWith(() => _Messenger(order)),
        paymentApiServiceProvider.overrideWithValue(api),
        socketServiceProvider.overrideWithValue(_Sock()),
        callAvailabilityProvider.overrideWith(_Calls.new),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
  return api;
}

Future<void> _enter(
  WidgetTester tester,
  String button,
  String amount, {
  String? note,
}) async {
  // Not pumpAndSettle: the QR view's "waiting for the scan" spinner never
  // stops.
  Future<void> settle() async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  await tester.tap(find.textContaining(button).first);
  await settle();
  await tester.enterText(find.byType(TextField).first, amount);
  if (note != null) await tester.enterText(find.byType(TextField).last, note);
  await tester.tap(find.text('บันทึก'));
  await settle();
}

const _rideCash = PaymentScreen(
  service: ReviewService.ride,
  amount: 100,
  orderId: 'r1',
  gateCompletion: true,
  methodLabel: 'CASH',
);

void main() {
  group('extraChargeError', () {
    test('an amount needs to say what it was', () {
      expect(
        extraChargeError(ExtraCharge.other, amount: 40),
        'กรุณาระบุว่าเป็นค่าอะไร',
      );
      expect(
        extraChargeError(ExtraCharge.other, amount: 40, note: 'ค่าจอดรถ'),
        isNull,
      );
    });

    test('0 clears another cost; a toll must be above 0; at most 500', () {
      expect(extraChargeError(ExtraCharge.other, amount: 0), isNull);
      expect(extraChargeError(ExtraCharge.toll, amount: 0), isNotNull);
      expect(extraChargeError(ExtraCharge.toll, amount: 500), isNull);
      expect(
        extraChargeError(ExtraCharge.toll, amount: 501),
        'ใส่ได้สูงสุด ฿500',
      );
      expect(extraChargeError(ExtraCharge.toll, amount: null), isNotNull);
    });
  });

  testWidgets('a ride shows both buttons, a parcel only อื่นๆ, food none', (
    tester,
  ) async {
    await _open(tester, _rideCash, ride: _ride());
    expect(find.text('ค่าทางด่วน'), findsOneWidget);
    expect(find.text('อื่นๆ'), findsOneWidget);

    await _open(
      tester,
      const PaymentScreen(
        service: ReviewService.messenger,
        amount: 53,
        orderId: 'p1',
        gateCompletion: true,
        methodLabel: 'CASH',
      ),
      order: const MessengerOrder(id: 'p1', fare: 63, amountDue: 53),
    );
    expect(find.text('ค่าทางด่วน'), findsNothing);
    expect(find.text('อื่นๆ'), findsOneWidget);

    await _open(
      tester,
      const PaymentScreen(service: ReviewService.food),
      ride: _ride(),
    );
    expect(find.text('ค่าทางด่วน'), findsNothing);
    expect(find.text('อื่นๆ'), findsNothing);
  });

  testWidgets('nothing to add once the passenger has paid', (tester) async {
    await _open(tester, _rideCash, ride: _ride(paymentStatus: 'PAID', due: 0));
    expect(find.text('ค่าทางด่วน'), findsNothing);
  });

  // E2: a cash ride, toll 25 + parking 40 → the bill is the fare + 65, read
  // back from the server's amount_due.
  testWidgets('a cash ride collects amount_due after a toll and parking', (
    tester,
  ) async {
    final api = await _open(tester, _rideCash, ride: _ride());
    await _enter(tester, 'ค่าทางด่วน', '25');
    await _enter(tester, 'อื่นๆ', '40', note: 'ค่าจอดรถ');

    expect(api.calls, ['toll r1 25.0', 'other r1 40.0 ค่าจอดรถ']);
    expect(find.text('฿165'), findsOneWidget);
    expect(find.text('ค่าอื่นๆ (ค่าจอดรถ)'), findsOneWidget);
    expect(find.text('ค่าทางด่วน ฿25'), findsOneWidget);
  });

  // E5: no note → said before anything is sent.
  testWidgets('another cost without a note is not sent', (tester) async {
    final api = await _open(tester, _rideCash, ride: _ride());
    await _enter(tester, 'อื่นๆ', '40');
    expect(find.text('กรุณาระบุว่าเป็นค่าอะไร'), findsOneWidget);
    expect(api.calls, isEmpty);
  });

  // E4: the backend refuses once paid — its message is shown as sent.
  testWidgets('a refusal shows the backend message', (tester) async {
    final api = await _open(tester, _rideCash, ride: _ride());
    api.fail = _conflict('เพิ่มค่าใช้จ่ายได้ก่อนลูกค้าชำระเงินเท่านั้น');
    await _enter(tester, 'ค่าทางด่วน', '25');
    expect(
      find.text('เพิ่มค่าใช้จ่ายได้ก่อนลูกค้าชำระเงินเท่านั้น'),
      findsOneWidget,
    );
  });

  // E3 (cash side): fee 63, promo 10, parking 40 → collect 93, net 90.
  testWidgets('a parcel takes amount_due and earnings from the order', (
    tester,
  ) async {
    final api = await _open(
      tester,
      const PaymentScreen(
        service: ReviewService.messenger,
        amount: 53,
        orderId: 'p1',
        gateCompletion: true,
        methodLabel: 'CASH',
      ),
      order: const MessengerOrder(id: 'p1', fare: 63, amountDue: 53),
    );
    await _enter(tester, 'อื่นๆ', '40', note: 'ค่าจอดรถ');

    expect(api.calls, ['parcel p1 40.0 ค่าจอดรถ']);
    expect(find.text('฿93'), findsOneWidget);
    expect(find.text('ค่าอื่นๆ (ค่าจอดรถ)'), findsOneWidget);
    expect(find.text('฿90'), findsOneWidget);
  });

  // E1: a PromptPay ride, toll 25 + parking 40 → each change voids the QR
  // and a new one is minted for the new amount_due (fare + 65).
  testWidgets('a QR ride asks for a new QR after each charge', (tester) async {
    final api = await _open(
      tester,
      const PaymentScreen(
        service: ReviewService.ride,
        amount: 100,
        orderId: 'r1',
        gateCompletion: true,
        methodLabel: 'PROMPTPAY',
      ),
      ride: _ride(method: 'PROMPTPAY'),
    );
    await tester.pump();
    expect(api.intents, [100]);

    await _enter(tester, 'ค่าทางด่วน', '25');
    await _enter(tester, 'อื่นๆ', '40', note: 'ค่าจอดรถ');

    expect(api.intents, [100, 125, 165]);
    expect(find.text('165'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
