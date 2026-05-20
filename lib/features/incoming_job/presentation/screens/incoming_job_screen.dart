import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
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

  @override
  Widget build(BuildContext context) {
    final incomingJobState = ref.watch(incomingJobControllerProvider);
    final job = incomingJobState.currentJob;

    if (job == null) {
      // Safety fallback
      return const Scaffold(
        backgroundColor: AppColors.semanticGrayNeutralFgWhite,
        body: Center(child: CircularProgressIndicator()),
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

    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(job.pickupLat, job.pickupLng),
          LatLng(job.dropoffLat, job.dropoffLng),
        ],
        color: job.isFood
            ? AppColors.foundationOrange600
            : AppColors.semanticPrimaryBgHigh,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
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

