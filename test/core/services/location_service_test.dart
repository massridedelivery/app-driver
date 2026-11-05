import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:massdrive/core/auth/session_trail.dart';
import 'package:massdrive/core/services/location_service.dart';
import 'package:massdrive/core/services/socket_service.dart';

class _Sock implements SocketService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

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

  test('maskedPath hides ids', () {
    expect(
      maskedPath('/api/driver/jobs/92cc2962-1b2c-4d5e-8f90-123456789abc/toll'),
      '/api/driver/jobs/:id/toll',
    );
    expect(maskedPath('/api/driver/profile'), '/api/driver/profile');
    expect(maskedPath('/api/orders/123?x=1'), '/api/orders/:id');
  });
}
