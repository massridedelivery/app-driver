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
  StreamSubscription<Position>? _positionSubscription;

  LocationService(this._socketService);

  Future<void> startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (kDebugMode) debugPrint('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (kDebugMode) debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (kDebugMode) debugPrint('Location permissions are permanently denied.');
      return;
    }

    // Cancel any existing subscription before starting a new one
    _positionSubscription?.cancel();

    // Use getPositionStream: emits when moved >10m or at most every 5s
    // Much cheaper than polling getCurrentPosition every 5s
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // only emit when moved > 10 metres
      ),
    ).listen(
      (pos) {
        _socketService.sendLocationUpdate(pos.latitude, pos.longitude);
        if (kDebugMode) {
          debugPrint('📍 LocationService: Updated ${pos.latitude}, ${pos.longitude}');
        }
      },
      onError: (e) {
        if (kDebugMode) debugPrint('LocationService Stream Error: $e');
      },
    );
  }

  void stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
