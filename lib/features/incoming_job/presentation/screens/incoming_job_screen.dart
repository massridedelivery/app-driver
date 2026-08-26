import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/services/directions_service.dart';
import 'package:massdrive/features/incoming_job/domain/services/offer_recovery.dart';
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

  /// True while pulling the offer a notification tap only pointed at.
  bool _recovering = false;

  /// Set once recovery has run and come back empty — the offer is gone.
  bool _noOffer = false;

  @override
  void initState() {
    super.initState();
    // Arriving from a notification tap means empty controller state: the push
    // carries no job data and the offer socket isn't connected in the
    // background. Fetch the offer instead of bouncing the driver to Home.
    if (ref.read(incomingJobControllerProvider).currentJob == null) {
      _recoverOffer();
    } else {
      _loadRoute();
    }
  }

  Future<void> _recoverOffer() async {
    setState(() => _recovering = true);
    String? route;
    try {
      route = await recoverPendingOffer(ref);
    } catch (e) {
      if (kDebugMode) debugPrint('IncomingJob: offer recovery failed: $e');
    }
    if (!mounted) return;

    // Messenger offers live on their own screen.
    if (route != null && route != AppRoutes.incomingJobNamedPage) {
      context.go(route);
      return;
    }

    setState(() {
      _recovering = false;
      _noOffer = ref.read(incomingJobControllerProvider).currentJob == null;
    });
    if (!_noOffer) _loadRoute();
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
      // Still fetching the offer a notification tap pointed at — hold the
      // screen rather than bouncing away before the answer arrives.
      if (_recovering) {
        return const Scaffold(
          backgroundColor: AppColors.semanticGrayNeutralFgWhite,
          body: Center(child: MassLoadingM(size: 72)),
        );
      }

      // Recovery came back empty (offer expired or taken) or the screen was
      // route-restored after a kill. Nothing to accept — send the driver home.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(incomingJobControllerProvider).currentJob != null) return;
        if (_noOffer) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('งานนี้ถูกรับไปแล้วหรือหมดเวลาแล้ว')),
          );
        }
        context.go(AppRoutes.homeNamedPage);
      });
      return const Scaffold(
        backgroundColor: AppColors.semanticGrayNeutralFgWhite,
        body: Center(child: MassLoadingM(size: 72)),
      );
    }

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(job.pickupLat, job.pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          job.isFood ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen,
        ),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(job.dropoffLat, job.dropoffLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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

