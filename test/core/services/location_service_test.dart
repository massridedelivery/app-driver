import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:massdrive/core/auth/session_trail.dart';
import 'package:massdrive/core/services/location_service.dart';
import 'package:massdrive/core/services/socket_service.dart';

class _Sock implements SocketService {
  bool up = true;
  final sent = <(double, double)>[];

  @override
  bool get isConnected => up;

  @override
  void sendLocationUpdate(double lat, double lng) => sent.add((lat, lng));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Position _fix(double lat) => Position(
  latitude: lat,
  longitude: 100.5,
  timestamp: DateTime.now(),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool foreground;
  late List<LocationSettings> opened;
  late List<StreamController<Position>> streams;

  LocationService make() => LocationService(
    _Sock(),
    isForeground: () => foreground,
    serviceEnabled: () async => true,
    checkPermission: () async => LocationPermission.whileInUse,
    requestPermission: () async => LocationPermission.whileInUse,
    positionStream: (settings) {
      opened.add(settings);
      final c = StreamController<Position>();
      streams.add(c);
      return c.stream;
    },
  );

  setUp(() {
    foreground = true;
    opened = [];
    streams = [];
  });

  test('a socket reconnect does not restart a running session', () async {
    final s = make();
    await s.startLocationUpdates();
    await s.startLocationUpdates();
    await s.startLocationUpdates();
    expect(opened, hasLength(1));
    expect(s.isTracking, isTrue);
    s.dispose();
  });

  test('in the background nothing starts; it starts on resume', () async {
    final s = make();
    foreground = false;
    await s.startLocationUpdates();
    expect(opened, isEmpty);

    foreground = true;
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.hidden,
    );
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.inactive,
    );
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await pumpEventQueue();
    expect(opened, hasLength(1));
    s.dispose();
  });

  test('going offline drops a start waiting for resume', () async {
    final s = make();
    foreground = false;
    await s.startLocationUpdates();
    s.stopLocationUpdates();
    foreground = true;
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.inactive,
    );
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await pumpEventQueue();
    expect(opened, isEmpty);
    s.dispose();
  });

  test('a job screen switches a running session to the trip profile', () async {
    final s = make();
    await s.startLocationUpdates();
    expect((opened.last as dynamic).accuracy, isNot(LocationAccuracy.high));

    s.beginActiveJob();
    await pumpEventQueue();
    expect(opened, hasLength(2));
    expect(opened.last.accuracy, LocationAccuracy.high);
    expect(opened.last.distanceFilter, 10);

    // One job screen replacing another keeps the trip profile.
    s.beginActiveJob();
    s.endActiveJob();
    await pumpEventQueue();
    expect(opened, hasLength(2));

    s.endActiveJob();
    await pumpEventQueue();
    expect(opened, hasLength(3));
    expect(opened.last.accuracy, LocationAccuracy.medium);
    s.dispose();
  });

  test('a job screen never starts tracking for an offline driver', () async {
    final s = make();
    s.beginActiveJob();
    await pumpEventQueue();
    expect(opened, isEmpty);
    // Going online during the job starts straight on the trip profile.
    await s.startLocationUpdates();
    expect(opened.single.accuracy, LocationAccuracy.high);
    s.dispose();
  });

  test('a stream the platform ended is reopened on the next start', () async {
    final s = make();
    await s.startLocationUpdates();
    await streams.single.close();
    await pumpEventQueue();
    expect(s.isTracking, isFalse);
    await s.startLocationUpdates();
    expect(opened, hasLength(2));
    s.dispose();
  });

  test('going to the background during the checks defers the start', () async {
    final s = LocationService(
      _Sock(),
      isForeground: () => foreground,
      serviceEnabled: () async {
        foreground = false; // the driver switched apps meanwhile
        return true;
      },
      checkPermission: () async => LocationPermission.whileInUse,
      requestPermission: () async => LocationPermission.whileInUse,
      positionStream: (settings) {
        opened.add(settings);
        return const Stream.empty();
      },
    );
    await s.startLocationUpdates();
    expect(opened, isEmpty);
    expect(s.isTracking, isFalse);
    s.dispose();
  });

  group('Android refuses the location foreground service', () {
    FlutterErrorDetails refused({
      String channel = 'geolocator_updates_android',
    }) => FlutterErrorDetails(
      exception: PlatformException(
        code: 'error',
        message:
            'Service.startForeground() not allowed due to mAllowStartForeground false',
      ),
      context: ErrorDescription(
        'while activating platform stream on channel flutter.baseflow.com/$channel',
      ),
    );

    test('is recognised only for the geolocator stream', () {
      expect(LocationService.isRefusedForegroundStart(refused()), isTrue);
      expect(
        LocationService.isRefusedForegroundStart(refused(channel: 'other')),
        isFalse,
      );
      expect(
        LocationService.isRefusedForegroundStart(
          FlutterErrorDetails(exception: StateError('x')),
        ),
        isFalse,
      );
    });

    test('drops the silent session and starts again on resume', () async {
      final s = make();
      await s.startLocationUpdates();
      expect(s.isTracking, isTrue);

      foreground = false;
      expect(LocationService.onFlutterError(refused()), isTrue);
      expect(s.isTracking, isFalse);

      foreground = true;
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        WidgetsBinding.instance.handleAppLifecycleStateChanged(state);
      }
      await pumpEventQueue();
      expect(opened, hasLength(2));
      expect(s.isTracking, isTrue);
      s.dispose();
    });
  });

  test('maskedPath hides ids', () {
    expect(
      maskedPath('/api/driver/jobs/92cc2962-1b2c-4d5e-8f90-123456789abc/toll'),
      '/api/driver/jobs/:id/toll',
    );
    expect(maskedPath('/api/driver/profile'), '/api/driver/profile');
    expect(maskedPath('/api/orders/123?x=1'), '/api/orders/:id');
  });

  group('upstream', () {
    late _Sock sock;
    late List<(double, double)> posted;

    LocationService makeWith() => LocationService(
      sock,
      isForeground: () => foreground,
      serviceEnabled: () async => true,
      checkPermission: () async => LocationPermission.whileInUse,
      requestPermission: () async => LocationPermission.whileInUse,
      positionStream: (settings) {
        final c = StreamController<Position>();
        streams.add(c);
        return c.stream;
      },
      postLocation: (lat, lng) async => posted.add((lat, lng)),
    );

    setUp(() {
      sock = _Sock();
      posted = [];
    });

    test('in front with the socket up: a location_update frame', () async {
      final s = makeWith();
      await s.startLocationUpdates();
      streams.single.add(_fix(13.7));
      await pumpEventQueue();
      expect(sock.sent, [(13.7, 100.5)]);
      expect(posted, isEmpty);
      s.dispose();
    });

    test('socket down: POST /api/driver/location instead', () async {
      final s = makeWith();
      await s.startLocationUpdates();
      sock.up = false;
      streams.single.add(_fix(13.7));
      await pumpEventQueue();
      expect(sock.sent, isEmpty);
      expect(posted, [(13.7, 100.5)]);
      s.dispose();
    });

    test('backgrounded: over HTTP, at most one per 10 s', () async {
      final s = makeWith();
      await s.startLocationUpdates();
      foreground = false;
      streams.single.add(_fix(13.7));
      await pumpEventQueue();
      streams.single.add(_fix(13.8));
      await pumpEventQueue();
      expect(sock.sent, isEmpty);
      expect(posted, [(13.7, 100.5)]);
      s.dispose();
    });
  });
}
