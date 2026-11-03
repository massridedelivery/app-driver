import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/incoming_job/presentation/states/incoming_job_state.dart';
import 'package:massdrive/features/payment/presentation/screens/payment_screen.dart';
import 'package:massdrive/features/review/data/customer_review_api.dart';

class _Jobs extends IncomingJobController {
  _Jobs(this.job);
  final IncomingJobModel? job;

  @override
  IncomingJobState build() => IncomingJobState(currentJob: job);
}

IncomingJobModel _foodJob({String? paymentStatus, String method = 'qr'}) =>
    IncomingJobModel(
      jobId: 'food-1',
      pickupAddress: 'ร้าน',
      dropoffAddress: 'บ้าน',
      pickupLat: 13.7,
      pickupLng: 100.5,
      dropoffLat: 13.8,
      dropoffLng: 100.6,
      netIncome: 120,
      paymentMethod: method,
      paymentStatus: paymentStatus,
    );

Future<void> _open(WidgetTester tester, Widget screen, IncomingJobModel? job) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [incomingJobControllerProvider.overrideWith(() => _Jobs(job))],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
}

void main() {
  // A food order a promo made ฿0 is paid as placed (BE v1.6.13), as is one
  // paid by QR/card. Food pushes /payment with no amount, and the screen used
  // to fall back to the fare: "เก็บเงินสด ฿120" for an order nobody owes.
  testWidgets('a paid food order has nothing to collect', (tester) async {
    await _open(
      tester,
      const PaymentScreen(service: ReviewService.food),
      _foodJob(paymentStatus: 'PAID'),
    );

    expect(find.text('ลูกค้าชำระแล้ว · ไม่ต้องเก็บเงินสด'), findsOneWidget);
    expect(find.text('เลื่อนเพื่อจบงาน'), findsOneWidget);
    expect(find.text('เลื่อนเมื่อรับเงินสดแล้ว'), findsNothing);
  });

  testWidgets('an unpaid cash food order still collects the fare', (tester) async {
    await _open(
      tester,
      const PaymentScreen(service: ReviewService.food),
      _foodJob(method: 'cash'),
    );

    expect(find.text('เก็บเงินสด'), findsOneWidget);
    expect(find.text('เลื่อนเมื่อรับเงินสดแล้ว'), findsOneWidget);
  });

  // A parcel whose fee a promo covered (amount_due 0) but with goods value to
  // take at the door: COD in cash — never a ฿0 QR the backend can't mint.
  testWidgets('a ฿0 parcel fee with COD collects the COD in cash, no QR', (tester) async {
    await _open(
      tester,
      const PaymentScreen(
        service: ReviewService.messenger,
        amount: 0,
        codAmount: 350,
        methodLabel: 'promptpay',
        orderId: 'parcel-1',
        gateCompletion: true,
      ),
      null,
    );

    expect(find.text('เก็บเงินสด'), findsOneWidget);
    expect(find.text('เลื่อนเมื่อรับเงินสดแล้ว'), findsOneWidget);
  });
}
