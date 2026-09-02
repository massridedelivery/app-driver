import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/utils/map_marker_providers.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/services/directions_service.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/incoming_job/presentation/widgets/incoming_food_modal.dart';
import 'package:massdrive/features/incoming_job/presentation/widgets/incoming_job_modal.dart';

class IncomingJobScreen extends ConsumerStatefulWidget {
  const IncomingJobScreen({super.key});

  @override
  ConsumerState<IncomingJobScreen> createState() => _IncomingJobScreenState();
}

class _IncomingJobScreenState extends ConsumerState<IncomingJobScreen> {
  GoogleMapController? _mapController;
  final DirectionsService _directions = DirectionsService();

  /// The road-following route drawn on the background map. Empty until loaded —
  /// the map then falls back to a straight pickup→drop-off line.
  List<LatLng> _routePoints = const [];

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  /// Prefer the encoded polyline the BE ships in the offer (SCRUM-66) — free,
  /// no network call; fall back to the Google Directions call, then to a
  /// straight line. Drawn on the full-screen map behind the offer card.
  Future<void> _loadRoute() async {
    final job = ref.read(incomingJobControllerProvider).currentJob;
    if (job == null) return;
    final pickup = LatLng(job.pickupLat, job.pickupLng);
    final dropoff = LatLng(job.dropoffLat, job.dropoffLng);

    List<LatLng> pts;
    final encoded = job.encodedPolyline;
    if (encoded != null && encoded.isNotEmpty) {
      pts = _directions.decode(encoded);
    } else {
      pts = await _directions.getRoutePolyline(
        origin: pickup,
        destination: dropoff,
      );
    }
    if (!mounted || pts.isEmpty) return;
    setState(() => _routePoints = pts);
    _fitToRoute();
  }

  void _fitToRoute() {
    final c = _mapController;
    if (c == null || _routePoints.isEmpty) return;
    final lats = _routePoints.map((p) => p.latitude);
    final lngs = _routePoints.map((p) => p.longitude);
    c.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(lats.reduce(min), lngs.reduce(min)),
          northeast: LatLng(lats.reduce(max), lngs.reduce(max)),
        ),
        80,
      ),
    );
  }

  @override
  void dispose() {
    // Release the native map controller so it (and its camera-animation
    // closure) can be garbage-collected instead of leaking on every job.
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incomingJobState = ref.watch(incomingJobControllerProvider);
    final job = incomingJobState.currentJob;

    if (job == null) {
      // No job in memory — e.g. the app was route-restored here after a kill,
      // when the offer state is gone. Don't strand the driver on a spinner:
      // bounce to home, where the active-job probe recovers any real job.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(incomingJobControllerProvider).currentJob != null) return;
        context.go(AppRoutes.homeNamedPage);
      });
      return const Scaffold(
        backgroundColor: AppColors.semanticGrayNeutralFgWhite,
        body: Center(child: MassLoadingM(size: 72)),
      );
    }

    // Custom pins (same as the live screen) — fall back to the default hue
    // marker until the bitmap finishes rasterizing.
    final pickupIcon = ref.watch(pickupMarkerProvider).value ??
        BitmapDescriptor.defaultMarkerWithHue(
          job.isFood ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen,
        );
    final dropoffIcon = ref.watch(dropoffMarkerProvider).value ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(job.pickupLat, job.pickupLng),
        icon: pickupIcon,
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(job.dropoffLat, job.dropoffLng),
        icon: dropoffIcon,
      ),
    };

    // Real road-following route once loaded; a straight line as the fallback.
    final bool hasRoute = _routePoints.isNotEmpty;
    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: hasRoute
            ? _routePoints
            : [
                LatLng(job.pickupLat, job.pickupLng),
                LatLng(job.dropoffLat, job.dropoffLng),
              ],
        color: job.isFood
            ? AppColors.foundationOrange600
            : AppColors.semanticPrimaryBgHigh,
        width: 5,
        // Dashed only for the straight-line fallback; solid for the real route.
        patterns: hasRoute
            ? const []
            : [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgWhite,
      body: Stack(
        children: [
          // Build the standalone map
          SizedBox.expand(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                final bounds = LatLngBounds(
                  southwest: LatLng(
                    min(job.pickupLat, job.dropoffLat),
                    min(job.pickupLng, job.dropoffLng),
                  ),
                  northeast: LatLng(
                    max(job.pickupLat, job.dropoffLat),
                    max(job.pickupLng, job.dropoffLng),
                  ),
                );
                // Delay slightly to ensure map is fully sized before projecting bounds
                Future.delayed(const Duration(milliseconds: 300), () {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 80),
                  );
                });
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(job.pickupLat, job.pickupLng),
                zoom: 14,
              ),
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),

          // Show the appropriate modal based on job type
          Align(
            alignment: Alignment.bottomCenter,
            child: job.isFood
                ? IncomingFoodModal(job: job)
                : IncomingJobModal(job: job),
          ),
        ],
      ),
    );
  }
}

