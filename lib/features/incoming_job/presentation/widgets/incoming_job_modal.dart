import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/common/widgets/job_offer_action_bar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/services/directions_service.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/setting/presentation/controllers/auto_accept_controller.dart';

class IncomingJobModal extends ConsumerStatefulWidget {
  final IncomingJobModel job;

  const IncomingJobModal({super.key, required this.job});

  @override
  ConsumerState<IncomingJobModal> createState() => _IncomingJobModalState();
}

class _IncomingJobModalState extends ConsumerState<IncomingJobModal> {
  Timer? _timer;

  /// Total window (seconds) the driver has to accept, from the offer.
  late final int _totalSeconds;

  /// Seconds left on the accept window; drives the button label + progress bar.
  late int _remaining;

  /// Guards against firing accept/decline twice (e.g. tap racing the timeout).
  bool _resolved = false;

  // Route preview map: pickup/drop-off pins + the driving route between them.
  GoogleMapController? _mapController;
  final _directions = DirectionsService();
  late final LatLng _pickup =
      LatLng(widget.job.pickupLat, widget.job.pickupLng);
  late final LatLng _dropoff =
      LatLng(widget.job.dropoffLat, widget.job.dropoffLng);
  // Start with a straight pickup→drop-off line; replaced by the real road
  // route once the Directions call returns.
  late List<LatLng> _routePoints = [_pickup, _dropoff];

  @override
  void initState() {
    super.initState();
    // Fixed 16s accept window (the backend sends no timeout_seconds, so this
    // is the app-side source of truth — same value across ride/food/messenger).
    _totalSeconds = widget.job.timeoutSeconds > 0
        ? widget.job.timeoutSeconds
        : 16;
    _remaining = _totalSeconds;
    _startCountdown();
    _loadRoute();
  }

  /// Fetch the real road-following route (Google Directions fallback — the
  /// offer payload has no encoded polyline yet, see SCRUM-83). On failure the
  /// straight line stays.
  Future<void> _loadRoute() async {
    final pts = await _directions.getRoutePolyline(
      origin: _pickup,
      destination: _dropoff,
    );
    if (!mounted || pts.isEmpty) return;
    setState(() => _routePoints = pts);
    _fitBounds();
  }

  void _fitBounds() {
    final c = _mapController;
    if (c == null) return;
    final lats = _routePoints.map((p) => p.latitude);
    final lngs = _routePoints.map((p) => p.longitude);
    final swLat = lats.reduce(math.min), neLat = lats.reduce(math.max);
    final swLng = lngs.reduce(math.min), neLng = lngs.reduce(math.max);
    // Degenerate span (pickup ≈ drop-off) — just centre on the point.
    if ((neLat - swLat) < 1e-5 && (neLng - swLng) < 1e-5) {
      c.moveCamera(CameraUpdate.newLatLngZoom(_pickup, 15));
      return;
    }
    c.moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(swLat, swLng),
          northeast: LatLng(neLat, neLng),
        ),
        36,
      ),
    );
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        // Window elapsed. Auto-accept only if the driver opted in; otherwise
        // the offer auto-cancels.
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
    ref.read(incomingJobControllerProvider.notifier).acceptJob();
  }

  void _decline() {
    if (_resolved) return;
    _resolved = true;
    _timer?.cancel();
    ref.read(incomingJobControllerProvider.notifier).declineJob();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Compact, non-interactive route preview: pickup (green) → drop-off (red)
  /// with the driving route drawn between them.
  Widget _buildRoutePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 150,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              (_pickup.latitude + _dropoff.latitude) / 2,
              (_pickup.longitude + _dropoff.longitude) / 2,
            ),
            zoom: 12,
          ),
          onMapCreated: (c) {
            _mapController = c;
            // Wait a frame so the map has a size before fitting the bounds.
            WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
          },
          markers: {
            Marker(
              markerId: const MarkerId('pickup'),
              position: _pickup,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
            Marker(
              markerId: const MarkerId('dropoff'),
              position: _dropoff,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          },
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              points: _routePoints,
              color: AppColors.foundationOrange600,
              width: 5,
            ),
          },
          // A glanceable preview inside a modal — no gestures/controls.
          zoomGesturesEnabled: false,
          scrollGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final autoAccept = ref.watch(autoAcceptProvider);
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
              // Top Section: Income and Points
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              'รายได้สุทธิ',
                              style: AppTypography.body1.copyWith(
                                color: AppColors.semanticGrayNeutralFgWhite,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s3),
                            Row(
                              children: [
                                Text(
                                  job.netIncome.toInt().toString(),
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
                            job.paymentMethod,
                            style: AppTypography.body2.copyWith(
                              color: AppColors.semanticGrayNeutralFgHigh,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.s4),

              // Service Type
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2,
                    color: AppColors.semanticGrayNeutralFgWhite,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    job.serviceType,
                    style: AppTypography.heading5.copyWith(
                      color: AppColors.semanticGrayNeutralFgWhite,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.s4),

              // Route preview: pickup → drop-off on a compact map.
              _buildRoutePreview(),
              const SizedBox(height: AppSpacing.s4),

              // Timeline
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Timeline Dots & Line
                    Column(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.semanticSuccessBgHigh,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
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
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.semanticSupportRedBgHigh,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Addresses
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAddressBlock(
                            job.pickupAddress,
                            job.pickupAddressDetail,
                            '${job.pickupDistanceKm} KM',
                          ),
                          const SizedBox(height: 24),
                          _buildAddressBlock(
                            job.dropoffAddress,
                            job.dropoffAddressDetail,
                            '${(job.distanceKm ?? 0.0) > 0 ? job.distanceKm : job.dropoffDistanceKm} KM',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.s4),

              // Shared accept/decline footer: auto-accept caption, progress bar
              // and the large cancel/accept pills.
              JobOfferActionBar(
                remaining: _remaining,
                totalSeconds: _totalSeconds,
                autoAccept: autoAccept,
                onAccept: _accept,
                onDecline: _decline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressBlock(String title, String detail, String distance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            SizedBox(width: 8),
            Text(
              distance,
              style: AppTypography.caption4.copyWith(
                color: AppColors.foundationAlphaWhite500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
