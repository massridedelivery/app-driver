import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_service.g.dart';

@Riverpod(keepAlive: true)
LocationService locationService(ref) {
  final socket = ref.watch(socketServiceProvider);
  final service = LocationService(
    socket,
    postLocation: (lat, lng) => ref
        .read(dioProvider)
        .post<dynamic>(
          Endpoints.driverLocation,
          data: {'lat': lat, 'lng': lng},
        ),
  );
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
  DateTime? _lastPostAt;
  bool _posting = false;

  /// Open job screens (ride / food / parcel): any open → the trip profile.
  int _activeJobs = 0;

  /// The profile the running session was started with.
  bool? _runningActiveJob;

  /// A start asked for while the app was in the background, run on resume.
  bool _startOnResume = false;
  AppLifecycleListener? _resumeListener;

  final bool Function() _isForeground;
  final Future<bool> Function() _serviceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Stream<Position> Function(LocationSettings) _positionStream;
  final Future<void> Function(double lat, double lng)? _postLocation;

  /// Every fix produced by the tracking session, unthrottled — the throttle
  /// applies to what we send upstream, not to what the UI may observe.
  /// Only emits while [startLocationUpdates] is running (driver is online).
  Stream<Position> get onPosition => _positionController.stream;

  /// Send the last position at least this often even when stationary — the
  /// dispatch pool drops drivers that go silent for ~1 min (driver spec §4),
  /// and on a job a fix older than 60 s leaves the customer without an ETA.
  static const Duration _idleKeepAlive = Duration(seconds: 20);
  static const Duration _jobKeepAlive = Duration(seconds: 15);
  Duration _keepAlive = _idleKeepAlive;

  /// The HTTP fallback is a request per fix — never closer than this.
  static const Duration _minPostInterval = Duration(seconds: 10);

  LocationService(
    this._socketService, {
    bool Function()? isForeground,
    Future<bool> Function()? serviceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Stream<Position> Function(LocationSettings)? positionStream,
    Future<void> Function(double lat, double lng)? postLocation,
  }) : _postLocation = postLocation,
       _isForeground = isForeground ?? _appInForeground,
       _serviceEnabled = serviceEnabled ?? Geolocator.isLocationServiceEnabled,
       _checkPermission = checkPermission ?? Geolocator.checkPermission,
       _requestPermission = requestPermission ?? Geolocator.requestPermission,
       _positionStream =
           positionStream ??
           ((settings) =>
               Geolocator.getPositionStream(locationSettings: settings));

  /// Android only lets an app start a foreground service while it is visible
  /// (Android 12+); started from the background it throws
  /// `Service.startForeground() not allowed` (a Crashlytics issue) and the
  /// location stream never opens. `inactive` still counts: the permission
  /// dialog and the notification shade leave the activity visible.
  static bool _appInForeground() {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null ||
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
  }

  /// Whether a tracking session is running.
  bool get isTracking => _positionSubscription != null;

  /// Starts tracking — or does nothing when a session with the same profile
  /// is already running. Called on going online and on every socket
  /// (re)connect: restarting a live session there swapped the foreground
  /// service for a new one, which Android refuses in the background, so a
  /// network blip with the app behind the map app ended location for good.
  ///
  /// The profile follows the open job screens ([beginActiveJob]): the trip
  /// one is tighter, idle (online, waiting) is cheaper on battery.
  Future<void> startLocationUpdates() async {
    final activeJob = _activeJobs > 0;
    if (isTracking && _runningActiveJob == activeJob) return;
    if (!_isForeground()) {
      _deferUntilResume();
      return;
    }
    _startOnResume = false;

    if (!await _serviceEnabled()) {
      if (kDebugMode) debugPrint('Location services are disabled.');
      return;
    }

    if (!await _ensurePermission(request: true)) return;

    // Reset any existing session.
    _positionSubscription?.cancel();
    _keepAliveTimer?.cancel();
    _lastSentAt = null;
    _runningActiveJob = activeJob;

    final accuracy = activeJob
        ? LocationAccuracy.high
        : LocationAccuracy.medium;
    final distanceFilter = activeJob ? 10 : 25;
    _minSendInterval = Duration(seconds: activeJob ? 3 : 8);
    _keepAlive = activeJob ? _jobKeepAlive : _idleKeepAlive;

    _positionSubscription =
        _positionStream(_buildSettings(accuracy, distanceFilter)).listen(
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
          // The platform ended the stream: let the next start open a new one.
          onDone: () {
            _positionSubscription = null;
            _runningActiveJob = null;
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

  /// A job screen opened: track on the trip profile until [endActiveJob].
  /// Counted, so one job screen replacing another keeps it.
  void beginActiveJob() {
    _activeJobs++;
    _reprofile();
  }

  /// The job screen closed. Back to the idle profile when none is open.
  void endActiveJob() {
    if (_activeJobs > 0) _activeJobs--;
    _reprofile();
  }

  /// Restarts a running session on the new profile. Never starts one: the
  /// driver may be offline.
  void _reprofile() {
    if (!isTracking || _runningActiveJob == _activeJobs > 0) return;
    unawaited(startLocationUpdates());
  }

  void _deferUntilResume() {
    _startOnResume = true;
    _resumeListener ??= AppLifecycleListener(onResume: _onResume);
  }

  void _onResume() {
    if (!_startOnResume) return;
    _startOnResume = false;
    unawaited(startLocationUpdates());
  }

  /// Platform location settings that keep updates flowing while the app is
  /// backgrounded, so the driver stays in the dispatch pool (SCRUM-122):
  ///  • Android → a foreground service with a persistent notification.
  ///  • iOS → the background-location mode (blue status indicator).
  /// Both work with "while in use" permission because the session starts while
  /// the app is in the foreground (driver taps "online").
  LocationSettings _buildSettings(
    LocationAccuracy accuracy,
    int distanceFilter,
  ) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Mass Drive กำลังออนไลน์',
          notificationText: 'กำลังแชร์ตำแหน่งเพื่อรับงาน',
          enableWakeLock: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter);
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

  /// Whether the device's location service (GPS) is turned on.
  Future<bool> serviceEnabled() => Geolocator.isLocationServiceEnabled();

  /// Current location permission — lets the UI show a Settings prompt when the
  /// driver has permanently denied it (`deniedForever`).
  Future<LocationPermission> permission() => Geolocator.checkPermission();

  /// Resolves true when location permission is usable. [request] prompts the
  /// driver when it has not been asked for yet.
  Future<bool> _ensurePermission({bool request = false}) async {
    var permission = await _checkPermission();

    if (permission == LocationPermission.denied && request) {
      permission = await _requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (kDebugMode) debugPrint('Location permissions are denied');
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      if (kDebugMode)
        debugPrint('Location permissions are permanently denied.');
      return false;
    }
    return true;
  }

  /// Upstream: the socket while the app is in front and the socket is up;
  /// otherwise `POST /api/driver/location` — a backgrounded app's socket may
  /// be suspended or gone, and a `location_update` frame sent to a closed
  /// socket is dropped, which left the customer's ETA blank.
  void _send(Position pos) {
    if (_isForeground() && _socketService.isConnected) {
      _lastSentAt = DateTime.now();
      _socketService.sendLocationUpdate(pos.latitude, pos.longitude);
      if (kDebugMode) {
        debugPrint(
          '📍 LocationService: Updated ${pos.latitude}, ${pos.longitude}',
        );
      }
      return;
    }
    unawaited(_post(pos));
  }

  Future<void> _post(Position pos) async {
    final post = _postLocation;
    if (post == null || _posting) return;
    final now = DateTime.now();
    if (_lastPostAt != null &&
        now.difference(_lastPostAt!) < _minPostInterval) {
      return;
    }
    _posting = true;
    _lastPostAt = now;
    try {
      await post(pos.latitude, pos.longitude);
      _lastSentAt = DateTime.now();
      if (kDebugMode) debugPrint('📍 LocationService: posted over HTTP');
    } catch (e) {
      // The keep-alive tries again; nothing else to do.
      if (kDebugMode) debugPrint('LocationService: HTTP fallback failed: $e');
    } finally {
      _posting = false;
    }
  }

  void stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _lastPosition = null;
    _lastSentAt = null;
    _lastPostAt = null;
    _runningActiveJob = null;
    _startOnResume = false;
  }

  /// Tears the service down for good. [onPosition] is closed here rather than
  /// in [stopLocationUpdates] so listeners survive going offline and online.
  void dispose() {
    stopLocationUpdates();
    _resumeListener?.dispose();
    _resumeListener = null;
    _positionController.close();
  }
}
