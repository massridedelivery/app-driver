import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/services/job_cancellation.dart';
import 'package:massdrive/features/food_live/domain/food_order.dart';
import 'package:massdrive/features/food_live/presentation/screens/food_live_screen.dart';
import 'package:massdrive/features/incoming_job/domain/accept_outcome.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';

/// Backend v1.6.26: accepting jobs, food WS frames, the food order held from
/// the restaurant's accept on, scheduled ride offers.

DioException _err(int code, Object? body) => DioException(
  requestOptions: RequestOptions(path: '/api/food/driver/orders/O/accept'),
  response: Response(
    requestOptions: RequestOptions(path: ''),
    statusCode: code,
    data: body,
  ),
);

/// `food_delivery_offer`'s `order` (FoodOfferWSResponse).
const _offer = {
  'id': 'O1',
  'restaurant_id': 'R1',
  'restaurant_name': 'ข้าวมันไก่ป้าศรี',
  'restaurant_address': 'ซอยอารีย์ 1',
  'restaurant_lat': 13.78,
  'restaurant_lng': 100.54,
  'delivery_fee': 35,
  'customer_distance_km': 1.2,
  'fulfillment_distance_km': 3.4,
  'delivery_lat': 13.75,
  'delivery_lng': 100.5,
  'subtotal': 120,
  'order_items': [
    {'name': 'ข้าวมันไก่', 'quantity': 2, 'unit_price': 60, 'subtotal': 120},
  ],
};

/// One order from GET /api/food/driver/orders/active (foodorder.Order).
Map<String, dynamic> _held(String status) => {
  'id': 'O1',
  'customer_id': 'C1',
  'customer_name': 'คุณเอ',
  'restaurant_id': 'R1',
  'restaurant_name': 'ข้าวมันไก่ป้าศรี',
  'restaurant_address': 'ซอยอารีย์ 1',
  'restaurant_lat': 13.78,
  'restaurant_lng': 100.54,
  'driver_id': 'D1',
  'status': status,
  'delivery_lat': 13.75,
  'delivery_lng': 100.5,
  'delivery_address': '99/1 ถนนพหลโยธิน',
  'food_total': 120,
  'delivery_fee': 30,
  'delivery_fee_waived': 10,
  'total_amount': 150,
  'payment_method': 'CASH',
  'items': [
    {'name': 'ข้าวมันไก่', 'quantity': 2, 'unit_price': 60, 'subtotal': 120},
  ],
};

void main() {
  group('accepting', () {
    test('food 409 "no longer available" closes the offer with its text', () {
      final e = _err(409, {'message': 'this order is no longer available'});
      expect(foodAcceptOutcomeOf(e), AcceptOutcome.unavailable);
      expect(
        acceptFailureMessage(AcceptOutcome.unavailable, e),
        'this order is no longer available',
      );
    });

    test('409 taken and 403 not offered keep closing the offer', () {
      expect(
        foodAcceptOutcomeOf(
          _err(409, {'message': 'delivery already taken by another driver'}),
        ),
        AcceptOutcome.unavailable,
      );
      final notOffered = _err(403, {
        'error': 'this job was not offered to you',
      });
      expect(isOfferGoneError(notOffered), isTrue);
      expect(foodAcceptOutcomeOf(notOffered), AcceptOutcome.unavailable);
    });

    test('the cash-job 403 still points to "เติมเครดิต"', () {
      expect(
        foodAcceptOutcomeOf(_err(403, {'code': 'CASH_JOBS_BLOCKED'})),
        AcceptOutcome.cashBlocked,
      );
    });

    test('a timeout or 5xx lets the driver try again', () {
      expect(foodAcceptOutcomeOf(_err(503, {})), AcceptOutcome.failed);
      expect(foodAcceptOutcomeOf(Exception('timeout')), AcceptOutcome.failed);
      expect(
        acceptOutcomeMessage(AcceptOutcome.unavailable),
        'งานนี้ไม่สามารถรับได้แล้ว',
      );
    });
  });

  group('food order JSON', () {
    test('the offer reads with the restaurant as pickup', () {
      final job = IncomingJobModel.fromJson(foodOrderAsJobJson(_offer));
      expect(job.jobId, 'O1');
      expect(job.isFood, isTrue);
      expect(job.pickupLat, 13.78);
      expect(job.dropoffLng, 100.5);
      expect(job.pickupAddress, 'ซอยอารีย์ 1');
      expect(job.restaurantName, 'ข้าวมันไก่ป้าศรี');
      expect(job.netIncome, 35);
      expect(job.dropoffDistanceKm, 3.4);
      expect(job.orderItems.single['name'], 'ข้าวมันไก่');
    });

    test('ride-shaped keys, when sent, win', () {
      final json = foodOrderAsJobJson({
        ..._offer,
        'pickup_lat': 1.0,
        'fare': 50,
      });
      expect(json['pickup_lat'], 1.0);
      expect(json['fare'], 50);
    });

    test('the active order: {batch, orders} with its status', () {
      final held = activeFoodOrderFrom({
        'batch': null,
        'orders': [_held('PREPARING')],
      })!;
      expect(held.status, 'PREPARING');
      final job = IncomingJobModel.fromJson(held.json);
      expect(job.dropoffAddress, '99/1 ถนนพหลโยธิน');
      expect(job.passengerName, 'คุณเอ');
      expect(job.paymentMethod, 'CASH');
      // Delivery fee plus the part waived for the customer.
      expect(job.netIncome, 40);
      expect(job.subtotal, 120);
      expect(job.orderItems, hasLength(1));

      expect(activeFoodOrderFrom({'orders': []}), isNull);
      expect(activeFoodOrderFrom(null), isNull);
      expect(
        activeFoodOrderFrom([_held('DRIVER_ASSIGNED')])?.status,
        'DRIVER_ASSIGNED',
      );
    });
  });

  group('order held while the restaurant prepares', () {
    test(
      'RESTAURANT_ACCEPTED / PREPARING → heading to the restaurant, preparing',
      () {
        for (final s in ['RESTAURANT_ACCEPTED', 'PREPARING']) {
          expect(isRestaurantPreparing(s), isTrue, reason: s);
          expect(foodLiveStateFor(s), FoodLiveState.headingToRestaurant);
        }
        for (final s in ['READY_FOR_PICKUP', 'DRIVER_ASSIGNED', null]) {
          expect(isRestaurantPreparing(s), isFalse, reason: '$s');
          expect(foodLiveStateFor(s), FoodLiveState.headingToRestaurant);
        }
        expect(foodLiveStateFor('DRIVER_PICKED_UP'), FoodLiveState.delivering);
      },
    );

    testWidgets('the note reads "ร้านกำลังเตรียมอาหาร"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FoodPreparingNote())),
      );
      expect(find.text('ร้านกำลังเตรียมอาหาร'), findsOneWidget);
    });
  });

  group('food WS frames', () {
    Map<String, dynamic> frame(String type, String status) => {
      'type': type,
      'order_id': 'O1',
      'status': status,
      'order': {'id': 'O1', 'status': status},
    };

    test('driver_assigned names the order to open', () {
      final f = foodFrameOf(
        'driver_assigned',
        frame('driver_assigned', 'DRIVER_ASSIGNED'),
        null,
      )!;
      expect(f.orderId, 'O1');
      expect(f.status, 'DRIVER_ASSIGNED');
      expect(f.order?['id'], 'O1');
      expect(isFoodOrderEndedFrame(f.type, f.status), isFalse);
      // Not a cancellation.
      expect(
        jobCancelFromSocket(
          'driver_assigned',
          frame('driver_assigned', 'DRIVER_ASSIGNED'),
          null,
        ),
        isNull,
      );
    });

    test('order_cancelled closes the order, whatever the end', () {
      final cancelled = jobCancelFromSocket(
        'order_cancelled',
        frame('order_cancelled', 'CANCELLED'),
        null,
      )!;
      expect(cancelled.jobId, 'O1');
      expect(cancelled.message, 'ออเดอร์นี้ถูกยกเลิกแล้ว');

      final failed = jobCancelFromSocket(
        'order_cancelled',
        frame('order_cancelled', 'FAILED_DELIVERY'),
        null,
      )!;
      expect(failed.message, 'ออเดอร์นี้ปิดแล้ว (ส่งไม่สำเร็จ)');
    });

    test('the back office ending it, or not', () {
      expect(
        jobCancelFromSocket(
          'externally_dispatched',
          frame('externally_dispatched', 'EXTERNALLY_DISPATCHED'),
          null,
        )?.message,
        'ออเดอร์นี้ส่งต่อให้ผู้ส่งรายอื่นแล้ว',
      );
      expect(
        jobCancelFromSocket(
          'status_updated',
          frame('status_updated', 'CANCELLED'),
          null,
        ),
        isNotNull,
      );
      expect(
        jobCancelFromSocket(
          'status_updated',
          frame('status_updated', 'READY_FOR_PICKUP'),
          null,
        ),
        isNull,
      );
      expect(
        jobCancelFromSocket(
          'order_ready',
          frame('order_ready', 'READY_FOR_PICKUP'),
          null,
        ),
        isNull,
      );
    });

    test('the ride job_status cancel is unchanged', () {
      final e = jobCancelFromSocket('job_status', {
        'job_id': 'J1',
        'status': 'CANCELLED',
        'cancelled_by': 'customer',
      }, null)!;
      expect(e.jobId, 'J1');
      expect(e.cancelledBy, 'customer');
      expect(e.message, isNull);
    });
  });

  group('scheduled ride offer', () {
    Map<String, dynamic> ride({bool scheduled = true}) => {
      'id': 'J9',
      'pickup_address': 'สยาม',
      'dropoff_address': 'อโศก',
      'pickup_lat': 13.74,
      'pickup_lng': 100.53,
      'dropoff_lat': 13.73,
      'dropoff_lng': 100.56,
      'fare': 120,
      'payment_method': 'CASH',
      'is_scheduled': scheduled,
      if (scheduled) 'scheduled_at': '2026-11-12T07:30:00Z',
    };

    test(
      'scheduled_job_offer\'s job reads like a ride offer, with its time',
      () {
        final job = IncomingJobModel.fromJson(ride());
        expect(job.jobId, 'J9');
        expect(job.isScheduled, isTrue);
        final at = DateTime.parse('2026-11-12T07:30:00Z').toLocal();
        String two(int n) => n.toString().padLeft(2, '0');
        expect(
          job.scheduledPickupLine,
          'งานล่วงหน้า · รับ ${two(at.hour)}:${two(at.minute)} น. '
          '${at.day} พ.ย. 2569',
        );
      },
    );

    test('a ride now has no pickup line', () {
      expect(
        IncomingJobModel.fromJson(ride(scheduled: false)).scheduledPickupLine,
        isNull,
      );
    });
  });
}
