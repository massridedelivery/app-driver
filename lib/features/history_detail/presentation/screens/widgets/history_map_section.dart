import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/core/constants/map_constants.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';

class HistoryMapSection extends StatelessWidget {
  final HistoryDetailEntity data;

  const HistoryMapSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final LatLng? pickup = data.hasRoute
        ? LatLng(data.pickupLat!, data.pickupLng!)
        : null;
    final LatLng? dropoff = data.hasRoute
        ? LatLng(data.dropoffLat!, data.dropoffLng!)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pickup ?? MapDefaults.center,
              zoom: 14,
            ),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            markers: {
              if (pickup != null)
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: pickup,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              if (dropoff != null)
                Marker(
                  markerId: const MarkerId('dropoff'),
                  position: dropoff,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
            },
            polylines: {
              if (pickup != null && dropoff != null)
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: [pickup, dropoff],
                ),
            },
            onMapCreated: (controller) {
              if (pickup == null || dropoff == null) return;
              controller.animateCamera(
                CameraUpdate.newLatLngBounds(_boundsOf(pickup, dropoff), 48),
              );
            },
          ),
        ),
      ),
    );
  }

  LatLngBounds _boundsOf(LatLng a, LatLng b) {
    return LatLngBounds(
      southwest: LatLng(
        math.min(a.latitude, b.latitude),
        math.min(a.longitude, b.longitude),
      ),
      northeast: LatLng(
        math.max(a.latitude, b.latitude),
        math.max(a.longitude, b.longitude),
      ),
    );
  }
}
