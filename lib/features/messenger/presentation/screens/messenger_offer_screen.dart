import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_offer.dart';
import 'package:massdrive/features/messenger/presentation/controllers/messenger_controller.dart';

/// Incoming messenger offer — map with pickup/dropoff + an accept/reject sheet
/// on a 60s window (SCRUM-41 §6).
class MessengerOfferScreen extends ConsumerStatefulWidget {
  const MessengerOfferScreen({super.key});

  @override
  ConsumerState<MessengerOfferScreen> createState() =>
      _MessengerOfferScreenState();
}

class _MessengerOfferScreenState extends ConsumerState<MessengerOfferScreen> {
  static const _window = 60;
  Timer? _ticker;
  int _secondsLeft = _window;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, _window));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offer = ref.watch(messengerControllerProvider).currentOffer;

    if (offer == null) {
      return const Scaffold(
        backgroundColor: AppColors.semanticGrayNeutralFgWhite,
        body: Center(child: CircularProgressIndicator()),
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
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickup,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
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
                color: AppColors.foundationOrange600,
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
            child: _OfferSheet(offer: offer, secondsLeft: _secondsLeft),
          ),
        ],
      ),
    );
  }
}

class _OfferSheet extends ConsumerWidget {
  final MessengerOffer offer;
  final int secondsLeft;

  const _OfferSheet({required this.offer, required this.secondsLeft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messengerControllerProvider);
    final controller = ref.read(messengerControllerProvider.notifier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.semanticGrayNeutralFgMidOnBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'งานส่งพัสดุใหม่',
                style: AppTypography.heading4.copyWith(
                  color: AppColors.foundationOrange500,
                ),
              ),
              Text(
                '$secondsLeft วิ',
                style: AppTypography.heading5.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip('ขนาด ${offer.packageSizeTier}'),
              const SizedBox(width: 8),
              _chip('${offer.distanceKm.toStringAsFixed(1)} กม.'),
              const SizedBox(width: 8),
              _chip(offer.isCod ? 'COD ฿${offer.codAmount.toInt()}' : 'เงินสด'),
            ],
          ),
          const SizedBox(height: 16),
          _addressRow(Icons.circle, 'จุดรับ', offer.pickupAddress ?? '-',
              AppColors.foundationOrange500),
          const SizedBox(height: 8),
          _addressRow(Icons.location_on, 'จุดส่ง', offer.dropoffAddress ?? '-',
              AppColors.semanticErrorBgHigh),
          const SizedBox(height: 16),
          Text(
            '฿${offer.fare.toStringAsFixed(0)}',
            style: AppTypography.heading2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      state.isSubmitting ? null : () => controller.rejectOffer(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('ปฏิเสธ',
                      style: AppTypography.heading5.copyWith(color: Colors.white70)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed:
                      state.isSubmitting ? null : () => controller.acceptOffer(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.semanticSuccessBgHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('รับงาน',
                          style: AppTypography.heading5
                              .copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.foundationAlphaWhite100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: AppTypography.caption4.copyWith(color: Colors.white)),
      );

  Widget _addressRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.caption5.copyWith(color: Colors.white54)),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption3.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
