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
  Timer? _keepAliveTimer;

  Position? _lastPosition;
  DateTime? _lastSentAt;
  Duration _minSendInterval = const Duration(seconds: 8);

  /// Send the last position at least this often even when stationary — the
  /// dispatch pool drops drivers that go silent for ~1 min (driver spec §4).
  static const Duration _keepAlive = Duration(seconds: 20);

  LocationService(this._socketService);

  /// [activeJob] tightens accuracy/cadence while on a trip; idle (online,
  /// waiting) uses a cheaper profile to save battery.
  Future<void> startLocationUpdates({bool activeJob = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (kDebugMode) debugPrint('Location services are disabled.');
      return;
    }

    var permission = await Geolocator.checkPermission();
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

    // Reset any existing session.
    _positionSubscription?.cancel();
    _keepAliveTimer?.cancel();
    _lastSentAt = null;

    final accuracy =
        activeJob ? LocationAccuracy.high : LocationAccuracy.medium;
    final distanceFilter = activeJob ? 10 : 25;
    _minSendInterval = Duration(seconds: activeJob ? 3 : 8);

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (pos) {
        _lastPosition = pos;
        // Throttle rapid emissions (e.g. highway speeds).
        final now = DateTime.now();
        if (_lastSentAt == null ||
            now.difference(_lastSentAt!) >= _minSendInterval) {
          _send(pos);
        }
      },
      onError: (e) {
        if (kDebugMode) debugPrint('LocationService Stream Error: $e');
      },
    );

    // Keep-alive: resend the last fix when the driver is stationary (the stream
    // is silent under distanceFilter) so we stay in the dispatch pool.
    _keepAliveTimer = Timer.periodic(_keepAlive, (_) {
      final pos = _lastPosition;
      if (pos == null) return;
      if (_lastSentAt == null ||
          DateTime.now().difference(_lastSentAt!) >= _keepAlive) {
        _send(pos);
      }
    });
  }

  void _send(Position pos) {
    _lastSentAt = DateTime.now();
    _socketService.sendLocationUpdate(pos.latitude, pos.longitude);
    if (kDebugMode) {
      debugPrint('📍 LocationService: Updated ${pos.latitude}, ${pos.longitude}');
    }
  }

  void stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _lastPosition = null;
    _lastSentAt = null;
  }
}
