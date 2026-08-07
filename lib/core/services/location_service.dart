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
  ref.onDispose(service.dispose);
  return service;
}

class LocationService {
  final SocketService _socketService;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _keepAliveTimer;

  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  Position? _lastPosition;
  DateTime? _lastSentAt;
  Duration _minSendInterval = const Duration(seconds: 8);

  /// Every fix produced by the tracking session, unthrottled — the throttle
  /// applies to what we send upstream, not to what the UI may observe.
  /// Only emits while [startLocationUpdates] is running (driver is online).
  Stream<Position> get onPosition => _positionController.stream;

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

    if (!await _ensurePermission(request: true)) return;

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
        if (!_positionController.isClosed) _positionController.add(pos);
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

  /// A single fix for one-off needs (map camera, active-job probe). Works
  /// whether or not a tracking session is running. Returns null when no fix is
  /// available — callers keep whatever fallback they already show.
  ///
  /// Never prompts for permission: the prompt belongs to going online, so a
  /// driver who has not granted it yet simply gets null here.
  Future<Position?> currentPosition({
    Duration timeLimit = const Duration(seconds: 5),
  }) async {
    // While a session is running the last fix is live — reuse it. Outside a
    // session it would be stale, so always look it up again.
    if (_positionSubscription != null && _lastPosition != null) {
      return _lastPosition;
    }

    try {
      if (!await _ensurePermission()) return null;

      // Last known is instant; only pay for a fresh fix when there is none.
      return await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: timeLimit,
            ),
          );
    } catch (e) {
      if (kDebugMode) debugPrint('LocationService.currentPosition: $e');
      return null;
    }
  }

  /// Resolves true when location permission is usable. [request] prompts the
  /// driver when it has not been asked for yet.
  Future<bool> _ensurePermission({bool request = false}) async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (kDebugMode) debugPrint('Location permissions are denied');
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      if (kDebugMode) debugPrint('Location permissions are permanently denied.');
      return false;
    }
    return true;
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

  /// Tears the service down for good. [onPosition] is closed here rather than
  /// in [stopLocationUpdates] so listeners survive going offline and online.
  void dispose() {
    stopLocationUpdates();
    _positionController.close();
  }
}
