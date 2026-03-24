import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_service.g.dart';

@Riverpod(keepAlive: true)
LocationService locationService(ref) {
  final socket = ref.watch(socketServiceProvider);
  final service = LocationService(socket);
  ref.onDispose(() => service.stopLocationUpdates());
  return service;
}

class LocationService {
  final SocketService _socketService;
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionSubscription;

  LocationService(this._socketService);

  Future<void> startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return;
    }

    // Initial update
    final position = await Geolocator.getCurrentPosition();
    _socketService.sendLocationUpdate(position.latitude, position.longitude);

    // Periodic update every 5 seconds as per doc
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        );
        _socketService.sendLocationUpdate(pos.latitude, pos.longitude);
        debugPrint('📍 LocationService: Updated ${pos.latitude}, ${pos.longitude}');
      } catch (e) {
        debugPrint('Error getting location: $e');
      }
    });
  }

  void stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
