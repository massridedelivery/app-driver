import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/core/utils/map_marker_utils.dart';

/// Rasterizing a pin is a little work, and the bitmaps never change, so cache
/// them once per app session. Screens read `.value` and fall back to a hue
/// marker while the async build is still resolving.
final pickupMarkerProvider = FutureProvider<BitmapDescriptor>(
  (ref) => MapMarkerUtils.createPickupMarker(),
);

final dropoffMarkerProvider = FutureProvider<BitmapDescriptor>(
  (ref) => MapMarkerUtils.createDropoffMarker(),
);

final restaurantMarkerProvider = FutureProvider<BitmapDescriptor>(
  (ref) => MapMarkerUtils.createRestaurantMarker(),
);
