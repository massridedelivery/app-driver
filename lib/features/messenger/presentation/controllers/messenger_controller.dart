import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_offer.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';
import 'package:massdrive/features/messenger/domain/repositories/messenger_repository.dart';
import 'package:massdrive/features/messenger/presentation/states/messenger_state.dart';
import 'package:massdrive/router/app_routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messenger_controller.g.dart';

/// Drives the messenger offer + active-delivery lifecycle (SCRUM-41 §6/§7).
@Riverpod(keepAlive: true)
class MessengerController extends _$MessengerController {
  static const _offerWindow = Duration(seconds: 60);

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
          receiveOffer(MessengerOffer.fromJson(orderJson));
        }
      } else if (msg.type == 'messenger_cancelled') {
        final orderId = msg.raw['order_id'] ?? msg.data?['order_id'];
        if (state.activeOrder?.id == orderId) {
          state = state.copyWith(activeOrder: null);
          AppRouter.router.go('/home');
        }
      }
    });

    ref.onDispose(() {
      _socketSub?.cancel();
      _offerTimeout?.cancel();
    });

    return const MessengerState();
  }

  /// Show an incoming offer and start the 60s accept window.
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
        dismissOffer();
      }
    });
  }

  Future<void> acceptOffer() async {
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
    }
  }

  Future<void> pickedUp() async {
    if (await _runAction((id) => _repo.pickedUpOrder(id))) {
      await _refreshActive();
    }
  }

  Future<void> delivered() async {
    if (await _runAction((id) => _repo.deliveredOrder(id))) {
      state = state.copyWith(activeOrder: null);
      AppRouter.router.go('/payment');
    }
  }

  Future<bool> _runAction(Future<void> Function(String id) call) async {
    final order = state.activeOrder;
    if (order == null) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: '');
    try {
      await call(order.id);
      return true;
    } catch (e) {
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
