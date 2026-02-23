import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';

class HistoryMapSection extends StatelessWidget {
  final HistoryDetailEntity data;

  const HistoryMapSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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
            initialCameraPosition: const CameraPosition(
              target: LatLng(13.7563, 100.5018),
              zoom: 14,
            ),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: const [
                  LatLng(13.7563, 100.5018),
                  LatLng(13.7463, 100.4918),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}
