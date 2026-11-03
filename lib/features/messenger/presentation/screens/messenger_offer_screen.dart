import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/services/directions_service.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/map_marker_providers.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_offer.dart';
import 'package:massdrive/features/messenger/presentation/controllers/messenger_controller.dart';
import 'package:massdrive/features/setting/presentation/controllers/auto_accept_controller.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/incoming_job/domain/models/offer_headline.dart';
import 'package:massdrive/features/job_live/presentation/widgets/ride_flow_widgets.dart';
import 'package:massdrive/features/messenger/domain/parcel_payment_label.dart';

/// Incoming messenger offer — map with pickup/dropoff + an accept/reject sheet
/// on a 16s window (SCRUM-41 §6). Shares the ride offer's look and flow
/// (net income, timeline, auto-accept countdown, cancel/accept pills).
class MessengerOfferScreen extends ConsumerWidget {
  const MessengerOfferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = ref.watch(messengerControllerProvider).currentOffer;

    if (offer == null) {
      return const Scaffold(
        backgroundColor: AppColors.semanticGrayNeutralFgWhite,
        body: Center(child: MassLoadingM(size: 72)),
      );
    }

    final pickup = LatLng(offer.pickupLat, offer.pickupLng);
    final dropoff = LatLng(offer.dropoffLat, offer.dropoffLng);
    // Real road route from the BE-supplied encoded polyline (dev15); straight
    // dashed line only as the fallback when it's absent.
    final encoded = offer.encodedPolyline;
    final routePts = (encoded != null && encoded.isNotEmpty)
        ? DirectionsService().decode(encoded)
        : const <LatLng>[];
    final hasRoute = routePts.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgWhite,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: pickup, zoom: 14),
            markers: {
              // Same custom pins as the ride/live flow: green = pickup,
              // red = dropoff (fall back to the hue marker until the bitmap
              // finishes rasterizing).
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickup,
                icon: ref.watch(pickupMarkerProvider).value ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
              ),
              Marker(
                markerId: const MarkerId('dropoff'),
                position: dropoff,
                icon: ref.watch(dropoffMarkerProvider).value ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    ),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: hasRoute ? routePts : [pickup, dropoff],
                color: AppColors.semanticPrimaryBgHigh,
                width: hasRoute ? 5 : 4,
                patterns: hasRoute
                    ? const []
                    : [PatternItem.dash(20), PatternItem.gap(10)],
              ),
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: MessengerOfferSheet(offer: offer),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet mirroring the ride offer modal: it owns the accept-window
/// countdown and, when the window closes, auto-accepts or auto-cancels per the
/// driver's preference — the same flow as [IncomingJobModal].
class MessengerOfferSheet extends ConsumerStatefulWidget {
  final MessengerOffer offer;

  const MessengerOfferSheet({required this.offer});

  @override
  ConsumerState<MessengerOfferSheet> createState() =>
      _MessengerOfferSheetState();
}

class _MessengerOfferSheetState extends ConsumerState<MessengerOfferSheet> {
  /// Messenger accept window — 16s, matching ride/food.
  static const int _totalSeconds = 16;

  Timer? _timer;
  int _remaining = _totalSeconds;

  /// Guards against firing accept/decline twice (tap racing the timeout).
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        // Window elapsed. Auto-accept only if the driver opted in; otherwise
        // the offer auto-cancels. (The controller keeps its own timeout as a
        // background safety net for offers with no visible screen.)
        if (ref.read(autoAcceptProvider)) {
          _accept();
        } else {
          _decline();
        }
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _accept() {
    if (_resolved) return;
    _resolved = true;
    _timer?.cancel();
    ref.read(messengerControllerProvider.notifier).acceptOffer();
  }

  void _decline() {
    if (_resolved) return;
    _resolved = true;
    _timer?.cancel();
    ref.read(messengerControllerProvider.notifier).rejectOffer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final p = context.palette;
    final card = RideCardColors.of(context);
    // รายได้สุทธิ from driver_earnings (BE v1.6.16); without it the fee is
    // labelled as the delivery fee, never as the driver's income (BE #191).
    final earnings = offer.driverEarnings;
    final headline = offerHeadline(
      fare: offer.fare,
      driverNet: earnings?.driverNet,
      delivery: true,
    );
    final autoAccept = ref.watch(autoAcceptProvider);
    final isSubmitting = ref.watch(
      messengerControllerProvider.select((s) => s.isSubmitting),
    );
    final km = '${offer.distanceKm.toStringAsFixed(1)} กม.';

    // The ride offer's card (IncomingJobModal): tag + payment · km on the
    // left, the money on the right, the pickup → dropoff timeline, the slide.
    return Container(
      decoration: BoxDecoration(
        color: card.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Padding(
        // Bottom inset from viewPadding, not SafeArea: SafeArea reads
        // MediaQuery.padding, which an ancestor can consume to 0 — leaving
        // the accept slide under the system nav/gesture bar.
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          12 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RideTag(
                        text: offer.packageSizeTier.isEmpty
                            ? 'ส่งพัสดุ'
                            : 'ส่งพัสดุ · ขนาด ${offer.packageSizeTier}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          parcelPaymentLabel(
                            offer.paymentMethod,
                            recipientPays: offer.isRecipientPays,
                          ),
                          km,
                        ].where((t) => t.isNotEmpty).join(' · '),
                        style: AppTypography.caption5.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                RideOfferMoney(
                  label: headline.label,
                  amount: headline.amount,
                  note: earnings?.commissionLine,
                ),
              ],
            ),
            Divider(height: 20, color: card.line),
            RideStopsTimeline(
              stops: [
                RideStop(
                  address: offer.pickupAddress ?? 'จุดรับพัสดุ',
                  sub: 'รับพัสดุ',
                  isPickup: true,
                  state: RideStopState.current,
                ),
                RideStop(
                  address: offer.dropoffAddress ?? 'จุดส่งพัสดุ',
                  sub: 'ส่งพัสดุ · $km',
                  isPickup: false,
                  state: RideStopState.current,
                ),
              ],
            ),
            // Goods value taken at the door, on top of the fee.
            if (offer.isCod && offer.codAmount > 0) ...[
              const SizedBox(height: 8),
              PriorCancelFeeNote(
                text: 'เก็บเงินค่าสินค้าปลายทาง ${formatBaht(offer.codAmount)}',
              ),
            ],
            const SizedBox(height: 6),
            RideOfferFooter(
              remaining: _remaining,
              total: _totalSeconds,
              autoAccept: autoAccept,
              accepting: isSubmitting,
              onAccept: _accept,
              onDecline: _decline,
            ),
          ],
        ),
      ),
    );
  }
}
