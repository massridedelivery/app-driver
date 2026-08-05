import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Map defaults used when the driver's real position or a job's coordinates
/// are not available yet (emulator testing, no active job, missing data).
///
/// Only a camera fallback — nothing here is ever sent to the backend.
class MapDefaults {
  const MapDefaults._();

  /// Bangkok city center.
  static const double latitude = 13.7563;
  static const double longitude = 100.5018;

  static const LatLng center = LatLng(latitude, longitude);
}
