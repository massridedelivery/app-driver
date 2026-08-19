import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/common/widgets/job_offer_action_bar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_offer.dart';
import 'package:massdrive/features/messenger/presentation/controllers/messenger_controller.dart';
import 'package:massdrive/features/setting/presentation/controllers/auto_accept_controller.dart';

/// Incoming messenger offer — map with pickup/dropoff + an accept/reject sheet
/// on a 60s window (SCRUM-41 §6). Shares the ride offer's look and flow
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

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgWhite,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: pickup, zoom: 14),
            markers: {
              // Same pin convention as the ride flow (incoming_job_screen):
              // green = pickup, red = dropoff.
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickup,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              ),
              Marker(
                markerId: const MarkerId('dropoff'),
                position: dropoff,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: [pickup, dropoff],
                color: AppColors.semanticPrimaryBgHigh,
                width: 4,
                patterns: [PatternItem.dash(20), PatternItem.gap(10)],
              ),
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _OfferSheet(offer: offer),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet mirroring the ride offer modal: it owns the accept-window
/// countdown and, when the window closes, auto-accepts or auto-cancels per the
/// driver's preference — the same flow as [IncomingJobModal].
class _OfferSheet extends ConsumerStatefulWidget {
  final MessengerOffer offer;

  const _OfferSheet({required this.offer});

  @override
  ConsumerState<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends ConsumerState<_OfferSheet> {
  /// Messenger accept window (SCRUM-41 §6).
  static const int _totalSeconds = 60;

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
    final autoAccept = ref.watch(autoAcceptProvider);
    final isSubmitting = ref.watch(
      messengerControllerProvider.select((s) => s.isSubmitting),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.semanticGrayNeutralFgMidOnBlack,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.s4),
          topRight: Radius.circular(AppSpacing.s4),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          // Bottom inset from viewPadding, not SafeArea: SafeArea reads
          // MediaQuery.padding, which an ancestor can consume to 0 — leaving
          // the accept button under the system nav/gesture bar.
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s4 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Net income + payment method (mirrors the ride modal header).
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รายได้สุทธิ',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.semanticGrayNeutralFgWhite,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            offer.fare.toInt().toString(),
                            style: AppTypography.heading2.copyWith(
                              color: AppColors.semanticGrayNeutralFgWhite,
                              fontSize: 32,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            ' ฿',
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.semanticGrayNeutralFgWhite,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.semanticGrayNeutralFgWhite,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      offer.isCod ? 'COD' : 'เงินสด',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.semanticGrayNeutralFgHigh,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.s4),

              // Service type row (mirrors the ride modal).
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2,
                    color: AppColors.semanticGrayNeutralFgWhite,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ส่งพัสดุ',
                    style: AppTypography.heading5.copyWith(
                      color: AppColors.semanticGrayNeutralFgWhite,
                    ),
                  ),
                  if (offer.packageSizeTier.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '· ขนาด ${offer.packageSizeTier}',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.foundationAlphaWhite500,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: AppSpacing.s4),

              // Pickup → dropoff timeline (mirrors the ride modal).
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        _dot(AppColors.semanticSuccessBgHigh),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                3,
                                (index) => Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: Colors.white70,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _dot(AppColors.semanticSupportRedBgHigh),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _addressBlock(offer.pickupAddress ?? 'จุดรับพัสดุ', null),
                          const SizedBox(height: 24),
                          _addressBlock(
                            offer.dropoffAddress ?? 'จุดส่งพัสดุ',
                            '${offer.distanceKm.toStringAsFixed(1)} กม.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (offer.isCod && offer.codAmount > 0) ...[
                const SizedBox(height: AppSpacing.s3),
                Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      color: AppColors.foundationOrange500,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'เก็บเงินปลายทาง ฿${offer.codAmount.toInt()}',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.foundationOrange500,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.s4),

              // Shared accept/decline footer: same flow as the ride offer.
              JobOfferActionBar(
                remaining: _remaining,
                totalSeconds: _totalSeconds,
                autoAccept: autoAccept,
                isSubmitting: isSubmitting,
                onAccept: _accept,
                onDecline: _decline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );

  Widget _addressBlock(String title, String? distance) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.heading5.copyWith(
              color: AppColors.semanticGrayNeutralFgWhite,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (distance != null) ...[
          const SizedBox(width: 8),
          Text(
            distance,
            style: AppTypography.caption4.copyWith(
              color: AppColors.foundationAlphaWhite500,
            ),
          ),
        ],
      ],
    );
  }
}
