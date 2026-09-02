import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:massdrive/core/services/push_notification_service.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/presentation/screens/home_screen.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_offer.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';
import 'package:massdrive/features/messenger/domain/repositories/messenger_repository.dart';
import 'package:massdrive/features/messenger/presentation/states/messenger_state.dart';
import 'package:massdrive/features/review/data/customer_review_api.dart';
import 'package:massdrive/features/setting/presentation/controllers/auto_accept_controller.dart';
import 'package:massdrive/router/app_routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messenger_controller.g.dart';

/// Drives the messenger offer + active-delivery lifecycle (SCRUM-41 §6/§7).
@Riverpod(keepAlive: true)
class MessengerController extends _$MessengerController {
  // 16s accept window, matching ride/food (the visible countdown in the offer
  // sheet). Background safety net for offers whose sheet never rendered.
  static const _offerWindow = Duration(seconds: 16);

  StreamSubscription? _socketSub;
  Timer? _offerTimeout;

  MessengerRepository get _repo => getIt<MessengerRepository>();

  @override
  MessengerState build() {
    final socket = ref.watch(socketServiceProvider);

    _socketSub?.cancel();
    _socketSub = socket.messages.listen((msg) {
      if (msg.type == 'messenger_offer') {
        final orderJson = msg.raw['order'] ?? msg.data?['order'];
        if (orderJson is Map<String, dynamic>) {
          final offer = MessengerOffer.fromJson(orderJson);
          receiveOffer(offer);
          // WS carries no sound — ring the loud alert locally (de-duped vs FCM).
          PushNotificationService.instance.alertJobOffer(key: offer.id);
        }
      } else if (msg.type == 'messenger_cancelled') {
        final orderId = msg.raw['order_id'] ?? msg.data?['order_id'];
        if (state.activeOrder?.id == orderId) {
          state = state.copyWith(activeOrder: null);
          AppRouter.router.go('/home');
        }
      } else if (msg.type == 'payment_paid') {
        // Customer scanned the rider's QR and paid — re-fetch the authoritative
        // order (now PAID) so the live screen hides the QR button and shows the
        // paid state. (MessengerOrder has no client-side copyWith.)
        final data = msg.data ?? msg.raw;
        final oid = data['order_id']?.toString();
        final o = state.activeOrder;
        if (o != null &&
            (oid == null || oid == o.id) &&
            (data['status']?.toString().toUpperCase() == 'PAID')) {
          _refreshActive();
        }
      } else if (msg.type == 'messenger_order_updated' ||
          msg.type == 'messenger_order_update' ||
          msg.type == 'messenger_updated') {
        // Order fields changed server-side — notably the customer switching
        // "จ่ายเงินสดแทน" (payment_method → CASH) or a payment landing. Adopt
        // the fresh order so the UI (QR button / "เก็บเงินสด") reacts live.
        final orderJson = msg.raw['order'] ?? msg.data?['order'];
        final current = state.activeOrder;
        if (orderJson is Map<String, dynamic> && current != null) {
          try {
            final updated = MessengerOrder.fromJson(orderJson);
            if (updated.id == current.id) {
              state = state.copyWith(activeOrder: updated);
            }
          } catch (_) {}
        }
      }
    });

    ref.onDispose(() {
      _socketSub?.cancel();
      _offerTimeout?.cancel();
    });

    return const MessengerState();
  }

  /// Show an incoming offer and start the 16s accept window.
  void receiveOffer(MessengerOffer offer) {
    _offerTimeout?.cancel();
    state = state.copyWith(
      currentOffer: offer,
      isModalVisible: true,
      errorMessage: '',
    );
    AppRouter.router.go('/messenger-offer');
    _offerTimeout = Timer(_offerWindow, () {
      if (state.currentOffer?.id == offer.id && state.isModalVisible) {
        // Match the ride/food flow: when the window closes, honour the driver's
        // auto-accept preference. Safety net for an offer whose sheet never
        // rendered (e.g. arrived while backgrounded).
        if (ref.read(autoAcceptProvider)) {
          acceptOffer();
        } else {
          dismissOffer();
        }
      }
    });
  }

  Future<void> acceptOffer() async {
    // Stop the ~10s job-alert notification sound the moment the driver acts.
    PushNotificationService.instance.cancelJobAlerts();
    final offer = state.currentOffer;
    if (offer == null) return;
    _offerTimeout?.cancel();
    state = state.copyWith(isSubmitting: true, errorMessage: '');

    // 1. Accept.
    try {
      await _repo.acceptOrder(offer.id);
    } catch (e) {
      if (kDebugMode) debugPrint('MessengerController: accept failed → $e');
      // The driver may already have an active order (capacity = 1). Resume that
      // job instead of bouncing home — they must finish it before taking a new
      // one. Only a truly idle driver falls through to the error.
      final existing = await _safeGetActive();
      if (existing != null) {
        _goLive(existing);
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        isModalVisible: false,
        currentOffer: null,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      AppRouter.router.go('/home');
      return;
    }

    // 2. Accepted. Fetch full detail; if it lags/fails, fall back to the offer.
    final order = await _safeGetActive() ?? _orderFromOffer(offer);
    _goLive(order);
  }

  Future<MessengerOrder?> _safeGetActive() async {
    try {
      return await _repo.getActiveOrder();
    } catch (e) {
      if (kDebugMode) debugPrint('MessengerController: getActiveOrder failed → $e');
      return null;
    }
  }

  void _goLive(MessengerOrder order) {
    state = state.copyWith(
      activeOrder: order,
      currentOffer: null,
      isModalVisible: false,
      isSubmitting: false,
    );
    AppRouter.router.go('/messenger-live');
  }

  /// Minimal order built from the offer, used when the active-detail fetch is
  /// unavailable right after accept (offer carries no recipient PII).
  MessengerOrder _orderFromOffer(MessengerOffer o) => MessengerOrder(
        id: o.id,
        status: 'ACCEPTED',
        pickupLat: o.pickupLat,
        pickupLng: o.pickupLng,
        pickupAddress: o.pickupAddress,
        dropoffLat: o.dropoffLat,
        dropoffLng: o.dropoffLng,
        dropoffAddress: o.dropoffAddress,
        packageSizeTier: o.packageSizeTier,
        codAmount: o.codAmount,
        paymentMethod: o.paymentMethod,
        distanceKm: o.distanceKm,
        fare: o.fare,
      );

  Future<void> rejectOffer() async {
    final offer = state.currentOffer;
    _offerTimeout?.cancel();
    if (offer != null) {
      try {
        await _repo.rejectOrder(offer.id);
      } catch (e) {
        if (kDebugMode) debugPrint('MessengerController: reject error $e');
      }
    }
    state = state.copyWith(currentOffer: null, isModalVisible: false);
    AppRouter.router.go('/home');
  }

  void dismissOffer() {
    _offerTimeout?.cancel();
    state = state.copyWith(currentOffer: null, isModalVisible: false);
    AppRouter.router.go('/home');
  }

  /// Restore an in-progress order on resume (SCRUM-45).
  void setActiveOrder(MessengerOrder order) {
    state = state.copyWith(activeOrder: order, isModalVisible: false);
  }

  Future<void> arrived() async {
    if (await _runAction((id) => _repo.arrivedOrder(id))) {
      await _refreshActive();
      // Auto-present the QR the instant we arrive at pickup: if the sender owes
      // an unpaid PromptPay fee, jump straight to the collect screen instead of
      // making the driver tap "แสดง QR รับเงิน" first.
      final o = state.activeOrder;
      if (o != null &&
          o.paymentMethod.toUpperCase() == 'PROMPTPAY' &&
          !o.isFeePaid &&
          !o.isRecipientPays) {
        await collectFeeQr();
      }
    }
  }

  /// Show the QR (or cash) collection screen on demand — the rider taps
  /// "แสดง QR รับเงิน" to present the QR to the sender (at pickup) or the
  /// recipient (at drop-off). Reuses the /payment screen (QR intent, poll, WS
  /// payment_paid, EXPIRED → new QR, cash fallback). midTrip returns here.
  Future<void> collectFeeQr() async {
    final order = state.activeOrder;
    if (order == null) return;
    final paid = await AppRouter.router.push('/payment', extra: {
      'amount': order.feeDue,
      'method': order.paymentMethod,
      'payer': order.payer,
      'collectAt': order.collectAt,
      'paymentStatus': order.paymentStatus,
      'title': order.isRecipientPays ? 'ผู้รับ' : 'ผู้ส่ง',
      'orderId': order.id,
      'service': ReviewService.messenger,
      'midTrip': true,
    });
    if (paid == true) await _refreshActive();
  }

  Future<void> pickedUp() async {
    final order = state.activeOrder;
    if (order == null) return;

    // dev14: when the fee is collected at PICKUP (sender pays the driver) and
    // isn't already prepaid, collect it now — QR/cash on the driver app — before
    // marking the parcel picked up. midTrip returns to the live screen so the
    // trip continues (COD is separate and collected later at DELIVERY).
    if ((order.collectAt?.toUpperCase() == 'PICKUP') && !order.isFeePaid) {
      final paid = await AppRouter.router.push('/payment', extra: {
        'amount': order.feeDue,
        'method': order.paymentMethod,
        'payer': order.payer,
        'collectAt': order.collectAt,
        'paymentStatus': order.paymentStatus,
        'title': 'ผู้ส่ง',
        'orderId': order.id,
        'service': ReviewService.messenger,
        'midTrip': true,
      });
      // Driver backed out without collecting → don't advance the stage.
      if (paid != true) return;
    }

    if (await _runAction((id) => _repo.pickedUpOrder(id))) {
      await _refreshActive();
    }
  }

  Future<void> delivered() async {
    final order = state.activeOrder;
    if (order == null) return;

    // Collect ONCE, at the stage the order dictates. Only show the collect
    // screen at delivery when there's actually something to take at the door:
    //  • the delivery fee, when collectAt == DELIVERY and not already paid, OR
    //  • COD (goods value), which is always collected at delivery.
    // If the fee was already collected at PICKUP and there's no COD, don't
    // prompt the recipient — just mark delivered and finish.
    final feeAtDelivery =
        (order.collectAt?.toUpperCase() == 'DELIVERY') && !order.isFeePaid;
    final hasCod = order.codAmount > 0;

    if (!feeAtDelivery && !hasCod) {
      if (await _runAction((id) => _repo.deliveredOrder(id))) {
        state = state.copyWith(activeOrder: null);
        ref.read(socketServiceProvider).disconnect();
        ref.read(onlineStatusProvider.notifier).setStatus(true, force: true);
        AppRouter.router.go('/review-customer', extra: {
          'jobId': order.id,
          'service': ReviewService.messenger,
          'customerName': order.recipientName ?? 'ลูกค้า',
        });
      }
      return;
    }

    // Something to collect at the door → PaymentScreen collects (fee and/or COD)
    // then marks delivered and runs the review/home flow. Don't mark delivered
    // here — an unpaid QR delivery must not be closable.
    state = state.copyWith(activeOrder: null);
    AppRouter.router.go('/payment', extra: {
      // Delivery fee only (dev14 amount_due) — the COD goods value is a separate
      // debt shown on its own line, never folded into the fee.
      'amount': order.feeDue,
      'codAmount': order.codAmount,
      'method': order.paymentMethod,
      'payer': order.payer,
      'collectAt': order.collectAt,
      // Already settled (prepaid QR) → the screen skips fee collection.
      'paymentStatus': order.paymentStatus,
      'title': order.recipientName ?? 'ลูกค้า',
      'orderId': order.id,
      'service': ReviewService.messenger,
      'gateCompletion': true,
    });
  }

  Future<bool> _runAction(Future<void> Function(String id) call) async {
    final order = state.activeOrder;
    if (order == null) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: '');
    try {
      await call(order.id);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('MessengerController: action failed → $e');
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> _refreshActive() async {
    try {
      final order = await _repo.getActiveOrder();
      state = state.copyWith(activeOrder: order);
    } catch (e) {
      if (kDebugMode) debugPrint('MessengerController: refresh error $e');
    }
  }
}
